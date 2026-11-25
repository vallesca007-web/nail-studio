const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const rootDir = path.resolve(__dirname, '../..');
const envPath = path.join(rootDir, '.env');
const legacyPath = path.join(rootDir, '.env.txt');
const examplePath = path.join(rootDir, '.env.example');

// Valores que pide la configuracion local. Solo se usan cuando la variable no
// existe o esta vacia: un .env ya configurado nunca se sobrescribe.
const defaults = {
  DB_HOST: '127.0.0.1',
  DB_PORT: '3306',
  DB_NAME: 'anne_nail_studio',
  DB_USER: 'anne_nail_app',
  GOOGLE_APPLICATION_CREDENTIALS: './backend/.credentials/service-account.json',
  TIMEZONE: 'America/Mexico_City',
};

// Variables de la epoca de Docker: se eliminan al normalizar el archivo.
const dockerOnly = new Set(['MYSQL_ROOT_PASSWORD', 'GOOGLE_CREDENTIALS_DIR']);
const isDockerSecretPath = (value) => value.startsWith('/run/secrets');
const placeholders = /^(tu-|your-|replace|cambia|reemplazar)/i;

function parse(content) {
  const entries = [];
  for (const rawLine of content.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;
    const separator = line.indexOf('=');
    if (separator === -1) continue;
    const key = line.slice(0, separator).trim();
    const value = line.slice(separator + 1).trim().replace(/^["']|["']$/g, '');
    if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(key)) continue;
    entries.push({ key, value });
  }
  return entries;
}

function isUnset(value) {
  return value === undefined || value === '' || placeholders.test(value);
}

// Si existe .env.txt y todavia no hay .env, se renombra sin tocar su contenido.
if (!fs.existsSync(envPath) && fs.existsSync(legacyPath)) {
  fs.renameSync(legacyPath, envPath);
  console.log('Renombrado .env.txt -> .env');
}

const exampleEntries = fs.existsSync(examplePath)
  ? parse(fs.readFileSync(examplePath, 'utf8'))
  : [];
const existingEntries = fs.existsSync(envPath)
  ? parse(fs.readFileSync(envPath, 'utf8'))
  : [];

const example = new Map(exampleEntries.map((entry) => [entry.key, entry.value]));
const existing = new Map(existingEntries.map((entry) => [entry.key, entry.value]));
const orderedKeys = [...exampleEntries.map((entry) => entry.key)];
for (const { key } of existingEntries) {
  if (!orderedKeys.includes(key)) orderedKeys.push(key);
}

const removed = [];
const added = [];
const values = new Map();

for (const key of orderedKeys) {
  if (dockerOnly.has(key) || isDockerSecretPath(existing.get(key) || '')) {
    removed.push(key);
    continue;
  }
  const current = existing.get(key);
  if (!isUnset(current)) {
    values.set(key, current);
    continue;
  }
  if (defaults[key] !== undefined) {
    values.set(key, defaults[key]);
    added.push(key);
    continue;
  }
  // Se hereda el valor del ejemplo (por ejemplo BUSINESS_OPEN_HOUR=10); si
  // tampoco lo trae, queda vacio y el codigo usa su valor por defecto.
  values.set(key, isUnset(example.get(key)) ? '' : example.get(key));
}

if (isUnset(values.get('DB_PASSWORD'))) {
  values.set('DB_PASSWORD', crypto.randomBytes(24).toString('hex'));
  added.push('DB_PASSWORD');
}
if (isUnset(values.get('JWT_SECRET'))) {
  values.set('JWT_SECRET', crypto.randomBytes(32).toString('hex'));
  added.push('JWT_SECRET');
}

const lines = [
  '# Generado por scripts/env-init.js. No se versiona: la contrasena y el',
  '# secreto viven solo en este archivo.',
  ...orderedKeys
    .filter((key) => values.has(key))
    .map((key) => `${key}=${values.get(key)}`),
  '',
];

fs.writeFileSync(envPath, lines.join('\n'), { mode: 0o600 });

console.log(`Archivo .env listo en ${envPath}`);
if (existingEntries.length) console.log('Valores existentes conservados.');
if (added.length) console.log(`Variables agregadas: ${added.join(', ')}.`);
if (removed.length) console.log(`Variables de Docker eliminadas: ${removed.join(', ')}.`);
console.log('Revisa el archivo y ejecuta: npm run db:setup');
