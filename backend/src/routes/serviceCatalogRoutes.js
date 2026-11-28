const express = require('express');

const asyncHandler = require('../middleware/asyncHandler');
const createServiceCatalogController = require('../controllers/serviceCatalogController');
const createServiceCatalogRepository = require('../repositories/serviceCatalogRepository');

module.exports = function createServiceCatalogRoutes(pool) {
  const router = express.Router();
  const listServices = createServiceCatalogController(
    createServiceCatalogRepository(pool),
  );

  router.get('/', asyncHandler(listServices));
  return router;
};
