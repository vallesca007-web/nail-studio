const path = require('node:path');
const { loadEnvironment } = require('./config/env');

loadEnvironment();

if (!process.env.JWT_SECRET) {
  console.warn('Falta JWT_SECRET en el .env: el inicio de sesion fallara.');
}

const express = require('express');
const cookieParser = require('cookie-parser');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { createPool } = require('mysql2/promise');

const {
  dateInTimeZone,
  formatLocalDateTime,
  localDateTimeToDate,
  localDayRange,
  parseDate,
  weekday,
} = require('./services/dateTime');
const googleCalendar = require('./services/googleCalendar');

const port = Number(process.env.PORT || 3000);
const timeZone = process.env.TIMEZONE || 'America/Mexico_City';
const pool = createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'AnneNail',
  connectionLimit: 10,
  timezone: 'Z',
  multipleStatements: true,
});

class ApiError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

const asyncHandler = (handler) => (request, response, next) =>
  Promise.resolve(handler(request, response, next)).catch(next);

function getBusinessDays() {
  const value = process.env.BUSINESS_DAYS || '1,2,3,4,5,6';
  const days = value.split(',').map((item) => Number(item.trim()));
  if (days.some((day) => !Number.isInteger(day) || day < 1 || day > 7)) {
    throw new ApiError(500, 'BUSINESS_DAYS debe usar números del 1 al 7.');
  }
  return new Set(days);
}

function getBusinessHours() {
  const opening = Number(process.env.BUSINESS_OPEN_HOUR || 10);
  const closing = Number(process.env.BUSINESS_CLOSE_HOUR || 19);
  const closingMinute = Number(process.env.BUSINESS_CLOSE_MINUTE || 30);
  const interval = Number(process.env.SLOT_INTERVAL_MINUTES || 30);
  if (
    !Number.isInteger(opening) ||
    !Number.isInteger(closing) ||
    !Number.isInteger(closingMinute) ||
    !Number.isInteger(interval) ||
    opening < 0 ||
    closing > 23 ||
    closingMinute < 0 ||
    closingMinute > 59 ||
    closing * 60 + closingMinute <= opening * 60 ||
    interval <= 0 ||
    interval > 240
  ) {
    throw new ApiError(500, 'La configuración del horario no es válida.');
  }
  return { opening, closingMinute: closing * 60 + closingMinute, interval };
}

function validatePhone(value) {
  if (value === undefined || value === null || value === '') return null;
  if (typeof value !== 'string') throw new ApiError(400, 'El teléfono no es válido.');
  const phone = value.trim();
  if (phone.length > 32) throw new ApiError(400, 'El teléfono no puede superar 32 caracteres.');
  if (!/^[+\d][\d\s().-]*$/.test(phone)) throw new ApiError(400, 'El teléfono no es válido.');
  return phone;
}

function buildSlots(date, duration, busyRanges) {
  const businessDays = getBusinessDays();
  const dayOfWeek = weekday(date);
  if (!dayOfWeek || dayOfWeek === 7 || !businessDays.has(dayOfWeek)) return [];
  const { opening, closingMinute, interval } = getBusinessHours();
  const isToday = dateInTimeZone(new Date(), timeZone) === date;
  const now = Date.now();
  const slots = [];
  for (let minute = opening * 60; minute < closingMinute; minute += interval) {
    const time = `${String(Math.floor(minute / 60)).padStart(2, '0')}:${String(minute % 60).padStart(2, '0')}`;
    const start = localDateTimeToDate(date, time, timeZone);
    if (!start || (isToday && start.getTime() <= now)) continue;
    const end = new Date(start.getTime() + duration * 60_000);
    const localEnd = formatLocalDateTime(end, timeZone);
    const endMinute = Number(localEnd.slice(11, 13)) * 60 + Number(localEnd.slice(14, 16));
    if (localEnd.slice(0, 10) !== date || endMinute > closingMinute) continue;
    if (busyRanges.some((busy) => start < busy.end && end > busy.start)) continue;
    slots.push(time);
  }
  return slots;
}

async function getService(serviceId) {
  const [rows] = await pool.execute(
    'SELECT id, nombre, costo, duracion_min FROM servicios WHERE id = ? AND activo = TRUE',
    [serviceId],
  );
  if (!rows.length) throw new ApiError(404, 'El servicio no existe.');
  return rows[0];
}

async function getAvailableSlots(date, service) {
  const range = localDayRange(date, timeZone);
  if (!range) throw new ApiError(400, 'La fecha no es válida.');
  let busyRanges;
  try {
    busyRanges = await googleCalendar.getBusyRanges(date);
  } catch (error) {
    console.error('No se pudo consultar Google Calendar:', error);
    throw new ApiError(502, 'No pudimos consultar la agenda.');
  }
  const [rows] = await pool.execute(
    `SELECT hora, hora_fin
     FROM citas
     WHERE fecha = ? AND estado <> 'cancelada'`,
    [date],
  );
  const databaseBusy = rows.map((row) => ({
    start: localDateTimeToDate(date, String(row.hora).slice(0, 5), timeZone),
    end: localDateTimeToDate(date, String(row.hora_fin).slice(0, 5), timeZone),
  })).filter((row) => row.start && row.end);
  const busy = [
    ...busyRanges.map((item) => ({ start: new Date(item.start), end: new Date(item.end) })),
    ...databaseBusy,
  ];
  return buildSlots(date, service.duracion_min, busy);
}

