require('dotenv').config();

const crypto = require('node:crypto');
const path = require('node:path');

const express = require('express');
const cookieParser = require('cookie-parser');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { google } = require('googleapis');
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
const createAdminRoutes = require('./admin/routes');

const port = Number(process.env.PORT || 3000);
const timeZone = process.env.TIMEZONE || 'America/Mexico_City';
const pool = createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'anne_nail_studio',
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
    throw new ApiError(500, 'La configuración del horario del estudio no es válida.');
  }
  return { opening, closingMinute: closing * 60 + closingMinute, interval };
}

async function getService(serviceId) {
  if (typeof serviceId !== 'string' || !serviceId.trim()) {
    throw new ApiError(400, 'Selecciona un servicio válido.');
  }
  const [rows] = await pool.execute(
    `SELECT service_id, name, description, duration_minutes, price
     FROM services
     WHERE service_id = ? AND active = TRUE`,
    [serviceId.trim()],
  );
  if (rows.length === 0) throw new ApiError(404, 'El servicio no está disponible.');
  return rows[0];
}

function buildSlots(date, duration, busyRanges) {
  const businessDays = getBusinessDays();
  const dayOfWeek = weekday(date);
  if (!dayOfWeek || dayOfWeek === 7 || !businessDays.has(dayOfWeek)) return [];

  const { opening, closingMinute, interval } = getBusinessHours();
  const range = localDayRange(date, timeZone);
  if (!range) throw new ApiError(400, 'La fecha o la zona horaria no son válidas.');

  const appointments = busyRanges.map((busy) => ({
    start: new Date(busy.start),
    end: new Date(busy.end),
  }));
  const isToday = dateInTimeZone(new Date(), timeZone) === date;
  const now = Date.now();
  const slots = [];

  for (let minute = opening * 60; minute < closingMinute; minute += interval) {
    const time = `${String(Math.floor(minute / 60)).padStart(2, '0')}:${String(
      minute % 60,
    ).padStart(2, '0')}`;
    const start = localDateTimeToDate(date, time, timeZone);
    if (!start || (isToday && start.getTime() <= now)) continue;
    const end = new Date(start.getTime() + duration * 60_000);
    const localEnd = formatLocalDateTime(end, timeZone);
    const endMinute =
      Number(localEnd.slice(11, 13)) * 60 +
      Number(localEnd.slice(14, 16));
    if (localEnd.slice(0, 10) !== date || endMinute > closingMinute) continue;
    if (appointments.some((busy) => start < busy.end && end > busy.start)) continue;
    slots.push(time);
  }
  return slots;
}

async function getAvailableSlots(date, service) {
  const range = localDayRange(date, timeZone);
  if (!range) throw new ApiError(400, 'La fecha o la zona horaria no son válidas.');
  let busyRanges;
  let rows;
  try {
    [busyRanges, rows] = await Promise.all([
      googleCalendar.getBusyRanges(date),
      pool.execute(
        `SELECT start_at, end_at
         FROM appointments
         WHERE start_at < ? AND end_at > ?`,
        [range.end, range.start],
      ),
    ]);
  } catch (error) {
    console.error('No se pudo consultar la disponibilidad:', error);
    throw new ApiError(502, 'No pudimos consultar la agenda. Inténtalo nuevamente.');
  }
  const [appointments] = rows;
  const databaseBusy = appointments.map((appointment) => ({
    start: new Date(appointment.start_at).toISOString(),
    end: new Date(appointment.end_at).toISOString(),
  }));
  return buildSlots(date, service.duration_minutes, [...busyRanges, ...databaseBusy]);
}

function validateDateAndTime(date, time) {
  if (!parseDate(date)) throw new ApiError(400, 'Usa una fecha válida con formato AAAA-MM-DD.');
  if (date < dateInTimeZone(new Date(), timeZone)) {
    throw new ApiError(400, 'No puedes reservar una fecha pasada.');
  }
  if (typeof time !== 'string' || !/^([01]\d|2[0-3]):[0-5]\d$/.test(time)) {
    throw new ApiError(400, 'Usa una hora válida con formato HH:mm.');
  }
}

async function verifyCustomer(request) {
  const audience = (process.env.GOOGLE_OAUTH_CLIENT_ID || '')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
  if (audience.length === 0) {
    throw new ApiError(503, 'El inicio de sesión no está configurado en el servidor.');
  }
  const token = /^Bearer\s+(.+)$/i.exec(request.headers.authorization || '')?.[1];
  if (!token) throw new ApiError(401, 'Inicia sesión con Google para reservar una cita.');
  try {
    const ticket = await new google.auth.OAuth2().verifyIdToken({
      idToken: token,
      audience,
    });
    const payload = ticket.getPayload();
    if (!payload?.email || payload.email_verified !== true) {
      throw new Error('El correo de Google no está verificado.');
    }
    return payload;
  } catch {
    throw new ApiError(401, 'Tu sesión de Google venció. Inicia sesión nuevamente.');
  }
}

