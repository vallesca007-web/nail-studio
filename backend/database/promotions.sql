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

INSERT INTO promociones (titulo, etiqueta, descripcion, fecha_fin, activo)
SELECT 'Bienvenida al estudio', '10% OFF',
       'Recibe 10% de descuento en tu primera visita. Muestra esta promoción al reservar.',
       NULL, TRUE
WHERE NOT EXISTS (
  SELECT 1 FROM promociones WHERE titulo = 'Bienvenida al estudio'
);
