CREATE DATABASE IF NOT EXISTS anne_nail_studio
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE anne_nail_studio;

CREATE TABLE IF NOT EXISTS appointments (
  event_id VARCHAR(128) PRIMARY KEY,
  service_name VARCHAR(160) NOT NULL,
  start_at DATETIME(3) NOT NULL,
  end_at DATETIME(3) NOT NULL,
  customer_name VARCHAR(160) NOT NULL,
  customer_email VARCHAR(254) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_appointments_customer_start (customer_email, start_at)
);