function validatePhone(value) {
  if (value === undefined || value === null || value === '') return null;
  if (typeof value !== 'string') throw new ApiError(400, 'El teléfono no es válido.');
  const phone = value.trim();
  if (phone.length > 32) throw new ApiError(400, 'El teléfono no puede superar 32 caracteres.');
  if (!/^[+\d][\d\s().-]*$/.test(phone)) {
    throw new ApiError(400, 'El teléfono no es válido.');
  }
  return phone;
}

async function createAppointment(request, body) {
  const { serviceId, date, time } = body;
  validateDateAndTime(date, time);
  const service = await getService(serviceId);
  const customer = await verifyCustomer(request);
  const customerName =
    typeof body.customerName === 'string' && body.customerName.trim()
      ? body.customerName.trim()
      : typeof customer.name === 'string'
      ? customer.name.trim()
      : '';
  if (!customerName || customerName.length > 160) {
    throw new ApiError(400, 'No pudimos obtener el nombre de tu cuenta de Google.');
  }
  const customerPhone = validatePhone(body.customerPhone);

  const start = localDateTimeToDate(date, time, timeZone);
  if (!start) throw new ApiError(400, 'La hora elegida no existe en la zona horaria del estudio.');
  const end = new Date(start.getTime() + service.duration_minutes * 60_000);
  const allowedSlots = buildSlots(date, service.duration_minutes, []);
  if (!allowedSlots.includes(time)) {
    throw new ApiError(400, 'Ese horario no está dentro del horario de atención.');
  }

  const connection = await pool.getConnection();
  const lockName = `anne-booking-${date}`;
  let hasLock = false;
  let inTransaction = false;
  let eventId;
  let eventUrl;

  try {
    const [lockRows] = await connection.execute(
      'SELECT GET_LOCK(?, 10) AS acquired',
      [lockName],
    );
    if (lockRows[0]?.acquired !== 1) {
      throw new ApiError(503, 'No pudimos reservar el horario ahora. Inténtalo de nuevo.');
    }
    hasLock = true;
    await connection.beginTransaction();
    inTransaction = true;

    const [appointments] = await connection.execute(
      `SELECT start_at, end_at
       FROM appointments
       WHERE start_at < ? AND end_at > ?
       FOR UPDATE`,
      [end, start],
    );
    let busyRanges;
    try {
      busyRanges = await googleCalendar.getBusyRanges(date);
    } catch (error) {
      console.error('No se pudo revalidar la agenda antes de reservar:', error);
      throw new ApiError(502, 'No pudimos confirmar la disponibilidad. Inténtalo nuevamente.');
    }
    const databaseBusy = appointments.map((appointment) => ({
      start: new Date(appointment.start_at).toISOString(),
      end: new Date(appointment.end_at).toISOString(),
    }));
    if (buildSlots(date, service.duration_minutes, [...busyRanges, ...databaseBusy]).indexOf(time) < 0) {
      throw new ApiError(409, 'Ese horario acaba de ocuparse. Elige otro disponible.');
    }

    let event;
    try {
      event = await googleCalendar.createEvent({
        serviceName: service.name,
        customerName,
        customerEmail: customer.email,
        customerPhone,
        start,
        end,
      });
    } catch (error) {
      console.error('Google Calendar no pudo crear la cita:', error);
      throw new ApiError(502, 'No pudimos crear la cita en el calendario.');
    }
    eventId = event.eventId;
    eventUrl = event.eventUrl;

    const [specialists] = await connection.execute(
      'SELECT specialist_id FROM specialists WHERE active = TRUE ORDER BY created_at, name LIMIT 1',
    );
    const specialistId = specialists[0]?.specialist_id || null;
    const reservationCode = crypto.randomBytes(4).toString('hex').toUpperCase();
    await connection.execute(
      `INSERT INTO appointments
        (event_id, service_id, specialist_id, reservation_code, service_name, start_at, end_at,
         customer_name, customer_email, customer_phone, price, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pendiente')`,
      [
        eventId,
        service.service_id,
        specialistId,
        reservationCode,
        service.name,
        start,
        end,
        customerName,
        customer.email,
        customerPhone,
        service.price,
      ],
    );
    await connection.commit();
    inTransaction = false;

    return {
      eventId,
      eventUrl,
      reservationCode,
      serviceId: service.service_id,
      serviceName: service.name,
      start: formatLocalDateTime(start, timeZone),
      end: formatLocalDateTime(end, timeZone),
      customerName,
      customerEmail: customer.email,
      status: 'pendiente',
    };
  } catch (error) {
    if (inTransaction) {
      try {
        await connection.rollback();
      } catch (rollbackError) {
        console.error('Falló la reversión de la transacción MySQL:', rollbackError);
      }
    }
    if (eventId) {
      try {
        await googleCalendar.deleteEvent(eventId);
      } catch (rollbackError) {
        console.error(`No se pudo eliminar el evento huérfano ${eventId}:`, rollbackError);
        throw new ApiError(502, 'No se pudo guardar la cita y requiere revisión del estudio.');
      }
    }
    throw error;
  } finally {
    if (hasLock) {
      try {
        await connection.execute('SELECT RELEASE_LOCK(?)', [lockName]);
      } catch (error) {
        console.error('No se pudo liberar el bloqueo de reserva:', error);
      }
    }
    connection.release();
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
app.use(express.json({ limit: '16kb' }));
app.use(cookieParser());

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { error: 'Demasiados intentos. Espera antes de volver a iniciar sesión.' },
});

