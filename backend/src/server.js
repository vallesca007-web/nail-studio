require('dotenv').config();

const http = require('node:http');
const { createPool } = require('mysql2/promise');

const port = Number(process.env.PORT || 3000);
const pool = createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'anne_nail_studio',
  connectionLimit: 10,
  timezone: 'Z',
});

function send(response, status, body) {
  response.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET, POST, OPTIONS',
    'access-control-allow-headers': 'content-type',
  });
  response.end(JSON.stringify(body));
}

function parseDate(value) {
  if (typeof value !== 'string' || !Number.isFinite(Date.parse(value))) {
    return null;
  }
  return new Date(value);
}

async function readJson(request) {
  let raw = '';
  for await (const chunk of request) {
    raw += chunk;
    if (raw.length > 16_384) {
      throw new Error('El cuerpo de la solicitud es demasiado grande.');
    }
  }
  return JSON.parse(raw);
}

const server = http.createServer(async (request, response) => {
  const url = new URL(
    request.url,
    `http://${request.headers.host || 'localhost'}`,
  );
  if (request.method === 'OPTIONS') {
    send(response, 204, {});
    return;
  }

  try {
    if (request.method === 'GET' && url.pathname === '/api/health') {
      await pool.query('SELECT 1');
      send(response, 200, { status: 'ok', database: 'connected' });
      return;
    }

    if (request.method === 'GET' && url.pathname === '/api/appointments') {
      const email = (url.searchParams.get('email') || '').trim();
      if (!email || email.length > 254) {
        send(response, 400, { error: 'Se requiere un correo válido.' });
        return;
      }
      const [rows] = await pool.execute(
        `SELECT event_id, service_name, start_at, end_at,
                customer_name, customer_email
         FROM appointments
         WHERE customer_email = ?
         ORDER BY start_at`,
        [email],
      );
      send(
        response,
        200,
        rows.map((row) => ({
          eventId: row.event_id,
          serviceName: row.service_name,
          start: new Date(row.start_at).toISOString(),
          end: new Date(row.end_at).toISOString(),
          customerName: row.customer_name,
          customerEmail: row.customer_email,
        })),
      );
      return;
    }

    if (request.method === 'POST' && url.pathname === '/api/appointments') {
      let appointment;
      try {
        appointment = await readJson(request);
      } catch {
        send(response, 400, { error: 'El cuerpo JSON no es válido.' });
        return;
      }
      if (!appointment || typeof appointment !== 'object' || Array.isArray(appointment)) {
        send(response, 400, { error: 'Los datos de la cita son inválidos.' });
        return;
      }
      const start = parseDate(appointment.start);
      const end = parseDate(appointment.end);
      const fields = [
        ['eventId', 128],
        ['serviceName', 160],
        ['customerName', 160],
        ['customerEmail', 254],
      ];
      const invalid = fields.some(
        ([field, maxLength]) =>
          typeof appointment[field] !== 'string' ||
          !appointment[field].trim() ||
          appointment[field].trim().length > maxLength,
      );
      if (invalid || !start || !end || end <= start) {
        send(response, 400, { error: 'Los datos de la cita son inválidos.' });
        return;
      }
      await pool.execute(
        `INSERT INTO appointments
          (event_id, service_name, start_at, end_at, customer_name, customer_email)
         VALUES (?, ?, ?, ?, ?, ?)`,
        [
          appointment.eventId.trim(),
          appointment.serviceName.trim(),
          start,
          end,
          appointment.customerName.trim(),
          appointment.customerEmail.trim(),
        ],
      );
      send(response, 201, { saved: true });
      return;
    }

    send(response, 404, { error: 'Ruta no encontrada.' });
  } catch (error) {
    console.error(error);
    if (error.code === 'ER_DUP_ENTRY') {
      send(response, 409, { error: 'Esta cita ya está registrada.' });
      return;
    }
    send(response, 500, { error: 'Error interno del servidor.' });
  }
});

server.listen(port, '0.0.0.0', () => {
  console.log(`Anne Nail Studio API escuchando en el puerto ${port}`);
});

async function shutdown() {
  server.close();
  await pool.end();
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
