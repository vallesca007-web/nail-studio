USE anne_nail_studio;

CREATE TABLE IF NOT EXISTS specialists (
  specialist_id VARCHAR(64) PRIMARY KEY,
  name VARCHAR(160) NOT NULL,
  specialty VARCHAR(160) NOT NULL DEFAULT '',
  photo_url VARCHAR(1024) NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

SET @has_description = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'services' AND COLUMN_NAME = 'description'
);
SET @sql = IF(
  @has_description = 0,
  CONCAT('ALTER TABLE services ADD COLUMN description VARCHAR(500) NOT NULL DEFAULT ', CHAR(39), CHAR(39)),
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_category = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'services' AND COLUMN_NAME = 'category'
);
SET @sql = IF(@has_category = 0, 'ALTER TABLE services ADD COLUMN category VARCHAR(100) NOT NULL DEFAULT ''General''', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_service_active = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'services' AND COLUMN_NAME = 'active'
);
SET @sql = IF(@has_service_active = 0, 'ALTER TABLE services ADD COLUMN active BOOLEAN NOT NULL DEFAULT TRUE', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_phone = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'appointments' AND COLUMN_NAME = 'customer_phone'
);
SET @sql = IF(@has_phone = 0, 'ALTER TABLE appointments ADD COLUMN customer_phone VARCHAR(32) NULL', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_status = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'appointments' AND COLUMN_NAME = 'status'
);
SET @sql = IF(@has_status = 0, 'ALTER TABLE appointments ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT ''pendiente''', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

ALTER TABLE appointments
  MODIFY COLUMN status VARCHAR(20) NOT NULL DEFAULT 'pendiente';

SET @has_specialist = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'appointments' AND COLUMN_NAME = 'specialist_id'
);
SET @sql = IF(@has_specialist = 0, 'ALTER TABLE appointments ADD COLUMN specialist_id VARCHAR(64) NULL', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_price = (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'appointments' AND COLUMN_NAME = 'price'
);
SET @sql = IF(@has_price = 0, 'ALTER TABLE appointments ADD COLUMN price DECIMAL(10, 2) NULL', 'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

UPDATE appointments
SET status = 'pendiente'
WHERE status IS NULL OR status NOT IN ('pendiente', 'agendada');

UPDATE appointments AS a
JOIN services AS s ON s.service_id = a.service_id
SET a.price = s.price
WHERE a.price IS NULL;

SET @has_fk = (
  SELECT COUNT(*)
  FROM information_schema.TABLE_CONSTRAINTS
  WHERE CONSTRAINT_SCHEMA = DATABASE()
    AND TABLE_NAME = 'appointments'
    AND CONSTRAINT_NAME = 'fk_appointments_specialist'
);
SET @sql = IF(
  @has_fk = 0,
  'ALTER TABLE appointments ADD CONSTRAINT fk_appointments_specialist FOREIGN KEY (specialist_id) REFERENCES specialists (specialist_id)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_status_index = (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'appointments'
    AND INDEX_NAME = 'idx_appointments_status_start'
);
SET @sql = IF(
  @has_status_index = 0,
  'CREATE INDEX idx_appointments_status_start ON appointments (status, start_at)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @has_specialist_index = (
  SELECT COUNT(*)
  FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'appointments'
    AND INDEX_NAME = 'idx_appointments_specialist'
);
SET @sql = IF(
  @has_specialist_index = 0,
  'CREATE INDEX idx_appointments_specialist ON appointments (specialist_id)',
  'SELECT 1'
);
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
