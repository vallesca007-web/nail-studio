const mysql = require('mysql2/promise');

const { loadEnvironment } = require('../src/config/env');

loadEnvironment();

const settings = {
  host: process.env.DB_HOST || '127.0.0.1',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'anne_nail_studio',
};

const hints = {
  ECONNREFUSED: 'MySQL no acepta conexiones en ese host y puerto. Revisa que el servicio este iniciado y que DB_PORT sea el correcto (normalmente 3306).',
  ETIMEDOUT: 'La conexion no respondio. Revisa firewall y que DB_HOST sea la maquina correcta.',
  ER_ACCESS_DENIED_ERROR: 'Usuario o contrasena rechazados por MySQL. DB_PASSWORD debe ser la contrasena real de DB_USER.',
  ER_BAD_DB_ERROR: 'La base no existe. Ejecuta: npm run db:schema',
  ER_NO_SUCH_TABLE: 'Faltan tablas en la base. Ejecuta: npm run db:schema',
  ER_NOT_SUPPORTED_AUTH_MODE: 'MySQL usa un metodo de autenticacion que este cliente no soporta; cambia el usuario a mysql_native_password.',
};

async function main() {
  console.log(
    `Probando ${settings.user}@${settings.host}:${settings.port}/${settings.database} ` +
      `(contrasena ${settings.password ? 'definida' : 'vacia'})`,
  );

  let connection;
  try {
    connection = await mysql.createConnection(settings);
    const [tables] = await connection.query('SHOW TABLES');
    const [rows] = await connection.query('SELECT COUNT(*) AS total FROM servicios');
    console.log(`Conexion correcta: ${tables.length} tablas, ${rows[0].total} servicios.`);
  } catch (error) {
    console.error(`Fallo la conexion: ${error.code || error.message}`);
    if (hints[error.code]) console.error(hints[error.code]);
    process.exitCode = 1;
  } finally {
    if (connection) await connection.end();
  }
}

main();
