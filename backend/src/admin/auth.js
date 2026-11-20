const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const cookieName = 'admin_session';

function loginPasswordMatches(password) {
  const hash = process.env.ADMIN_PASSWORD_HASH || '';
  return hash ? bcrypt.compare(password, hash) : Promise.resolve(false);
}

function createAdminToken() {
  if (!process.env.JWT_SECRET) throw new Error('Falta configurar JWT_SECRET.');
  return jwt.sign(
    { role: 'admin', user: process.env.ADMIN_USER || 'admin' },
    process.env.JWT_SECRET,
    { expiresIn: '8h' },
  );
}

function requireAdmin(request, response, next) {
  const token = request.cookies?.[cookieName];
  if (!token) return response.status(401).json({ error: 'Inicia sesión como administradora.' });
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    if (payload.role !== 'admin') throw new Error('Invalid role');
    request.admin = payload;
    return next();
  } catch {
    return response.status(401).json({ error: 'Tu sesión venció. Inicia sesión nuevamente.' });
  }
}

module.exports = {
  cookieName,
  createAdminToken,
  loginPasswordMatches,
  requireAdmin,
};
