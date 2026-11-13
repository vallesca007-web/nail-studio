# Anne Nail Studio

Aplicación Flutter para Anne Nail Studio. Las citas se guardan en MySQL a través de una API Node.js; la app nunca se conecta directamente a MySQL.

## Iniciar la API y MySQL

1. Crea la base de datos ejecutando `backend/schema.sql` en MySQL.
2. Copia `backend/.env.example` a `backend/.env` y configura las credenciales de MySQL.
3. En `backend/`, instala dependencias y ejecuta la API:

   ```sh
   npm install
   npm start
   ```

4. Comprueba `http://localhost:3000/api/health`; debe responder `{"status":"ok","database":"connected"}`.

## Conectar Flutter

La URL por defecto de Flutter es `http://localhost:3000/api`, útil para Flutter Web en la misma computadora. Para Android Emulator, usa la dirección especial `10.0.2.2`:

```sh
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

En un dispositivo físico, reemplaza `10.0.2.2` por la IP local de la computadora que ejecuta la API. Para producción, configura una URL HTTPS y añade autenticación/autorización para proteger los datos de las clientas.
