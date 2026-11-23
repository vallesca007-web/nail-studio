CREATE DATABASE IF NOT EXISTS anne_nail_studio CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE anne_nail_studio;

CREATE TABLE IF NOT EXISTS usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  correo VARCHAR(120) NOT NULL UNIQUE,
  contrasena_hash VARCHAR(255) NOT NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS servicios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  costo DECIMAL(10,2) NOT NULL CHECK (costo > 0),
  duracion_min INT NOT NULL CHECK (duracion_min > 0),
  activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS manicuristas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE
);

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
  estado ENUM('pendiente','agendada','cancelada') NOT NULL DEFAULT 'pendiente',
  google_event_id VARCHAR(255) NULL,
  creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (servicio_id) REFERENCES servicios(id),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
  FOREIGN KEY (manicurista_id) REFERENCES manicuristas(id),
  INDEX idx_citas_fecha_hora (fecha, hora),
  INDEX idx_citas_estado (estado)
);
