USE anne_nail_studio;

CREATE TABLE IF NOT EXISTS services (
  service_id VARCHAR(64) PRIMARY KEY,
  name VARCHAR(160) NOT NULL,
  duration_minutes SMALLINT UNSIGNED NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
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