app.get('/api/health', async (request, response, next) => {
  try {
    await pool.query('SELECT 1 FROM appointments LIMIT 0');
    response.json({ status: 'ok', database: 'connected' });
  } catch (error) {
    next(error);
  }
});

app.get('/api/availability', async (request, response, next) => {
  try {
    const date = request.query.date;
    const serviceId = request.query.serviceId;
    if (!parseDate(date)) throw new ApiError(400, 'Indica una fecha válida con formato AAAA-MM-DD.');
    if (date < dateInTimeZone(new Date(), timeZone)) {
      throw new ApiError(400, 'No puedes consultar horarios de una fecha pasada.');
    }
    if (!serviceId) throw new ApiError(400, 'Indica el servicio que deseas reservar.');
    const service = await getService(serviceId);
    const slots = await getAvailableSlots(date, service);
    response.json({
      date,
      serviceId: service.service_id,
      price: Number(service.price),
      morning: slots.filter((time) => Number(time.slice(0, 2)) < 12),
      afternoon: slots.filter((time) => Number(time.slice(0, 2)) >= 12),
    });
  } catch (error) {
    next(error);
  }
});

app.get('/api/appointments', async (request, response, next) => {
  try {
    const email = String(request.query.email || '').trim();
    if (!email || email.length > 254) {
      throw new ApiError(400, 'Se requiere un correo válido.');
    }
    const [rows] = await pool.execute(
      `SELECT event_id, service_name, start_at, end_at, status
       FROM appointments
       WHERE customer_email = ?
       ORDER BY start_at`,
      [email],
    );
    response.json(rows.map((row) => ({
      eventId: row.event_id,
      serviceName: row.service_name,
      start: new Date(row.start_at).toISOString(),
      end: new Date(row.end_at).toISOString(),
      status: row.status,
    })));
  } catch (error) {
    next(error);
  }
});

app.post('/api/appointments', async (request, response, next) => {
  try {
    const appointment = await createAppointment(request, request.body);
    response.status(201).json(appointment);
  } catch (error) {
    next(error);
  }
});

app.post('/api/admin/login', loginLimiter);
app.use('/api/admin', createAdminRoutes(pool));

const publicAdminDir = path.join(__dirname, 'public');
app.use('/admin', express.static(publicAdminDir));
app.get('/admin', (request, response) => {
  response.sendFile(path.join(publicAdminDir, 'index.html'));
});

app.use((error, request, response, next) => {
  if (error instanceof ApiError) {
    return response.status(error.status).json({ error: error.message });
  }
  console.error(error);
  return response.status(500).json({ error: 'Error interno del servidor.' });
});

let server;
if (require.main === module) {
  const fs = require('node:fs');
  fs.promises
    .readFile(path.join(__dirname, '../migrations/002_admin.sql'), 'utf8')
    .then((migration) => pool.query(migration))
    .then(() => {
      server = app.listen(port, '0.0.0.0', () => {
        console.log(`Anne Nail Studio API escuchando en el puerto ${port}`);
      });
    })
    .catch((error) => {
      console.error('No se pudo aplicar la migración 002_admin.sql:', error);
      process.exitCode = 1;
    });
}

async function shutdown() {
  if (server) await new Promise((resolve) => server.close(resolve));
  await pool.end();
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

module.exports = { app, pool, shutdown };
