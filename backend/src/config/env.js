const fs = require('node:fs');
const path = require('node:path');
const dotenv = require('dotenv');

// Ruta absoluta a la raiz del repo, sin importar desde que carpeta se ejecute
// el proceso (backend/, raiz, npm --prefix, etc.).
const projectRoot = path.resolve(__dirname, '../../..');
const candidates = [
  path.join(projectRoot, '.env'),
  path.join(projectRoot, 'backend', '.env'),
];

const requiredVariables = {
  DB_PASSWORD: 'la conexion a MySQL fallara',
  JWT_SECRET: 'el inicio de sesion fallara',
};

function loadEnvironment() {
  const file = candidates.find((candidate) => fs.existsSync(candidate));

  if (!file) {
    console.warn(
      `No se encontro .env en ${path.join(projectRoot, '.env')}. ` +
        'Crea uno con: npm run env:init',
    );
  } else {
    dotenv.config({ path: file, quiet: true });
    console.log(`Configuracion leida de: ${path.relative(projectRoot, file)}`);
    if (file === candidates[1]) {
      console.warn('El .env esta en backend/. Se recomienda moverlo a la raiz del proyecto.');
    }
  }

  // Se nombra cada variable que falta para no perder tiempo adivinando.
  const missing = Object.keys(requiredVariables).filter((name) => !process.env[name]);
  for (const name of missing) {
    console.warn(`Falta ${name} en el .env: ${requiredVariables[name]}.`);
  }

  return { file, missing };
}

module.exports = { loadEnvironment, projectRoot };
