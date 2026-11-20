const express = require('express');
const crypto = require('node:crypto');

const googleCalendar = require('../services/googleCalendar');
const {
  cookieName,
  createAdminToken,
  loginPasswordMatches,
  requireAdmin,
} = require('./auth');
const { adjustPrice } = require('./price');

module.exports = function createAdminRoutes(pool) {
  const router = express.Router();

  router.post('/login', async (request, response) => {
    const user = typeof request.body?.user === 'string'
      ? request.body.user.trim()
      : '';
    const password = typeof request.body?.password === 'string'
      ? request.body.password
      : '';
    if (!user || !password) {
      return response.status(400).json({ error: 'Indica usuario y contraseña.' });
    }
    if (user !== (process.env.ADMIN_USER || '')) {
      await new Promise((resolve) => setTimeout(resolve, 250));
      return response.status(401).json({ error: 'Usuario o contraseña incorrectos.' });
    }
    const valid = await loginPasswordMatches(password);
    if (!valid) {
      return response.status(401).json({ error: 'Usuario o contraseña incorrectos.' });
    }
    response.cookie(cookieName, createAdminToken(), {
      httpOnly: true,
      sameSite: 'strict',
      secure: process.env.NODE_ENV === 'production' && process.env.COOKIE_SECURE === 'true',
      maxAge: 8 * 60 * 60 * 1000,
    });
    return response.json({ ok: true, user });
  });

  router.post('/logout', requireAdmin, (request, response) => {
    response.clearCookie(cookieName, { httpOnly: true, sameSite: 'strict' });
    response.json({ ok: true });
  });

  router.get('/me', requireAdmin, (request, response) => {
    response.json({ ok: true, user: request.admin.user });
  });

  router.get('/specialists', requireAdmin, async (request, response, next) => {
    try {
      const [rows] = await pool.execute(
        'SELECT specialist_id, name, specialty, photo_url, active, created_at FROM specialists WHERE active = TRUE ORDER BY name',
      );
      response.json(rows);
    } catch (error) {
      next(error);
    }
  });

  router.post('/specialists', requireAdmin, async (request, response, next) => {
    try {
      const name = String(request.body?.name || '').trim();
      const specialty = String(request.body?.specialty || '').trim();
      const photoUrl = String(request.body?.photoUrl || '').trim();
      if (!name || name.length > 160) {
        return response.status(400).json({ error: 'Indica un nombre válido.' });
      }
      if (specialty.length > 160) {
        return response.status(400).json({ error: 'La especialidad es demasiado larga.' });
      }
      if (photoUrl.length > 1024) {
        return response.status(400).json({ error: 'La URL de foto es demasiado larga.' });
      }
      const specialistId = crypto.randomUUID();
      await pool.execute(
        'INSERT INTO specialists (specialist_id, name, specialty, photo_url, active) VALUES (?, ?, ?, ?, TRUE)',
        [specialistId, name, specialty, photoUrl || null],
      );
      response.status(201).json({ specialistId, name, specialty, photoUrl: photoUrl || null, active: true });
    } catch (error) {
      next(error);
    }
  });

  router.delete('/specialists/:id', requireAdmin, async (request, response, next) => {
    try {
      const [appointments] = await pool.execute(
        'SELECT specialist_id FROM appointments WHERE specialist_id = ? LIMIT 1',
        [request.params.id],
      );
      if (appointments.length) {
        await pool.execute('UPDATE specialists SET active = FALSE WHERE specialist_id = ?', [request.params.id]);
        return response.json({ ok: true, deleted: false, reason: 'Desactivada por tener citas asociadas.' });
      }
      await pool.execute('DELETE FROM specialists WHERE specialist_id = ?', [request.params.id]);
      response.json({ ok: true, deleted: true });
    } catch (error) {
      next(error);
    }
  });

  router.get('/services', requireAdmin, async (request, response, next) => {
    try {
      const [rows] = await pool.execute(
        'SELECT service_id, name, description, duration_minutes, price, category, active FROM services ORDER BY name',
      );
      response.json(rows);
    } catch (error) {
      next(error);
    }
  });

  router.post('/services', requireAdmin, async (request, response, next) => {
    try {
      const name = String(request.body?.name || '').trim();
      const description = String(request.body?.description || '').trim();
      const category = String(request.body?.category || 'General').trim();
      const duration = Number(request.body?.durationMinutes);
      const price = Number(request.body?.price);
      if (!name || name.length > 160 || !Number.isInteger(duration) || duration <= 0 || duration > 1440) {
        return response.status(400).json({ error: 'Los datos del servicio no son válidos.' });
      }
      if (!Number.isFinite(price) || price <= 0) {
        return response.status(400).json({ error: 'El precio debe ser mayor que cero.' });
      }
      const serviceId = `service-${crypto.randomUUID()}`;
      await pool.execute(
        'INSERT INTO services (service_id, name, description, duration_minutes, price, category, active) VALUES (?, ?, ?, ?, ?, ?, TRUE)',
        [serviceId, name, description, duration, price, category || 'General'],
      );
      response.status(201).json({ serviceId, name, description, durationMinutes: duration, price, category: category || 'General', active: true });
    } catch (error) {
      next(error);
    }
  });

  router.put('/services/:id', requireAdmin, async (request, response, next) => {
    try {
      const price = request.body?.price === undefined ? undefined : Number(request.body.price);
      if (price !== undefined && (!Number.isFinite(price) || price <= 0)) {
        return response.status(400).json({ error: 'El precio debe ser mayor que cero.' });
      }
      await pool.execute(
        `UPDATE services
         SET name = COALESCE(?, name),
             description = COALESCE(?, description),
             duration_minutes = COALESCE(?, duration_minutes),
             price = COALESCE(?, price),
             category = COALESCE(?, category),
             active = COALESCE(?, active)
         WHERE service_id = ?`,
        [
          request.body?.name?.trim() || null,
          request.body?.description?.trim() || null,
          request.body?.durationMinutes ?? null,
          price ?? null,
          request.body?.category?.trim() || null,
          typeof request.body?.active === 'boolean' ? request.body.active : null,
          request.params.id,
        ],
      );
      const [rows] = await pool.execute('SELECT * FROM services WHERE service_id = ?', [request.params.id]);
      if (!rows.length) return response.status(404).json({ error: 'Servicio no encontrado.' });
      response.json(rows[0]);
    } catch (error) {
      next(error);
    }
  });

  router.delete('/services/:id', requireAdmin, async (request, response, next) => {
    try {
      const [appointments] = await pool.execute(
        'SELECT service_id FROM appointments WHERE service_id = ? LIMIT 1',
        [request.params.id],
      );
      if (appointments.length) {
        await pool.execute('UPDATE services SET active = FALSE WHERE service_id = ?', [request.params.id]);
        return response.json({ ok: true, deleted: false, reason: 'Desactivado por tener citas asociadas.' });
      }
      await pool.execute('DELETE FROM services WHERE service_id = ?', [request.params.id]);
      response.json({ ok: true, deleted: true });
    } catch (error) {
      next(error);
    }
  });

  router.post('/services/adjust-prices', requireAdmin, async (request, response, next) => {
    try {
      const type = request.body?.type === 'percentage' ? 'percentage' : 'fixed';
      const direction = request.body?.direction === 'down' ? 'down' : 'up';
      const amount = Number(request.body?.amount);
      if (!Number.isFinite(amount) || amount <= 0 ||
          (type === 'percentage' && amount >= 100)) {
        return response.status(400).json({ error: 'El ajuste no es válido.' });
      }
      const serviceId = request.body?.serviceId || null;
      const [rows] = await pool.execute(
        serviceId
          ? 'SELECT service_id, name, price FROM services WHERE service_id = ? AND active = TRUE'
          : 'SELECT service_id, name, price FROM services WHERE active = TRUE',
        serviceId ? [serviceId] : [],
      );
      const preview = rows.map((row) => {
        const price = adjustPrice(row.price, { type, direction, amount });
        return { serviceId: row.service_id, name: row.name, oldPrice: Number(row.price), newPrice: price };
      });
      if (preview.some((item) => item.newPrice === null)) {
        return response.status(400).json({ error: 'El ajuste dejaría algún precio en cero o negativo.' });
      }
      if (request.body?.apply === true) {
        for (const item of preview) {
          await pool.execute('UPDATE services SET price = ? WHERE service_id = ?', [item.newPrice, item.serviceId]);
        }
      }
      response.json({ preview, applied: request.body?.apply === true });
    } catch (error) {
      next(error);
    }
  });

  router.get('/appointments', requireAdmin, async (request, response, next) => {
    try {
      const status = request.query.status;
      const date = request.query.date;
      const search = String(request.query.search || '').trim();
      const where = [];
      const params = [];
      if (status === 'pendiente' || status === 'agendada') {
        where.push('a.status = ?');
        params.push(status);
      }
      if (date) {
        where.push('DATE(a.start_at) = ?');
        params.push(date);
      }
      if (search) {
        where.push('a.customer_name LIKE ?');
        params.push(`%${search}%`);
      }
      const sql = `
        SELECT a.event_id, a.reservation_code, a.customer_name, a.customer_email,
               a.customer_phone, a.service_name, COALESCE(a.price, s.price) AS price,
               a.start_at, a.end_at, a.status, sp.name AS specialist_name
        FROM appointments a
        LEFT JOIN services s ON s.service_id = a.service_id
        LEFT JOIN specialists sp ON sp.specialist_id = a.specialist_id
        ${where.length ? `WHERE ${where.join(' AND ')}` : ''}
        ORDER BY a.start_at DESC`;
      const [rows] = await pool.execute(sql, params);
      response.json(rows);
    } catch (error) {
      next(error);
    }
  });

  router.post('/appointments/:eventId/confirm', requireAdmin, async (request, response, next) => {
    try {
      const [rows] = await pool.execute(
        'SELECT event_id, service_name, customer_name, status FROM appointments WHERE event_id = ?',
        [request.params.eventId],
      );
      if (!rows.length) return response.status(404).json({ error: 'Cita no encontrada.' });
      const appointment = rows[0];
      if (appointment.status !== 'agendada') {
        await pool.execute(
          "UPDATE appointments SET status = 'agendada' WHERE event_id = ?",
          [request.params.eventId],
        );
        await googleCalendar.updateEventTitle(
          appointment.event_id,
          `Confirmada - ${appointment.service_name} - ${appointment.customer_name}`,
        );
      }
      response.json({ ok: true, status: 'agendada' });
    } catch (error) {
      next(error);
    }
  });

  return router;
};
