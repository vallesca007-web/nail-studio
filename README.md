# Anne Nail Studio

Aplicacion Flutter, API Node.js, MySQL local y Google Calendar.

## Requisitos

- Windows 10/11.
- Node.js 20 o posterior.
- MySQL 8.x en `127.0.0.1:3306`.
- Flutter SDK.
- Cuenta de Google Calendar y cuenta de servicio con permiso sobre el calendario.

## Base de datos

Los scripts usan el `DB_NAME` del `.env` (por defecto `AnneNail`): crean esa
base si no existe, la seleccionan y aplican el SQL. El nombre de la base no
esta fijo en los archivos `.sql`.

Si tu MySQL ya tiene la base `AnneNail`, solo faltan las tablas. Desde
`backend/`:

```powershell
npm run db:schema
npm run db:seed
```

Si prefieres un usuario propio en lugar de `root`:

```powershell
npm run db:setup
npm run db:schema
npm run db:seed
```

`db:setup` solicita la contraseña root y crea `anne_nail_app` con `DB_PASSWORD`.

Para actualizar una base que ya tiene datos, sin borrarlos:

```powershell
npm run db:upgrade
```

`db:upgrade` agrega los indices y restricciones de `upgrade.sql` a las tablas
existentes. Se ejecuta una sola vez por base.

Si la base `AnneNail` tiene tablas viejas (por ejemplo `citas` con `fecha_hora`
en lugar de `fecha` y `hora`) y no hay datos que conservar, se puede recrear
vacia:

```powershell
npm run db:reset
```

`db:reset` borra la base, la crea de nuevo y aplica `schema.sql` y `seed.sql`.
Pide escribir el nombre de la base para confirmar.

Archivos fuente:

- `backend/database/setup-local.sql`
- `backend/database/schema.sql`
- `backend/database/upgrade.sql`
- `backend/database/seed.sql`
- `backend/database/backups/`

`backend/database/backups/` esta ignorada por Git.

## Variables de entorno

```dotenv
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=AnneNail
DB_USER=root
DB_PASSWORD=contrasena-root-de-tu-mysql
JWT_SECRET=cambia-este-secreto

GOOGLE_CALENDAR_ID=tu-calendario@group.calendar.google.com
GOOGLE_APPLICATION_CREDENTIALS=./backend/.credentials/service-account.json
GOOGLE_OAUTH_CLIENT_ID=tu-client-id-web.apps.googleusercontent.com

TIMEZONE=America/Mexico_City
BUSINESS_OPEN_HOUR=10
BUSINESS_CLOSE_HOUR=19
BUSINESS_CLOSE_MINUTE=30
BUSINESS_DAYS=1,2,3,4,5,6
SLOT_INTERVAL_MINUTES=30

ADMIN_USER=anneadmin
ADMIN_PASSWORD_HASH=
```

Copia `.env.example` a `.env` y reemplaza todos los marcadores:

```powershell
Copy-Item .env.example .env
notepad .env
```

## Ejecutar

Backend:

```powershell
cd backend
npm install
npm start
```

Puerto:

```text
http://localhost:3000
```

Panel administrativo:

```text
http://localhost:3000/admin/
```

Desarrollo del backend:

```powershell
npm run dev
```

Flutter:

```powershell
flutter pub get
flutter devices
flutter run -d emulator-5554
```

Android Emulator usa `http://10.0.2.2:3000/api`.
Flutter Web usa `http://localhost:3000/api`.

## Endpoints

| Metodo | URL | Entrada | Respuesta | Codigos |
|---|---|---|---|---|
| POST | `/api/auth/register` | `{correo, contrasena}` | Usuario creado | 201,400,409,500 |
| POST | `/api/auth/login` | `{correo, contrasena}` | `{token, correo, id}` | 200,400,401,500 |
| GET | `/api/health` | Ninguna | Estado de API y MySQL | 200,500 |
| GET | `/api/availability` | `date`, `serviceId` | Horarios por mañana y tarde | 200,400,404,502 |
| POST | `/api/appointments` | `servicio_id`, `fecha`, `hora`, `telefono?` con Bearer JWT | Cita pendiente | 201,400,401,404,409,502,500 |
| GET | `/api/appointments/mine` | Bearer JWT | Citas propias | 200,401,500 |
| POST | `/api/admin/login` | `{user, password}` | Cookie JWT | 200,400,401 |
| GET/POST/PUT/DELETE | `/api/admin/*` | Datos administrativos | CRUD y confirmacion | 401,400,404,409,500 |
| GET | `/admin/` | Ninguna | Panel HTML | 200 |

## Pruebas

```powershell
cd backend
npm test
cd ..
flutter analyze
```

Pruebas manuales recomendadas:

1. Crear una cuenta nueva.
2. Iniciar sesion y guardar el JWT.
3. Reservar un servicio activo.
4. Verificar que se crea con estado `pendiente`.
5. Confirmar desde `/admin/`.
6. Verificar estado `agendada` y `manicurista_id` en MySQL.
7. Verificar el evento en Google Calendar.

## Problema: "No pudimos conectar con el servidor"

Ese mensaje aparece cuando la app no alcanza la API, no cuando MySQL falla.
Comprueba en este orden:

1. La API debe estar corriendo (`npm start` en `backend/`) y responder en
   <http://localhost:3000/api/health>.
2. Emulador Android: usa `http://10.0.2.2:3000/api`, que es el valor por defecto.
3. Teléfono físico: la computadora y el teléfono deben estar en la misma red y
   la app debe apuntar a la IP local:

   ```powershell
   flutter run --dart-define=API_BASE_URL=http://192.168.1.50:3000/api
   ```

4. Flutter Web: la API ya permite peticiones desde `localhost` en cualquier
   puerto (`backend/src/server.js`).
5. Firewall de Windows: permite Node.js en la red privada.

## Seguridad

- No subas `.env`.
- No subas `backend/.credentials/`.
- No subas `backend/database/backups/`.
- No pongas contrasenas ni client secrets en el codigo.
- Rota secretos que hayan sido compartidos.
