USE anne_nail_studio;

INSERT INTO servicios (nombre, costo, duracion_min, activo)
SELECT 'Manicura', 35.00, 45, TRUE
WHERE NOT EXISTS (SELECT 1 FROM servicios WHERE nombre = 'Manicura');

INSERT INTO servicios (nombre, costo, duracion_min, activo)
SELECT 'Esmaltado permanente', 45.00, 60, TRUE
WHERE NOT EXISTS (SELECT 1 FROM servicios WHERE nombre = 'Esmaltado permanente');

INSERT INTO servicios (nombre, costo, duracion_min, activo)
SELECT 'Uñas esculturales', 55.00, 90, TRUE
WHERE NOT EXISTS (SELECT 1 FROM servicios WHERE nombre = 'Uñas esculturales');

INSERT INTO servicios (nombre, costo, duracion_min, activo)
SELECT 'Pedicura', 40.00, 60, TRUE
WHERE NOT EXISTS (SELECT 1 FROM servicios WHERE nombre = 'Pedicura');

INSERT INTO servicios (nombre, costo, duracion_min, activo)
SELECT 'Softgel', 50.00, 75, TRUE
WHERE NOT EXISTS (SELECT 1 FROM servicios WHERE nombre = 'Softgel');

INSERT INTO servicios (nombre, costo, duracion_min, activo)
SELECT 'Poligel', 52.00, 75, TRUE
WHERE NOT EXISTS (SELECT 1 FROM servicios WHERE nombre = 'Poligel');

INSERT INTO manicuristas (nombre, activo)
SELECT 'Manicurista de prueba', TRUE
WHERE NOT EXISTS (
  SELECT 1 FROM manicuristas WHERE nombre = 'Manicurista de prueba'
);
