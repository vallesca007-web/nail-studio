const formatters = new Map();

function parseDate(date) {
  if (typeof date !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return null;
  }
  const [year, month, day] = date.split('-').map(Number);
  const parsed = new Date(Date.UTC(year, month - 1, day));
  if (
    parsed.getUTCFullYear() !== year ||
    parsed.getUTCMonth() !== month - 1 ||
    parsed.getUTCDate() !== day
  ) {
    return null;
  }
  return { year, month, day };
}

function formatter(timeZone) {
  if (!formatters.has(timeZone)) {
    formatters.set(
      timeZone,
      new Intl.DateTimeFormat('en-CA', {
        timeZone,
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hourCycle: 'h23',
      }),
    );
  }
  return formatters.get(timeZone);
}

function partsAt(date, format) {
  return Object.fromEntries(
    format
      .formatToParts(date)
      .filter((part) => part.type !== 'literal')
      .map((part) => [part.type, Number(part.value)]),
  );
}

function localDateTimeToDate(date, time, timeZone) {
  const calendarDate = parseDate(date);
  const match =
    typeof time === 'string' && /^([01]\d|2[0-3]):([0-5]\d)$/.exec(time);
  if (!calendarDate || !match) return null;

  const hour = Number(match[1]);
  const minute = Number(match[2]);
  const target = Date.UTC(
    calendarDate.year,
    calendarDate.month - 1,
    calendarDate.day,
    hour,
    minute,
  );
  const format = formatter(timeZone);
  let timestamp = target;

  for (let attempt = 0; attempt < 4; attempt += 1) {
    const parts = partsAt(new Date(timestamp), format);
    const represented = Date.UTC(
      parts.year,
      parts.month - 1,
      parts.day,
      parts.hour,
      parts.minute,
      parts.second,
    );
    const difference = target - represented;
    timestamp += difference;
    if (difference === 0) return new Date(timestamp);
  }

  return null;
}

function localDayRange(date, timeZone) {
  const day = parseDate(date);
  if (!day) return null;
  const nextDay = new Date(Date.UTC(day.year, day.month - 1, day.day + 1));
  const nextDate = [
    nextDay.getUTCFullYear(),
    String(nextDay.getUTCMonth() + 1).padStart(2, '0'),
    String(nextDay.getUTCDate()).padStart(2, '0'),
  ].join('-');
  const start = localDateTimeToDate(date, '00:00', timeZone);
  const end = localDateTimeToDate(nextDate, '00:00', timeZone);
  return start && end ? { start, end } : null;
}

function formatDate(parts) {
  return `${parts.year}-${String(parts.month).padStart(2, '0')}-${String(
    parts.day,
  ).padStart(2, '0')}`;
}

function formatLocalDateTime(date, timeZone) {
  const parts = partsAt(date, formatter(timeZone));
  return `${formatDate(parts)}T${String(parts.hour).padStart(
    2,
    '0',
  )}:${String(parts.minute).padStart(2, '0')}:00`;
}

function dateInTimeZone(date, timeZone) {
  return formatDate(partsAt(date, formatter(timeZone)));
}

function weekday(date) {
  const parsed = parseDate(date);
  if (!parsed) return null;
  const day = new Date(
    Date.UTC(parsed.year, parsed.month - 1, parsed.day),
  ).getUTCDay();
  return day === 0 ? 7 : day;
}

// mysql2 devuelve las columnas DATE como Date o como texto segun la conexion.
// La API responde siempre "YYYY-MM-DD" y "HH:MM" para que la app no tenga que
// interpretar zonas horarias.
function dateText(value) {
  if (typeof value === 'string') return value.slice(0, 10);
  if (value instanceof Date) return value.toISOString().slice(0, 10);
  return '';
}

function timeText(value) {
  return typeof value === 'string' ? value.slice(0, 5) : '';
}

module.exports = {
  dateInTimeZone,
  dateText,
  timeText,
  formatLocalDateTime,
  localDateTimeToDate,
  localDayRange,
  parseDate,
  weekday,
};
