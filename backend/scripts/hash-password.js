const readline = require('node:readline');
const bcrypt = require('bcryptjs');

const password = process.argv.slice(2).join(' ');

async function generate(value) {
  if (!value) {
    const input = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });
    value = await new Promise((resolve) => {
      input.question('Nueva contraseña de administrador: ', (answer) => {
        input.close();
        resolve(answer);
      });
    });
  }
  if (!value) throw new Error('La contraseña no puede estar vacía.');
  console.log(await bcrypt.hash(value, 12));
}

generate(password).catch((error) => {
  console.error(error.message);
  process.exitCode = 1;
});
