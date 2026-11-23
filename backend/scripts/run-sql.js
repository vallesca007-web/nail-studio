const fs = require('node:fs');
const path = require('node:path');
const readline = require('node:readline');
const mysql = require('mysql2/promise');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

const files = {
  'setup-local': '../database/setup-local.sql',
  schema: '../database/schema.sql',
  seed: '../database/seed.sql',
  upgrade: '../database/upgrade.sql',
};

const type = process.argv[2];
const dbName = process.env.DB_NAME || 'AnneNail';
let connection;

function ask(question, fallbackMessage) {
  if (!process.stdin.isTTY) throw new Error(fallbackMessage);
  const input = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  return new Promise((resolve) => {
    input.question(question, (answer) => {
      input.close();
      resolve(answer);
    });
  });
}

// El nombre se interpola en el SQL, asi que solo se aceptan identificadores simples.
function quotedDatabase() {
  if (!/^[A-Za-z0-9_$]+$/.test(dbName)) {
    throw new Error(`DB_NAME no es un nombre de base valido: ${dbName}`);
  }
  return `\`${dbName}\``;
}

async function rootPassword() {
  // Una variable definida pero vacia es valida: root sin contrasena.
  if (process.env.DB_ROOT_PASSWORD !== undefined) return process.env.DB_ROOT_PASSWORD;
  return ask(
    'Contrasena root de MySQL local: ',
    'No hay terminal interactiva: define DB_ROOT_PASSWORD en el .env.',
  );
}

function readSql(file) {
  return fs
    .readFileSync(path.resolve(__dirname, files[file]), 'utf8')
    .replaceAll('__DB_NAME__', quotedDatabase());
}

// CREATE TABLE IF NOT EXISTS no toca una tabla vieja con otras columnas:
// se avisa para que no falle despues como "Unknown column" en la API.
const expectedColumns = {
  usuarios: ['correo', 'contrasena_hash'],
  citas: ['manicurista_id', 'fecha', 'hora', 'hora_fin', 'precio'],
};

async function warnIfLegacy() {
  for (const [table, expected] of Object.entries(expectedColumns)) {
    const [rows] = await connection.query(
      'SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?',
      [table],
    );
    const columns = rows.map((row) => row.COLUMN_NAME);
    const missing = expected.filter((column) => !columns.includes(column));
    if (missing.length > 0) {
      console.warn(
        `Aviso: la tabla ${table} ya existia sin ${missing.join(', ')}. ` +
        'Si no hay datos que conservar, ejecuta npm run db:reset.',
      );
    }
  }
}

async function main() {
  if (!files[type] && type !== 'reset') {
    throw new Error('Uso: npm run db:setup | db:schema | db:seed | db:upgrade | db:reset');
  }
  const database = quotedDatabase();

  let sql = null;
  if (type !== 'reset') {
    sql = readSql(type);
    if (type === 'setup-local') {
      const password = process.env.DB_PASSWORD;
      if (!password) throw new Error('Falta DB_PASSWORD en .env.');
      sql = sql.replaceAll('REEMPLAZAR_CON_DB_PASSWORD', password);
    }
  }

  if (type === 'reset') {
    const answer = process.argv[3] === '--yes'
      ? dbName
      : await ask(
        `Esto borra la base ${dbName} con todas sus filas. Escribe "${dbName}" para continuar: `,
        'No hay terminal interactiva: confirma con npm run db:reset -- --yes',
      );
    if (answer.trim() !== dbName) throw new Error('Cancelado: no se borro nada.');
  }

  const useRoot = type === 'setup-local';
  connection = await mysql.createConnection({
    host: process.env.DB_HOST || '127.0.0.1',
    port: Number(process.env.DB_PORT || 3306),
    user: useRoot ? 'root' : (process.env.DB_USER || 'root'),
    password: useRoot ? await rootPassword() : (process.env.DB_PASSWORD || ''),
    multipleStatements: true,
  });

  if (type === 'reset') {
    await connection.query(`DROP DATABASE IF EXISTS ${database}`);
  }
  await connection.query(
    `CREATE DATABASE IF NOT EXISTS ${database} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`,
  );
  await connection.query(`USE ${database}`);

  if (type === 'reset') {
    await connection.query(readSql('schema'));
    await connection.query(readSql('seed'));
  } else {
    await connection.query(sql);
  }

  if (type === 'schema') await warnIfLegacy();

  await connection.end();
  console.log(`Ejecutado en la base ${dbName}.`);
}

main().catch(async (error) => {
  console.error(error.message);
  process.exitCode = 1;
  if (connection) await connection.end().catch(() => {});
});
