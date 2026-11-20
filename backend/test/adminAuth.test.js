const test = require('node:test');
const assert = require('node:assert/strict');

process.env.JWT_SECRET = 'test-admin-secret';
process.env.ADMIN_USER = 'admin';

const {
  createAdminToken,
  requireAdmin,
} = require('../src/admin/auth');

test('requireAdmin rejects a request without a session cookie', () => {
  const response = {
    statusCode: 200,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(body) {
      this.body = body;
      return this;
    },
  };
  let called = false;
  requireAdmin({ cookies: {} }, response, () => {
    called = true;
  });
  assert.equal(called, false);
  assert.equal(response.statusCode, 401);
});

test('requireAdmin accepts a valid admin token', () => {
  const token = createAdminToken();
  let called = false;
  const response = {
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(body) {
      this.body = body;
    },
  };
  requireAdmin({ cookies: { admin_session: token } }, response, () => {
    called = true;
  });
  assert.equal(called, true);
});
