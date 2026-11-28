# Anne Nail Studio

Aplicacion Flutter, API Node.js, MySQL local y Google Calendar.

## Requisitos

- Windows 10/11.
- Node.js 20 o posterior.
- MySQL 8.x en `127.0.0.1:3306`.
- Flutter SDK.
- Cuenta de Google Calendar y cuenta de servicio con permiso sobre el calendario.

## Base de datos

Los scripts usan el `DB_NAME` del `.env` (por defecto `anne_nail_studio`): crean
esa base si no existe, la seleccionan y aplican el SQL. El nombre de la base no
esta fijo en los archivos `.sql`. Si tu base ya existe con otro nombre, cambia
solo `DB_NAME` en el `.env`.

El `.env` se lee desde la raiz del repo (tambien se acepta `backend/.env`); al
arrancar, la API imprime de cual lo leyo. Para comprobar la conexion sin
levantar el servidor:

```powershell
npm run db:check
```

`db:check` muestra usuario, host, puerto y base, y si falla imprime el codigo
de error de MySQL con la causa (servidor apagado, credenciales, base o tablas
faltantes).

<<<<<<< HEAD
Para crear el usuario de la app y aplicar el esquema y datos iniciales:
=======
Para crear el usuario de la app y aplicar el esquema:
>>>>>>> origin/main

```powershell
npm run db:setup
npm run db:schema
npm run db:seed
```

`db:setup` crea `anne_nail_app` con el `DB_PASSWORD` del `.env` y le da solo
SELECT, INSERT, UPDATE y DELETE sobre la base. Los tres comandos piden la
contraseña de root de MySQL en la terminal y no la guardan. Si no quieres
escribirla cada vez, define `DB_ROOT_PASSWORD` en el `.env`.

<<<<<<< HEAD
`db:schema` aplica `backend/database/schema.sql`. En una base existente agrega
de forma segura solo las columnas `categoria`, `grupo`, `descripcion` y `orden`
a `servicios` si faltan; no elimina tablas ni filas. El comando requiere la
contraseña root local.

`db:seed` agrega servicios de ejemplo sin duplicarlos y asigna categoría,
grupo, descripción y orden a los servicios existentes. Los valores nuevos son
referenciales y se pueden editar desde el panel.
=======
`db:schema` aplica también `backend/database/ensure.sql`, que solo ajusta el
estado de las citas, así que puedes repetirlo sobre una base con datos cuando
el proyecto agregue un estado nuevo.

Para actualizar una base que ya tiene datos, sin borrarlos:

```powershell
npm run db:upgrade
```

`db:upgrade` agrega los indices y restricciones de `upgrade.sql` a las tablas
existentes. Se ejecuta una sola vez por base.
>>>>>>> origin/main

Si la base tiene tablas viejas (por ejemplo `citas` con `fecha_hora` en lugar de
`fecha` y `hora`) y no hay datos que conservar, se puede recrear vacia:

```powershell
npm run db:reset
```

<<<<<<< HEAD
`db:reset` es destructivo: borra y recrea la base completa. No lo uses para
actualizar un proyecto que ya tenga datos.
=======
`db:reset` borra la base, la crea de nuevo y aplica `schema.sql` y `seed.sql`.
Pide escribir el nombre de la base para confirmar.
>>>>>>> origin/main

Archivos fuente:

- `backend/database/setup-local.sql`
- `backend/database/schema.sql`
<<<<<<< HEAD
=======
- `backend/database/upgrade.sql`
>>>>>>> origin/main
- `backend/database/seed.sql`
- `backend/database/backups/`

`backend/database/backups/` esta ignorada por Git.

## Variables de entorno

```dotenv
DB_HOST=127.0.0.1
DB_PORT=3306
DB_NAME=anne_nail_studio
DB_USER=anne_nail_app
DB_PASSWORD=generada-por-env-init
JWT_SECRET=generado-por-env-init

# Opcional: sin calendario ni credenciales la agenda se controla solo con MySQL.
GOOGLE_CALENDAR_ID=tu-calendario@group.calendar.google.com
GOOGLE_APPLICATION_CREDENTIALS=./backend/.credentials/service-account.json
GOOGLE_OAUTH_CLIENT_ID=tu-client-id-web.apps.googleusercontent.com

TIMEZONE=America/Mexico_City
<<<<<<< HEAD
BUSINESS_OPEN_HOUR=9
BUSINESS_CLOSE_HOUR=18
BUSINESS_CLOSE_MINUTE=0
BUSINESS_DAYS=1,2,3,4,5,6
SLOT_INTERVAL_MINUTES=120
=======
BUSINESS_OPEN_HOUR=10
BUSINESS_CLOSE_HOUR=19
BUSINESS_CLOSE_MINUTE=30
BUSINESS_DAYS=1,2,3,4,5,6
SLOT_INTERVAL_MINUTES=30
>>>>>>> origin/main

ADMIN_USER=anneadmin
ADMIN_PASSWORD_HASH=
```

