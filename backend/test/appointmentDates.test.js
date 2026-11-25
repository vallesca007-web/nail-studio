const test = require('node:test');
const assert = require('node:assert/strict');

const { app, pool } = require('../src/server');
const { dateInTimeZone } = require('../src/services/dateTime');

const phone = '6565550199';

// El pool es compartido por los dos casos: se cierra una sola vez al final.
test.after(async () => {
  await pool.end();
});

async function startServer() {
  const server = app.listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  return { server, base: `http://127.0.0.1:${server.address().port}` };
}

async function registerClient(base, email) {
  const registered = await fetch(`${base}/api/auth/register`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ correo: email, contrasena: 'TestSeguro123!' }),
  });
  assert.equal(registered.status, 201);
  const { id } = await registered.json();

  const logged = await fetch(`${base}/api/auth/login`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ correo: email, contrasena: 'TestSeguro123!' }),
  });
  assert.equal(logged.status, 200);
  return { id, token: (await logged.json()).token };
}

async function cleanup(userId) {
  if (!userId) return;
  await pool.execute('DELETE FROM citas WHERE usuario_id = ?', [userId]);
  await pool.execute('DELETE FROM usuarios WHERE id = ?', [userId]);
}

// Una cita guardada para el 24 de noviembre a las 10:00 tiene que volver con esa
// fecha y esa hora, sin segundos ni corrimiento de dia por la zona horaria.
test('una cita del 2026-11-24 a las 10:00 se devuelve con esa fecha y hora', async () => {
  const { server, base } = await startServer();
  const email = `fechas-${Date.now()}@example.com`;
  let userId;
  try {
    const session = await registerClient(base, email);
    userId = session.id;
    await pool.execute(
      `INSERT INTO citas (servicio_id, usuario_id, fecha, hora, hora_fin, precio, telefono, estado)
       VALUES (1, ?, '2026-11-24', '10:00:00', '11:00:00', 45, ?, 'pendiente')`,
      [userId, phone],
    );

    const response = await fetch(`${base}/api/appointments/mine`, {
      headers: { authorization: `Bearer ${session.token}` },
    });
    assert.equal(response.status, 200);
    const citas = await response.json();
    assert.equal(citas.length, 1);
    assert.equal(citas[0].fecha, '2026-11-24');
    assert.equal(citas[0].hora, '10:00');
  } finally {
    await cleanup(userId);
    await new Promise((resolve) => server.close(resolve));
  }
});

test('una clienta solo puede cancelar su propia cita activa', async () => {
  const { server, base } = await startServer();
  const suffix = Date.now();
  let ownerId;
  let otherId;
  let appointmentId;
  try {
    const owner = await registerClient(base, `cancelar-${suffix}@example.com`);
    const other = await registerClient(base, `otra-${suffix}@example.com`);
    ownerId = owner.id;
    otherId = other.id;
    const [result] = await pool.execute(
      `INSERT INTO citas (servicio_id, usuario_id, fecha, hora, hora_fin, precio, telefono, estado)
       VALUES (1, ?, '2030-01-02', '10:00:00', '11:00:00', 45, ?, 'pendiente')`,
      [ownerId, phone],
    );
    appointmentId = result.insertId;

    let response = await fetch(`${base}/api/appointments/${appointmentId}/cancel`, {
      method: 'POST',
      headers: { authorization: `Bearer ${other.token}` },
    });
    assert.equal(response.status, 404);
    const [unchanged] = await pool.execute(
      'SELECT estado FROM citas WHERE id = ?',
      [appointmentId],
    );
    assert.equal(unchanged[0].estado, 'pendiente');

    response = await fetch(`${base}/api/appointments/${appointmentId}/cancel`, {
      method: 'POST',
      headers: { authorization: `Bearer ${owner.token}` },
    });
    assert.equal(response.status, 200);
    assert.equal((await response.json()).estado, 'cancelada');

    response = await fetch(`${base}/api/appointments/${appointmentId}/cancel`, {
      method: 'POST',
      headers: { authorization: `Bearer ${owner.token}` },
    });
    assert.equal(response.status, 409);
  } finally {
    await cleanup(ownerId);
    await cleanup(otherId);
    await new Promise((resolve) => server.close(resolve));
  }
});

test('la reserva responde fecha y hora en el mismo formato que guarda', async () => {
  const { server, base } = await startServer();
  const email = `reserva-${Date.now()}@example.com`;
  let userId;
  try {
    const session = await registerClient(base, email);
    userId = session.id;

    // Cualquier dia habil futuro, para que la prueba no caduque con el tiempo.
    const timeZone = process.env.TIMEZONE || 'America/Mexico_City';
    let date = '';
    for (let days = 2; days < 12; days += 1) {
      const candidate = dateInTimeZone(new Date(Date.now() + days * 86_400_000), timeZone);
      if (new Date(`${candidate}T00:00:00Z`).getUTCDay() !== 0) {
        date = candidate;
        break;
      }
    }
    assert.ok(date, 'no se encontro un dia habil futuro');

    const hours = ['10:00', '10:30', '11:00', '11:30', '12:00', '12:30', '13:00', '13:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30', '17:00', '17:30', '18:00', '18:30'];
    let created = null;
    for (const hora of hours) {
      const response = await fetch(`${base}/api/appointments`, {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          authorization: `Bearer ${session.token}`,
        },
        body: JSON.stringify({ servicio_id: 1, fecha: date, hora, telefono: phone }),
      });
      if (response.status === 201) {
        created = await response.json();
        break;
      }
      assert.equal(response.status, 409, `reserva rechazada: ${await response.text()}`);
    }
    assert.ok(created, 'no quedo ningun horario libre para la prueba');
    assert.equal(created.fecha, date);
    assert.match(created.hora, /^\d{2}:\d{2}$/);
  } finally {
    await cleanup(userId);
    await new Promise((resolve) => server.close(resolve));
  }
});
