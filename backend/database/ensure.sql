-- Ajustes que se pueden repetir sin perder filas. Se ejecutan al final de
-- npm run db:schema para que una base creada antes siga funcionando.
-- SECCION: estados de una cita

ALTER TABLE citas
  MODIFY estado ENUM('pendiente','agendada','cancelada','rechazada') NOT NULL DEFAULT 'pendiente';
