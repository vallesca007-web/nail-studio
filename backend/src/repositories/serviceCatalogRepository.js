module.exports = function createServiceCatalogRepository(pool) {
  return {
    async listActiveByCategory(category) {
      const [rows] = await pool.execute(
        `SELECT id, nombre, descripcion, grupo, costo, duracion_min
         FROM servicios
         WHERE activo = TRUE AND categoria = ?
         ORDER BY grupo, orden, nombre`,
        [category],
      );
      return rows.map((row) => ({ ...row, costo: Number(row.costo) }));
    },
  };
};
