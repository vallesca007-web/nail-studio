const fs = require('node:fs');
const path = require('node:path');
const { google } = require('googleapis');

const { localDayRange } = require('./dateTime');

const scopes = [
  'https://www.googleapis.com/auth/calendar.events',
  'https://www.googleapis.com/auth/calendar.freebusy',
];
let calendarApi;

function resolveLocalCredentialPath(file) {
  if (path.isAbsolute(file)) return file;
  if (file.startsWith('./backend/') || file.startsWith('backend/')) {
    return path.resolve(__dirname, '../../..', file);
  }
  return path.resolve(process.cwd(), file);
}

function configuredCalendarId() {
  const calendarId = process.env.GOOGLE_CALENDAR_ID?.trim();
  if (!calendarId) throw new Error('Falta configurar GOOGLE_CALENDAR_ID.');
  return calendarId;
}

function getCalendarApi() {
  if (calendarApi) return calendarApi;
  const json = process.env.GOOGLE_SERVICE_ACCOUNT_JSON;
  const file = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  let auth;

  if (json) {
    let credentials;
    try {
      credentials = JSON.parse(json);
    } catch {
      throw new Error('GOOGLE_SERVICE_ACCOUNT_JSON no contiene JSON válido.');
    }
    auth = new google.auth.GoogleAuth({ credentials, scopes });
  } else if (file) {
    const credentialPath = resolveLocalCredentialPath(file);
    if (!fs.existsSync(credentialPath)) {
      throw new Error('No se encontró el archivo GOOGLE_APPLICATION_CREDENTIALS.');
    }
    auth = new google.auth.GoogleAuth({ keyFile: credentialPath, scopes });
  } else {
    throw new Error(
      'Configura GOOGLE_SERVICE_ACCOUNT_JSON o GOOGLE_APPLICATION_CREDENTIALS.',
    );
  }

  calendarApi = google.calendar({ version: 'v3', auth });
  return calendarApi;
}

async function getBusyRanges(date) {
  const timeZone = process.env.TIMEZONE || 'America/Mexico_City';
  const range = localDayRange(date, timeZone);
  if (!range) throw new Error('La fecha o la zona horaria no son válidas.');

  const response = await getCalendarApi().freebusy.query({
    requestBody: {
      timeMin: range.start.toISOString(),
      timeMax: range.end.toISOString(),
      timeZone,
      items: [{ id: configuredCalendarId() }],
    },
  });
  const calendar = response.data.calendars?.[configuredCalendarId()];
  if (calendar?.errors?.length) {
    throw new Error('Google Calendar no permitió consultar la agenda.');
  }
  return calendar?.busy || [];
}

async function createEvent({
  serviceName,
  customerName,
  customerEmail,
  customerPhone,
  start,
  end,
}) {
  const timeZone = process.env.TIMEZONE || 'America/Mexico_City';
  const response = await getCalendarApi().events.insert({
    calendarId: configuredCalendarId(),
    requestBody: {
      summary: `${serviceName} - ${customerName}`,
      description: [
        `Clienta: ${customerName}`,
        `Correo: ${customerEmail}`,
        `Teléfono: ${customerPhone || 'No proporcionado'}`,
        `Servicio: ${serviceName}`,
      ].join('\n'),
      start: { dateTime: start.toISOString(), timeZone },
      end: { dateTime: end.toISOString(), timeZone },
    },
  });
  if (!response.data.id) {
    throw new Error('Google Calendar no devolvió el identificador de la cita.');
  }
  return { eventId: response.data.id, eventUrl: response.data.htmlLink || null };
}

async function deleteEvent(eventId) {
  await getCalendarApi().events.delete({
    calendarId: configuredCalendarId(),
    eventId,
    sendUpdates: 'all',
  });
}

async function updateEventTitle(eventId, title) {
  await getCalendarApi().events.patch({
    calendarId: configuredCalendarId(),
    eventId,
    requestBody: { summary: title },
  });
}

module.exports = {
  createEvent,
  deleteEvent,
  getBusyRanges,
  updateEventTitle,
};