function requireUser(request, response, next) {
  const token = /^Bearer\s+(.+)$/i.exec(request.headers.authorization || '')?.[1];
  if (!token) return response.status(401).json({ error: 'Inicia sesión para continuar.' });
  try {
    request.user = jwt.verify(token, process.env.JWT_SECRET);
    return next();
  } catch {
    return response.status(401).json({ error: 'Tu sesión venció.' });
  }
}

const app = express();
app.disable('x-powered-by');
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", 'https://fonts.googleapis.com'],
      fontSrc: ["'self'", 'https://fonts.gstatic.com'],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", 'data:', 'https:'],
    },
  },
}));
// La app Flutter Web corre en otro puerto local; sin esto el navegador bloquea
// las peticiones y la app muestra "No pudimos conectar con el servidor".
const localOrigin = /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/;
app.use((request, response, next) => {
  const origin = request.headers.origin;
  if (origin && localOrigin.test(origin)) {
    response.setHeader('Access-Control-Allow-Origin', origin);
    response.setHeader('Vary', 'Origin');
    response.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type');
    response.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    response.setHeader('Access-Control-Max-Age', '600');
  }
  if (request.method === 'OPTIONS') return response.sendStatus(204);
  return next();
});
app.use(express.json({ limit: '16kb' }));
app.use(cookieParser());

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { error: 'Demasiados intentos. Espera antes de volver a iniciar sesión.' },
});

app.get('/api/health', asyncHandler(async (request, response) => {
  try {
    await pool.query('SELECT 1 FROM citas LIMIT 0');
    response.json({ status: 'ok', database: 'connected' });
  } catch (error) {
    // El codigo de MySQL distingue credenciales, base inexistente o servidor apagado.
    console.error('La base de datos no responde:', error.code || error.message);
    response.status(503).json({
      status: 'error',
      database: 'unavailable',
      code: error.code || null,
    });
  }
}));

app.post('/api/auth/register', asyncHandler(async (request, response) => {
  const correo = typeof request.body?.correo === 'string' ? request.body.correo.trim().toLowerCase() : '';
  const contrasena = typeof request.body?.contrasena === 'string' ? request.body.contrasena : '';
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correo)) throw new ApiError(400, 'El correo no es válido.');
  if (contrasena.length < 8) throw new ApiError(400, 'La contraseña debe tener al menos 8 caracteres.');
  const [existing] = await pool.execute('SELECT id FROM usuarios WHERE correo = ?', [correo]);
  if (existing.length) throw new ApiError(409, 'El correo ya está registrado.');
  const hash = await bcrypt.hash(contrasena, 12);
  const [result] = await pool.execute(
    'INSERT INTO usuarios (correo, contrasena_hash) VALUES (?, ?)',
    [correo, hash],
  );
  response.status(201).json({ id: result.insertId, correo });
}));

app.post('/api/auth/login', loginLimiter, asyncHandler(async (request, response) => {
  const correo = typeof request.body?.correo === 'string' ? request.body.correo.trim().toLowerCase() : '';
  const contrasena = typeof request.body?.contrasena === 'string' ? request.body.contrasena : '';
  if (!correo || !contrasena) throw new ApiError(400, 'Indica correo y contraseña.');
  const [rows] = await pool.execute('SELECT id, correo, contrasena_hash FROM usuarios WHERE correo = ?', [correo]);
  if (!rows.length || !(await bcrypt.compare(contrasena, rows[0].contrasena_hash))) {
    throw new ApiError(401, 'Credenciales incorrectas.');
  }
  const token = jwt.sign({ userId: rows[0].id, correo: rows[0].correo }, process.env.JWT_SECRET, { expiresIn: '8h' });
  response.json({ token, correo: rows[0].correo, id: rows[0].id });
}));

app.get('/api/availability', asyncHandler(async (request, response) => {
  const date = request.query.date;
  const serviceId = Number(request.query.serviceId);
  if (!parseDate(date)) throw new ApiError(400, 'Indica una fecha válida.');
  if (!Number.isInteger(serviceId) || serviceId <= 0) throw new ApiError(400, 'Indica el servicio.');
  if (date < dateInTimeZone(new Date(), timeZone)) throw new ApiError(400, 'No puedes consultar fechas pasadas.');
  const service = await getService(serviceId);
  const slots = await getAvailableSlots(date, service);
  response.json({
    date,
    serviceId: service.id,
    costo: Number(service.costo),
    duracion_min: service.duracion_min,
    morning: slots.filter((time) => Number(time.slice(0, 2)) < 12),
    afternoon: slots.filter((time) => Number(time.slice(0, 2)) >= 12),
  });
}));

