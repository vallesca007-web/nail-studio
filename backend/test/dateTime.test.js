const test = require('node:test');
const assert = require('node:assert/strict');

const {
  dateInTimeZone,
  formatLocalDateTime,
  localDateTimeToDate,
  localDayRange,
  parseDate,
} = require('../src/services/dateTime');

test('formats local dates and times consistently', () => {
  const instant = new Date('2026-01-15T16:07:45.000Z');
  assert.equal(dateInTimeZone(instant, 'America/Mexico_City'), '2026-01-15');
  assert.equal(
    formatLocalDateTime(instant, 'America/Mexico_City'),
    '2026-01-15T10:07:00',
  );
});

test('converts the studio wall time to the correct instant', () => {
  assert.equal(
    localDateTimeToDate(
      '2026-01-15',
      '10:00',
      'America/Mexico_City',
    ).toISOString(),
    '2026-01-15T16:00:00.000Z',
  );
});

test('uses timezone-aware day boundaries across daylight-saving changes', () => {
  const springDay = localDayRange('2026-03-08', 'America/Los_Angeles');
  const fallDay = localDayRange('2026-11-01', 'America/Los_Angeles');
  assert.equal((springDay.end - springDay.start) / 3_600_000, 23);
  assert.equal((fallDay.end - fallDay.start) / 3_600_000, 25);
});

test('rejects invalid dates and nonexistent daylight-saving times', () => {
  assert.equal(parseDate('2026-02-30'), null);
  assert.equal(
    localDateTimeToDate(
      '2026-03-08',
      '02:30',
      'America/Los_Angeles',
    ),
    null,
  );
});
