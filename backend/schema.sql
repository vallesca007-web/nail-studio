CREATE DATABASE IF NOT EXISTS anne_nail_studio
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE anne_nail_studio;

CREATE TABLE IF NOT EXISTS services (
  service_id VARCHAR(64) PRIMARY KEY,
  name VARCHAR(160) NOT NULL,
  duration_minutes SMALLINT UNSIGNED NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  description VARCHAR(500) NOT NULL DEFAULT '',
  category VARCHAR(100) NOT NULL DEFAULT 'General',
  active BOOLEAN NOT NULL DEFAULT TRUE
);

INSERT INTO services (service_id, name, duration_minutes, price, active)
VALUES (
  'signature-manicura-rusa',
  'Manicura Rusa & Esmaltado',
  60,
  45.00,
  TRUE
)
ON DUPLICATE KEY UPDATE
  name = VALUES(name),
  duration_minutes = VALUES(duration_minutes),
  price = VALUES(price),
  active = TRUE;

CREATE TABLE IF NOT EXISTS appointments (
  event_id VARCHAR(128) PRIMARY KEY,
  service_id VARCHAR(64) NOT NULL,
  reservation_code VARCHAR(32) NOT NULL UNIQUE,
  service_name VARCHAR(160) NOT NULL,
  start_at DATETIME(3) NOT NULL,
  end_at DATETIME(3) NOT NULL,
  customer_name VARCHAR(160) NOT NULL,
  customer_email VARCHAR(254) NOT NULL,
  customer_phone VARCHAR(32) NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'pendiente',
  specialist_id VARCHAR(64) NULL,
  price DECIMAL(10, 2) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_appointments_service
    FOREIGN KEY (service_id) REFERENCES services (service_id),
  INDEX idx_appointments_customer_start (customer_email, start_at),
  INDEX idx_appointments_schedule (start_at, end_at)
);
