# Anne Nail Studio

Aplicación Flutter con una API Node.js, MySQL y reservas en Google Calendar. Flutter se comunica con la API; las credenciales de MySQL y Google permanecen en el backend.

## Requisitos

- Windows con PowerShell.
- Docker Desktop con Docker Compose.
- Flutter y un emulador Android o Google Chrome.
- Un proyecto de Google Cloud con Google Calendar API habilitada.

## 1. Configurar el entorno local

Desde PowerShell, abre la carpeta raíz del proyecto. Copia el ejemplo solo si aún no tienes un `.env`, para no sobrescribir tu configuración:

```powershell
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
notepad .env
```

En `.env`:

- Cambia `MYSQL_ROOT_PASSWORD` y `DB_PASSWORD` por contraseñas distintas.
- Reemplaza `GOOGLE_CALENDAR_ID` por el ID del calendario del estudio.
- Configura `GOOGLE_OAUTH_CLIENT_ID` con el OAuth Client ID de tipo **Aplicación web**.
- Ajusta `TIMEZONE` y el horario si hace falta.

Para la cuenta de servicio, crea la carpeta e instala allí el JSON descargado:

```powershell
New-Item -ItemType Directory -Force backend\.credentials
```

Guarda el archivo como `backend\.credentials\service-account.json`. Deja `GOOGLE_SERVICE_ACCOUNT_JSON` vacío y conserva `GOOGLE_CREDENTIALS_DIR` y `GOOGLE_APPLICATION_CREDENTIALS` con sus valores de ejemplo. Comparte el calendario con el `client_email` del JSON y permite modificar eventos. No subas el JSON ni `.env` a Git.

Configura en `lib/config/app_config.dart` los OAuth Client IDs requeridos por Flutter. `googleServerClientId` debe coincidir con `GOOGLE_OAUTH_CLIENT_ID` del `.env`.

## 2. Iniciar MySQL y la API

Con Docker Desktop abierto, desde la raíz:

```powershell
docker compose up --build -d
docker compose ps
Invoke-RestMethod http://localhost:3000/api/health
```

En una base nueva, Compose crea `anne_nail_studio`, carga `backend/schema.sql` y levanta la API en el puerto `3000`. El health check debe responder con `status: ok` y `database: connected`.

Los scripts de `docker-entrypoint-initdb.d` solo se ejecutan cuando MySQL inicializa un volumen vacío. Para detener los servicios sin borrar los datos:

```powershell
docker compose down
```

No uses `docker compose down -v` si quieres conservar las citas.

## 3. Ejecutar Flutter

En otra terminal, desde la raíz:

```powershell
flutter pub get
flutter devices
flutter run
```

Inicia primero un emulador Android si eliges ese dispositivo. La app usa `http://10.0.2.2:3000/api` por defecto en Android y `http://localhost:3000/api` en Flutter Web. Para Web:

```powershell
flutter run -d chrome
```

En un teléfono físico, usa la IP local de la computadora que ejecuta Docker:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000/api
```

Reemplaza `192.168.1.20` por la IP real de tu computadora.

## Google Calendar y base existente

Para reservar, también deben estar configurados el OAuth Client ID, la cuenta de servicio y el Calendar ID; los valores de `.env.example` son marcadores, no credenciales funcionales. Puedes revisar los logs de la API con `docker compose logs -f api`.

El Compose de este proyecto crea su propia base compatible llamada `anne_nail_studio`. No usa automáticamente una base existente llamada `nail_studio` con tablas `usuarios`, `servicios` y `citas`. No ejecutes `backend/migrations/001_booking.sql` sobre esa estructura: esa migración corresponde a la versión anterior del esquema del proyecto. Para usar tu base existente habría que adaptar el backend a sus tablas.
