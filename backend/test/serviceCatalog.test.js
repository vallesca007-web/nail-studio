const test = require('node:test');
const assert = require('node:assert/strict');

const createServiceCatalogController = require('../src/controllers/serviceCatalogController');
const createServiceCatalogRepository = require('../src/repositories/serviceCatalogRepository');

test('service catalog rejects unsupported categories without querying the database', async () => {
  let queried = false;
  const controller = createServiceCatalogController({
    async listActiveByCategory() {
      queried = true;
      return [];
    },
  });
  const response = {
    statusCode: 200,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(value) {
      this.body = value;
      return this;
    },
  };

  await controller({ query: { categoria: 'unisex' } }, response);

  assert.equal(response.statusCode, 400);
  assert.deepEqual(response.body, {
    error: 'La categoría debe ser manicura o pedicura.',
  });
  assert.equal(queried, false);
});

test('service catalog repository parameterizes category and returns numeric prices', async () => {
  let query;
  let parameters;
  const repository = createServiceCatalogRepository({
    async execute(sql, values) {
      query = sql;
      parameters = values;
      return [[{ id: 8, nombre: 'Manicura', costo: '390.00', duracion_min: 60 }]];
    },
  });

  const services = await repository.listActiveByCategory('manicura');

  assert.deepEqual(parameters, ['manicura']);
  assert.match(query, /activo = TRUE AND categoria = \?/);
  assert.match(query, /ORDER BY grupo, orden, nombre/);
  assert.equal(services[0].costo, 390);
});
