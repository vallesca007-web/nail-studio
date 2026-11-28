CREATE DATABASE IF NOT EXISTS anne_nail_studio
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE anne_nail_studio;

CREATE TABLE IF NOT EXISTS usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  correo VARCHAR(120) NOT NULL UNIQUE,
  contrasena_hash VARCHAR(255) NOT NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS servicios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  costo DECIMAL(10,2) NOT NULL CHECK (costo > 0),
  duracion_min INT NOT NULL CHECK (duracion_min > 0),
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  categoria VARCHAR(20) NOT NULL,
  grupo VARCHAR(60) NOT NULL,
  descripcion VARCHAR(255) NULL,
  orden INT NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS promociones (
  id INT AUTO_INCREMENT PRIMARY KEY,
  titulo VARCHAR(120) NOT NULL,
  etiqueta VARCHAR(40) NOT NULL DEFAULT 'Promoción',
  descripcion VARCHAR(500) NOT NULL,
  fecha_fin DATE NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_promociones_activo_fecha_fin (activo, fecha_fin)
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
  KEY idx_citas_agenda (fecha, estado, hora, hora_fin),
  KEY idx_citas_usuario (usuario_id, fecha, hora),
  KEY idx_citas_estado_fecha (estado, fecha, hora),
  KEY idx_citas_servicio (servicio_id),
  KEY idx_citas_manicurista (manicurista_id)
) ENGINE=InnoDB;
