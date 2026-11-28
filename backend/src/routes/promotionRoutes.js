const express = require('express');

const asyncHandler = require('../middleware/asyncHandler');

module.exports = function createPromotionRoutes(pool) {
  const router = express.Router();

  router.get('/', asyncHandler(async (request, response) => {
    const [rows] = await pool.execute(
      `SELECT id, titulo, etiqueta, descripcion, fecha_fin
       FROM promociones
       WHERE activo = TRUE
         AND (fecha_fin IS NULL OR fecha_fin >= CURRENT_DATE())
       ORDER BY creado_en DESC, id DESC`,
    );
    response.json(rows);
  }));

  return router;
};
