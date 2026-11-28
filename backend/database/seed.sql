INSERT INTO servicios
  (nombre, costo, duracion_min, activo, categoria, grupo, descripcion, orden)
SELECT 'Manicura', 390.00, 60, TRUE, 'manicura', 'Manicura',
       'Cuidado de uñas naturales, limado y acabado limpio.', 1
WHERE NOT EXISTS (SELECT 1 FROM servicios WHERE nombre = 'Manicura');

INSERT INTO servicios
  (nombre, costo, duracion_min, activo, categoria, grupo, descripcion, orden)
SELECT 'Esmaltado permanente', 450.00, 60, TRUE, 'manicura', 'Color',
       'Color en gel de larga duración con preparación de la uña.', 2
WHERE NOT EXISTS (SELECT 1 FROM servicios WHERE nombre = 'Esmaltado permanente');

INSERT INTO servicios
  (nombre, costo, duracion_min, activo, categoria, grupo, descripcion, orden)
SELECT 'Uñas esculturales', 790.00, 120, TRUE, 'manicura', 'Acrílico / PolyGel',
       'Extensión esculpida y terminada al largo que prefieras.', 3
WHERE NOT EXISTS (SELECT 1 FROM servicios WHERE nombre = 'Uñas esculturales');

INSERT INTO servicios
  (nombre, costo, duracion_min, activo, categoria, grupo, descripcion, orden)
SELECT 'Pedicura', 490.00, 60, TRUE, 'pedicura', 'Pedicura',
       'Limpieza, cuidado de uñas y suavizado de los pies.', 1
WHERE NOT EXISTS (SELECT 1 FROM servicios WHERE nombre = 'Pedicura');

INSERT INTO servicios
  (nombre, costo, duracion_min, activo, categoria, grupo, descripcion, orden)
SELECT 'Softgel', 690.00, 90, TRUE, 'manicura', 'Acrílico / PolyGel',
       'Extensión ligera con acabado uniforme y natural.', 4
WHERE NOT EXISTS (SELECT 1 FROM servicios WHERE nombre = 'Softgel');

INSERT INTO servicios
  (nombre, costo, duracion_min, activo, categoria, grupo, descripcion, orden)
SELECT 'Poligel', 750.00, 90, TRUE, 'manicura', 'Acrílico / PolyGel',
       'Refuerzo y extensión con estructura resistente y ligera.', 5
WHERE NOT EXISTS (SELECT 1 FROM servicios WHERE nombre = 'Poligel');

UPDATE servicios SET
  categoria = 'manicura', grupo = 'Manicura',
  descripcion = 'Cuidado de uñas naturales, limado y acabado limpio.',
  orden = 1
WHERE nombre = 'Manicura';

UPDATE servicios SET
  categoria = 'manicura', grupo = 'Color',
  descripcion = 'Color en gel de larga duración con preparación de la uña.',
  orden = 2
WHERE nombre = 'Esmaltado permanente';

UPDATE servicios SET
  categoria = 'manicura', grupo = 'Acrílico / PolyGel',
  descripcion = 'Extensión esculpida y terminada al largo que prefieras.',
  orden = 3
WHERE nombre = 'Uñas esculturales';

UPDATE servicios SET
  categoria = 'pedicura', grupo = 'Pedicura',
  descripcion = 'Limpieza, cuidado de uñas y suavizado de los pies.',
  orden = 1
WHERE nombre = 'Pedicura';

UPDATE servicios SET
  categoria = 'manicura', grupo = 'Acrílico / PolyGel',
  descripcion = 'Extensión ligera con acabado uniforme y natural.',
  orden = 4
WHERE nombre = 'Softgel';

UPDATE servicios SET
  categoria = 'manicura', grupo = 'Acrílico / PolyGel',
  descripcion = 'Refuerzo y extensión con estructura resistente y ligera.',
  orden = 5
WHERE nombre = 'Poligel';

INSERT INTO manicuristas (nombre, activo)
SELECT 'Manicurista de prueba', TRUE
WHERE NOT EXISTS (
  SELECT 1 FROM manicuristas WHERE nombre = 'Manicurista de prueba'
);