Crea el `.env` en la raiz del repo con `env:init`: copia `.env.example`, genera
`JWT_SECRET` (64 caracteres hexadecimales) y `DB_PASSWORD` (aleatoria), y si ya
existe un `.env` conserva sus valores y solo agrega los que falten.

```powershell
npm run env:init
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
| GET | `/api/health` | Ninguna | Estado de API y MySQL | 200,503 |
<<<<<<< HEAD
| GET | `/api/servicios?categoria=manicura` o `pedicura` | Categoría | Servicios activos ordenados por grupo y orden | 200,400,500 |
=======
>>>>>>> origin/main
| GET | `/api/availability` | `date`, `serviceId` | Horarios por mañana y tarde | 200,400,404,502 |
| POST | `/api/appointments` | `servicio_id`, `fecha`, `hora`, `telefono?` con Bearer JWT | Cita pendiente | 201,400,401,404,409,502,500 |
| GET | `/api/appointments/mine` | Bearer JWT | Citas propias | 200,401,500 |
| POST | `/api/admin/login` | `{user, password}` | Cookie JWT | 200,400,401 |
| GET/POST/PUT/DELETE | `/api/admin/*` | Datos administrativos | CRUD y confirmacion | 401,400,404,409,500 |
| POST | `/api/admin/appointments/:id/reject` | Cookie admin | Rechaza una cita `pendiente` | 200,401,404,409 |
| POST | `/api/admin/appointments/:id/cancel` | Cookie admin | Cancela una cita `pendiente` o `agendada` | 200,401,404,409 |
| GET | `/admin/` | Ninguna | Panel HTML | 200 |

## Formato de fechas y horas

La API responde siempre `fecha` como `YYYY-MM-DD` y `hora` / `hora_fin` como
`HH:MM`, sin segundos ni zona horaria, en `POST /api/appointments`,
`GET /api/appointments/mine` y `/api/admin/appointments`.

La conexion usa `dateStrings: ['DATE']`, de modo que MySQL entrega la fecha como
texto y no la convierte a UTC: una cita del 24 a las 10:00 no cambia de dia por
la zona horaria del estudio (`America/Mexico_City`).

La app arma el `DateTime` con `parseStudioDateTime` (`lib/utils/date_time.dart`),
que tolera `2026-11-24`, `2026-11-24T00:00:00.000Z`, `10:00` y `10:00:00`.

## Pruebas

```powershell
cd backend
npm test
cd ..
flutter analyze
```

Pruebas manuales recomendadas:

<<<<<<< HEAD
1. Abrir la app y elegir Manicura o Pedicura en Inicio o en Servicios.
2. Elegir un servicio y tocar **RESERVAR**.
3. Crear una cuenta nueva o iniciar sesión.
4. Seleccionar fecha y horario, y confirmar la reserva.
5. Verificar que la cita aparece en Mis citas y con estado `pendiente`.
6. Confirmar desde `/admin/` y comprobar servicio, correo y teléfono.
7. Verificar estado `agendada` y `manicurista_id` en MySQL.
8. Rechazar otra cita pendiente o cancelar la agendada desde `/admin/` y
   verificar que el horario vuelve a aparecer en `/api/availability`.
9. Verificar el evento en Google Calendar.
=======
1. Crear una cuenta nueva.
2. Iniciar sesion y guardar el JWT.
3. Reservar un servicio activo.
4. Verificar que se crea con estado `pendiente`.
5. Confirmar desde `/admin/`.
6. Verificar estado `agendada` y `manicurista_id` en MySQL.
7. Rechazar otra cita pendiente o cancelar la agendada desde `/admin/` y
   verificar que el horario vuelve a aparecer en `/api/availability`.
8. Verificar el evento en Google Calendar.
>>>>>>> origin/main

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
