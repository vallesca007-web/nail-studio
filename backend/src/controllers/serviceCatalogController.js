const categories = new Set(['manicura', 'pedicura']);

module.exports = function createServiceCatalogController(repository) {
  return async function listServices(request, response) {
    const category = request.query.categoria;
    if (typeof category !== 'string' || !categories.has(category)) {
      return response.status(400).json({
        error: 'La categoría debe ser manicura o pedicura.',
      });
    }

    const services = await repository.listActiveByCategory(category);
    response.json(services);
  };
};
