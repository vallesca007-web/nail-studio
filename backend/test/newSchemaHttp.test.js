const test = require('node:test');
const assert = require('node:assert/strict');

const { app, pool, shutdown } = require('../src/server');

test('new-schema authentication and reservation HTTP cases', async () => {
  const server = app.listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  const email = `test-${Date.now()}@example.com`;
  let userId;
  let token;

  try {
    let response = await fetch(`${base}/api/auth/register`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ correo: email, contrasena: 'TestSeguro123!' }),
    });
    assert.equal(response.status, 201);
    userId = (await response.json()).id;

    response = await fetch(`${base}/api/auth/register`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ correo: email, contrasena: 'TestSeguro123!' }),
    });
    assert.equal(response.status, 409);

    response = await fetch(`${base}/api/auth/login`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ correo: email, contrasena: 'incorrecta' }),
    });
    assert.equal(response.status, 401);

    response = await fetch(`${base}/api/auth/login`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ correo: email, contrasena: 'TestSeguro123!' }),
    });
    assert.equal(response.status, 200);
    token = (await response.json()).token;

    response = await fetch(`${base}/api/availability?date=2026-11-24&serviceId=999`);
    assert.equal(response.status, 404);

    response = await fetch(`${base}/api/appointments`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        servicio_id: 1,
        fecha: '2026-11-24',
        hora: '18:00',
        telefono: '6565550101',
      }),
    });
    assert.equal(response.status, 409);
  } finally {
    if (userId) {
      await pool.execute('DELETE FROM usuarios WHERE id = ?', [userId]);
    }
    await new Promise((resolve) => server.close(resolve));
    await pool.end();
  }
});
