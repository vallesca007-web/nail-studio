const test = require('node:test');
const assert = require('node:assert/strict');

const { app, pool, shutdown } = require('../src/server');

test('new-schema authentication and reservation HTTP cases', async () => {
  const server = app.listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  const email = `test-${Date.now()}@example.com`;
<<<<<<< HEAD
  const futureDate = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
  const pastDate = new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
=======
>>>>>>> origin/main
  let userId;
  let token;

  try {
<<<<<<< HEAD
    let response = await fetch(`${base}/api/servicios?categoria=unisex`);
    assert.equal(response.status, 400);

    response = await fetch(`${base}/api/auth/register`, {
=======
    let response = await fetch(`${base}/api/auth/register`, {
>>>>>>> origin/main
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

<<<<<<< HEAD
    response = await fetch(`${base}/api/availability?date=${futureDate}&serviceId=999`);
=======
    response = await fetch(`${base}/api/availability?date=2026-11-24&serviceId=999`);
>>>>>>> origin/main
    assert.equal(response.status, 404);

    response = await fetch(`${base}/api/appointments`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({
        servicio_id: 1,
<<<<<<< HEAD
        fecha: pastDate,
=======
        fecha: '2026-11-24',
>>>>>>> origin/main
        hora: '18:00',
        telefono: '6565550101',
      }),
    });
<<<<<<< HEAD
    assert.equal(response.status, 400);
=======
    assert.equal(response.status, 409);
>>>>>>> origin/main
  } finally {
    if (userId) {
      await pool.execute('DELETE FROM usuarios WHERE id = ?', [userId]);
    }
    await new Promise((resolve) => server.close(resolve));
    await pool.end();
  }
});