app.post('/api/appointments', requireUser, asyncHandler(async (request, response) => {
  const serviceId = Number(request.body?.servicio_id);
  const date = request.body?.fecha;
  const time = request.body?.hora;
  const phone = validatePhone(request.body?.telefono);
  if (!Number.isInteger(serviceId) || serviceId <= 0) throw new ApiError(400, 'Indica el servicio.');
  if (!parseDate(date)) throw new ApiError(400, 'Indica una fecha válida.');
  if (typeof time !== 'string' || !/^([01]\d|2[0-3]):[0-5]\d$/.test(time)) {
    throw new ApiError(400, 'Indica una hora válida.');
  }
  if (date < dateInTimeZone(new Date(), timeZone)) throw new ApiError(400, 'No puedes reservar fechas pasadas.');
  const service = await getService(serviceId);
  const start = localDateTimeToDate(date, time, timeZone);
  if (!start) throw new ApiError(400, 'La hora no existe en la zona horaria.');
  const end = new Date(start.getTime() + service.duracion_min * 60_000);

  const connection = await pool.getConnection();
  let hasLock = false;
  let inTransaction = false;
  let eventId;
  try {
    const [lock] = await connection.execute('SELECT GET_LOCK(?,10) AS acquired', [`anne-booking-${date}`]);
    if (lock[0]?.acquired !== 1) throw new ApiError(503, 'No pudimos reservar ahora.');
    hasLock = true;
    await connection.beginTransaction();
    inTransaction = true;

    const [rows] = await connection.execute(
      `SELECT hora, hora_fin FROM citas
       WHERE fecha = ? AND estado <> 'cancelada'
       AND hora < ? AND hora_fin > ?
       FOR UPDATE`,
      [date, formatLocalDateTime(end, timeZone).slice(11, 16), time],
    );
    const googleBusy = await googleCalendar.getBusyRanges(date);
    if (rows.length || googleBusy.some((busy) => start < new Date(busy.end) && end > new Date(busy.start))) {
      throw new ApiError(409, 'Ese horario acaba de ocuparse.');
    }

    const [manicuristas] = await connection.execute(
      'SELECT id FROM manicuristas WHERE activo = TRUE ORDER BY id LIMIT 1',
    );
    const event = await googleCalendar.createEvent({
      serviceName: service.nombre,
      customerName: request.user.correo,
      customerEmail: request.user.correo,
      customerPhone: phone,
      start,
      end,
    });
    eventId = event.eventId;
    const [result] = await connection.execute(
      `INSERT INTO citas
       (servicio_id, usuario_id, manicurista_id, fecha, hora, hora_fin, precio, telefono, estado, google_event_id)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pendiente', ?)`,
      [
        service.id,
        request.user.userId,
        manicuristas[0]?.id || null,
        date,
        time,
        formatLocalDateTime(end, timeZone).slice(11, 16),
        service.costo,
        phone,
        eventId,
      ],
    );
    await connection.commit();
    inTransaction = false;
    response.status(201).json({
      id: result.insertId,
      servicio_id: service.id,
      servicio: service.nombre,
      fecha: date,
      hora: time,
      estado: 'pendiente',
      eventUrl: event.eventUrl,
    });
  } catch (error) {
    if (inTransaction) await connection.rollback().catch(() => {});
    if (eventId) await googleCalendar.deleteEvent(eventId).catch(() => {});
    throw error;
  } finally {
    if (hasLock) await connection.execute('SELECT RELEASE_LOCK(?)', [`anne-booking-${date}`]).catch(() => {});
    connection.release();
  }
}));

app.get('/api/appointments/mine', requireUser, asyncHandler(async (request, response) => {
  const [rows] = await pool.execute(
    `SELECT c.id, s.nombre AS servicio, c.fecha, c.hora, c.estado
     FROM citas c JOIN servicios s ON s.id = c.servicio_id
     WHERE c.usuario_id = ? ORDER BY c.fecha, c.hora`,
    [request.user.userId],
  );
  response.json(rows);
}));

app.use('/api/admin', require('./admin/routes')(pool));
app.use('/admin', express.static(path.join(__dirname, 'public')));
app.get('/admin', (request, response) => response.sendFile(path.join(__dirname, 'public/index.html')));

app.use((error, request, response, next) => {
  if (error instanceof ApiError) return response.status(error.status).json({ error: error.message });
  console.error(error);
  response.status(500).json({ error: 'Error interno del servidor.' });
});

let server;
if (require.main === module) {
  server = app.listen(port, '0.0.0.0', async () => {
    console.log(`Anne Nail Studio API escuchando en el puerto ${port}`);
    try {
      await pool.query('SELECT 1');
      console.log('MySQL conectado.');
    } catch (error) {
      console.error(`MySQL no responde: ${error.code || error.message}`);
    }
  });
}

async function shutdown() {
  if (server) await new Promise((resolve) => server.close(resolve));
  await pool.end();
}
process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

module.exports = { app, pool, shutdown };
