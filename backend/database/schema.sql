-- Esquema de Anne Nail Studio para MySQL 8.
-- Mismas tablas y columnas que la version anterior; solo cambian indices,
-- motor explicito y restricciones de integridad.
-- La base la crea y selecciona scripts/run-sql.js con el DB_NAME del .env.

CREATE TABLE IF NOT EXISTS usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  correo VARCHAR(120) NOT NULL,
  contrasena_hash VARCHAR(255) NOT NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_usuarios_correo (correo)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS servicios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  costo DECIMAL(10,2) NOT NULL,
  duracion_min INT NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT chk_servicios_costo CHECK (costo > 0),
  CONSTRAINT chk_servicios_duracion CHECK (duracion_min > 0),
  KEY idx_servicios_activo_nombre (activo, nombre)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS manicuristas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  KEY idx_manicuristas_activo_nombre (activo, nombre)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS citas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  servicio_id INT NOT NULL,
  usuario_id INT NOT NULL,
  manicurista_id INT NULL,
  fecha DATE NOT NULL,
  hora TIME NOT NULL,
  hora_fin TIME NOT NULL,
  precio DECIMAL(10,2) NOT NULL,
  telefono VARCHAR(32) NULL,
  estado ENUM('pendiente','agendada','cancelada','rechazada') NOT NULL DEFAULT 'pendiente',
  google_event_id VARCHAR(255) NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_citas_horario CHECK (hora_fin > hora),
  CONSTRAINT chk_citas_precio CHECK (precio >= 0),
  CONSTRAINT fk_citas_servicio FOREIGN KEY (servicio_id) REFERENCES servicios (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_citas_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_citas_manicurista FOREIGN KEY (manicurista_id) REFERENCES manicuristas (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  -- Disponibilidad y solapamiento: un dia, sin canceladas, por rango de hora.
  KEY idx_citas_agenda (fecha, estado, hora, hora_fin),
  -- "Mis citas" y borrado de usuarios: agrupado por cliente y ordenado por fecha.
  KEY idx_citas_usuario (usuario_id, fecha, hora),
  -- Listado del panel filtrado por estado y ordenado por fecha descendente.
  KEY idx_citas_estado_fecha (estado, fecha, hora),
  -- Comprobacion de servicio/manicurista en uso antes de borrar.
  KEY idx_citas_servicio (servicio_id),
  KEY idx_citas_manicurista (manicurista_id)
) ENGINE=InnoDB;
