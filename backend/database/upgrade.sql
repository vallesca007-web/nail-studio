-- Migracion para una base creada con la version anterior de schema.sql.
-- No borra ni modifica filas: solo agrega indices y restricciones.
-- Respalda antes: mysqldump -u root -p anne_nail_studio > respaldo.sql
-- Ejecutar una sola vez: npm run db:upgrade

USE anne_nail_studio;

ALTER TABLE servicios
  ADD INDEX idx_servicios_activo_nombre (activo, nombre);

ALTER TABLE manicuristas
  ADD INDEX idx_manicuristas_activo_nombre (activo, nombre);

ALTER TABLE citas
  DROP INDEX idx_citas_fecha_hora,
  DROP INDEX idx_citas_estado,
  ADD INDEX idx_citas_agenda (fecha, estado, hora, hora_fin),
  ADD INDEX idx_citas_usuario (usuario_id, fecha, hora),
  ADD INDEX idx_citas_estado_fecha (estado, fecha, hora),
  ADD INDEX idx_citas_servicio (servicio_id),
  ADD INDEX idx_citas_manicurista (manicurista_id),
  ADD CONSTRAINT chk_citas_horario CHECK (hora_fin > hora),
  ADD CONSTRAINT chk_citas_precio CHECK (precio >= 0);
