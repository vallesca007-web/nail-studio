const fs = require('node:fs');
const path = require('node:path');

const candidates = [
  path.resolve(__dirname, '../../../.env'),
  path.resolve(__dirname, '../../.env'),
];

// Se acepta el .env de la raiz o el de backend/; si existen los dos, manda la raiz.
function loadEnvironment() {
  const files = candidates.filter((file) => fs.existsSync(file));
  if (!files.length) {
    console.warn(
      'No se encontro ningun .env (raiz o backend/). Se usan los valores por defecto; copia .env.example a la raiz como .env.',
    );
    return [];
  }
  for (const file of files) {
    require('dotenv').config({ path: file, quiet: true });
  }
  if (files.length > 1) {
    console.warn('Hay .env en la raiz y en backend/. Se combinan y la raiz tiene prioridad.');
  }
  const projectRoot = path.resolve(__dirname, '../../..');
  console.log(
    `Configuracion leida de: ${files.map((file) => path.relative(projectRoot, file)).join(', ')}`,
  );
  return files;
}

module.exports = { loadEnvironment };
