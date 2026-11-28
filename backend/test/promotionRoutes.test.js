const test = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');

const createPromotionRoutes = require('../src/routes/promotionRoutes');

test('public promotion catalog returns active promotions and excludes expired records', async () => {
  let query;
  const rows = [{
    id: 4,
    titulo: 'Bienvenida al estudio',
    etiqueta: '10% OFF',
    descripcion: 'Descuento para tu primera visita.',
    fecha_fin: null,
  }];
  const app = express();
  app.use('/api/promociones', createPromotionRoutes({
    async execute(sql) {
      query = sql;
      return [rows];
    },
  }));
  const server = app.listen(0, '127.0.0.1');
  await new Promise((resolve) => server.once('listening', resolve));

  try {
    const response = await fetch(
      `http://127.0.0.1:${server.address().port}/api/promociones`,
    );
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), rows);
    assert.match(query, /activo = TRUE/);
    assert.match(query, /fecha_fin IS NULL OR fecha_fin >= CURRENT_DATE\(\)/);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
});
