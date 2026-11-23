const fs = require('node:fs');
const path = require('node:path');
const readline = require('node:readline');
const mysql = require('mysql2/promise');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

const type = process.argv[2];
const files = {
  'setup-local': '../database/setup-local.sql',
  schema: '../database/schema.sql',
  seed: '../database/seed.sql',
};

async function rootPassword() {
  if (process.env.DB_ROOT_PASSWORD) return process.env.DB_ROOT_PASSWORD;
  const input = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  return new Promise((resolve) => {
    input.question('Contraseña root de MySQL local: ', (answer) => {
      input.close();
      resolve(answer);
    });
  });
}

async function main() {
  if (!files[type]) throw new Error('Uso: npm run db:setup | db:schema | db:seed');
  const sqlPath = path.resolve(__dirname, files[type]);
  let sql = fs.readFileSync(sqlPath, 'utf8');

  if (type === 'setup-local') {
    const password = process.env.DB_PASSWORD;
    if (!password) throw new Error('Falta DB_PASSWORD en .env.');
    sql = sql.replaceAll('REEMPLAZAR_CON_DB_PASSWORD', password);
  }

  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || '127.0.0.1',
    port: Number(process.env.DB_PORT || 3306),
    user: type === 'setup-local' ? 'root' : (process.env.DB_USER || 'anne_nail_app'),
    password: type === 'setup-local'
      ? await rootPassword()
      : (process.env.DB_PASSWORD || ''),
    multipleStatements: true,
  });

  await connection.query(sql);
  await connection.end();
  console.log(`Ejecutado ${path.basename(sqlPath)}.`);
}

main().catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
