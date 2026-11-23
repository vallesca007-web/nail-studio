const express = require('express');

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
    const user = typeof request.body?.user === 'string' ? request.body.user.trim() : '';
    const password = typeof request.body?.password === 'string' ? request.body.password : '';
    if (!user || !password) return response.status(400).json({ error: 'Indica usuario y contraseña.' });
    if (user !== (process.env.ADMIN_USER || '')) {
      await new Promise((resolve) => setTimeout(resolve, 250));
      return response.status(401).json({ error: 'Usuario o contraseña incorrectos.' });
    }
    if (!(await loginPasswordMatches(password))) {
      return response.status(401).json({ error: 'Usuario o contraseña incorrectos.' });
    }
    response.cookie(cookieName, createAdminToken(), {
      httpOnly: true,
      sameSite: 'strict',
      secure: process.env.NODE_ENV === 'production' && process.env.COOKIE_SECURE === 'true',
      maxAge: 8 * 60 * 60 * 1000,
    });
    response.json({ ok: true, user });
  });

  router.post('/logout', requireAdmin, (request, response) => {
    response.clearCookie(cookieName, { httpOnly: true, sameSite: 'strict' });
    response.json({ ok: true });
  });

  router.get('/me', requireAdmin, (request, response) => {
    response.json({ ok: true, user: request.admin.user });
  });

  router.get('/services', requireAdmin, async (request, response, next) => {
    try {
      const [rows] = await pool.execute(
        'SELECT id, nombre, costo, duracion_min, activo FROM servicios ORDER BY nombre',
      );
      response.json(rows);
    } catch (error) {
      next(error);
    }
  });

  router.post('/services', requireAdmin, async (request, response, next) => {
    try {
      const nombre = String(request.body?.nombre || '').trim();
      const costo = Number(request.body?.costo);
      const duracion = Number(request.body?.duracion_min);
      if (!nombre || nombre.length > 100) return response.status(400).json({ error: 'El nombre no es válido.' });
      if (!Number.isFinite(costo) || costo <= 0) return response.status(400).json({ error: 'El costo debe ser mayor que cero.' });
      if (!Number.isInteger(duracion) || duracion <= 0) return response.status(400).json({ error: 'La duración no es válida.' });
      const [result] = await pool.execute(
        'INSERT INTO servicios (nombre, costo, duracion_min, activo) VALUES (?, ?, ?, TRUE)',
        [nombre, costo, duracion],
      );
      response.status(201).json({ id: result.insertId, nombre, costo, duracion_min: duracion, activo: true });
    } catch (error) {
      next(error);
    }
  });

  router.put('/services/:id', requireAdmin, async (request, response, next) => {
    try {
      const [rows] = await pool.execute('SELECT * FROM servicios WHERE id = ?', [request.params.id]);
      if (!rows.length) return response.status(404).json({ error: 'Servicio inexistente.' });
      const costo = request.body?.costo === undefined ? rows[0].costo : Number(request.body.costo);
      const duracion = request.body?.duracion_min === undefined ? rows[0].duracion_min : Number(request.body.duracion_min);
      const nombre = request.body?.nombre?.trim() || rows[0].nombre;
      const activo = typeof request.body?.activo === 'boolean' ? request.body.activo : rows[0].activo;
      if (!Number.isFinite(costo) || costo <= 0) return response.status(400).json({ error: 'El costo debe ser mayor que cero.' });
      if (!Number.isInteger(duracion) || duracion <= 0) return response.status(400).json({ error: 'La duración no es válida.' });
      await pool.execute(
        'UPDATE servicios SET nombre=?, costo=?, duracion_min=?, activo=? WHERE id=?',
        [nombre, costo, duracion, activo, request.params.id],
      );
      const [updated] = await pool.execute('SELECT * FROM servicios WHERE id = ?', [request.params.id]);
      response.json(updated[0]);
    } catch (error) {
      next(error);
    }
  });

  router.delete('/services/:id', requireAdmin, async (request, response, next) => {
    try {
      const [used] = await pool.execute('SELECT id FROM citas WHERE servicio_id = ? LIMIT 1', [request.params.id]);
      if (used.length) {
        await pool.execute('UPDATE servicios SET activo=FALSE WHERE id=?', [request.params.id]);
        return response.json({ ok: true, deleted: false, reason: 'Desactivado por tener citas asociadas.' });
      }
      await pool.execute('DELETE FROM servicios WHERE id=?', [request.params.id]);
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
      if (!Number.isFinite(amount) || amount <= 0 || (type === 'percentage' && amount >= 100)) {
        return response.status(400).json({ error: 'El ajuste no es válido.' });
      }
      const serviceId = request.body?.serviceId ? Number(request.body.serviceId) : null;
      const [rows] = await pool.execute(
        serviceId
          ? 'SELECT id,nombre,costo FROM servicios WHERE id=? AND activo=TRUE'
          : 'SELECT id,nombre,costo FROM servicios WHERE activo=TRUE',
        serviceId ? [serviceId] : [],
      );
      const preview = rows.map((row) => {
        const price = adjustPrice(row.costo, { type, direction, amount });
        return { serviceId: row.id, name: row.nombre, oldPrice: Number(row.costo), newPrice: price };
      });
      if (preview.some((item) => item.newPrice === null)) {
        return response.status(400).json({ error: 'El ajuste dejaría un costo inválido.' });
      }
      if (request.body?.apply === true) {
        for (const item of preview) {
          await pool.execute('UPDATE servicios SET costo=? WHERE id=?', [item.newPrice, item.serviceId]);
        }
      }
      response.json({ preview, applied: request.body?.apply === true });
    } catch (error) {
      next(error);
    }
  });

  router.get('/specialists', requireAdmin, async (request, response, next) => {
    try {
      const [rows] = await pool.execute(
        'SELECT id,nombre,activo FROM manicuristas WHERE activo=TRUE ORDER BY nombre',
      );
      response.json(rows);
    } catch (error) {
      next(error);
    }
  });

  router.post('/specialists', requireAdmin, async (request, response, next) => {
    try {
      const nombre = String(request.body?.nombre || '').trim();
      if (!nombre || nombre.length > 100) return response.status(400).json({ error: 'Nombre inválido.' });
      const [result] = await pool.execute(
        'INSERT INTO manicuristas (nombre, activo) VALUES (?, TRUE)',
        [nombre],
      );
      response.status(201).json({ id: result.insertId, nombre, activo: true });
    } catch (error) {
      next(error);
    }
  });

  router.delete('/specialists/:id', requireAdmin, async (request, response, next) => {
    try {
      const [used] = await pool.execute('SELECT id FROM citas WHERE manicurista_id=? LIMIT 1', [request.params.id]);
      if (used.length) {
        await pool.execute('UPDATE manicuristas SET activo=FALSE WHERE id=?', [request.params.id]);
        return response.json({ ok: true, deleted: false, reason: 'Desactivada por tener citas asociadas.' });
      }
      await pool.execute('DELETE FROM manicuristas WHERE id=?', [request.params.id]);
      response.json({ ok: true, deleted: true });
    } catch (error) {
      next(error);
    }
  });

  router.get('/appointments', requireAdmin, async (request, response, next) => {
    try {
      const estado = request.query.estado || request.query.status;
      const fecha = request.query.fecha || request.query.date;
      const search = String(request.query.search || '').trim();
      const where = [];
      const params = [];
      if (['pendiente', 'agendada'].includes(estado)) {
        where.push('c.estado = ?');
        params.push(estado);
      }
      if (fecha) {
        where.push('c.fecha = ?');
        params.push(fecha);
      }
      if (search) {
        where.push('u.correo LIKE ?');
        params.push(`%${search}%`);
      }
      const [rows] = await pool.execute(
        `SELECT c.id,c.fecha,c.hora,c.hora_fin,c.precio,c.telefono,c.estado,c.google_event_id,
                s.nombre AS servicio,m.nombre AS manicurista,u.correo
         FROM citas c
         JOIN servicios s ON s.id=c.servicio_id
         JOIN usuarios u ON u.id=c.usuario_id
         LEFT JOIN manicuristas m ON m.id=c.manicurista_id
         ${where.length ? `WHERE ${where.join(' AND ')}` : ''}
         ORDER BY c.fecha DESC,c.hora DESC`,
        params,
      );
      response.json(rows);
    } catch (error) {
      next(error);
    }
  });

  router.post('/appointments/:id/confirm', requireAdmin, async (request, response, next) => {
    try {
      const [rows] = await pool.execute(
        `SELECT c.id,c.google_event_id,c.estado,s.nombre AS servicio,u.correo
         FROM citas c JOIN servicios s ON s.id=c.servicio_id JOIN usuarios u ON u.id=c.usuario_id
         WHERE c.id=?`,
        [request.params.id],
      );
      if (!rows.length) return response.status(404).json({ error: 'Cita inexistente.' });
      const cita = rows[0];
      if (cita.estado !== 'pendiente') {
        return response.status(409).json({ error: `La cita ya está ${cita.estado}.` });
      }
      let manicuristaId = request.body?.manicurista_id ? Number(request.body.manicurista_id) : null;
      if (manicuristaId) {
        const [manicuristas] = await pool.execute(
          'SELECT id FROM manicuristas WHERE id=? AND activo=TRUE',
          [manicuristaId],
        );
        if (!manicuristas.length) return response.status(404).json({ error: 'Manicurista inexistente.' });
      } else {
        const [manicuristas] = await pool.execute(
          'SELECT id FROM manicuristas WHERE activo=TRUE ORDER BY id LIMIT 1',
        );
        manicuristaId = manicuristas[0]?.id || null;
      }
      await pool.execute(
        "UPDATE citas SET estado='agendada', manicurista_id=? WHERE id=?",
        [manicuristaId, request.params.id],
      );
      if (cita.google_event_id) {
        await googleCalendar.updateEventTitle(
          cita.google_event_id,
          `Confirmada - ${cita.servicio} - ${cita.correo}`,
        );
      }
      response.json({ ok: true, estado: 'agendada', manicurista_id: manicuristaId });
    } catch (error) {
      next(error);
    }
  });

  // Cambia el estado de una cita y libera el horario en la agenda. El evento de
  // Google Calendar solo se borra si se borra bien; si falla se conserva el id.
  async function changeAppointmentStatus(request, response, next, estado, from) {
    try {
      const [rows] = await pool.execute(
        'SELECT id,estado,google_event_id FROM citas WHERE id=?',
        [request.params.id],
      );
      if (!rows.length) return response.status(404).json({ error: 'Cita inexistente.' });
      const cita = rows[0];
      if (!from.includes(cita.estado)) {
        return response.status(409).json({ error: `La cita ya está ${cita.estado}.` });
      }
      let googleEventId = cita.google_event_id;
      if (googleEventId) {
        try {
          await googleCalendar.deleteEvent(googleEventId);
          googleEventId = null;
        } catch (error) {
          console.error('No se pudo borrar el evento de Google Calendar:', error.message);
        }
      }
      await pool.execute('UPDATE citas SET estado=?, google_event_id=? WHERE id=?', [
        estado,
        googleEventId,
        cita.id,
      ]);
      response.json({ ok: true, estado });
    } catch (error) {
      next(error);
    }
  }

  // Rechazar solo aplica a una solicitud pendiente; cancelar también sirve para
  // una cita que ya estaba confirmada.
  router.post('/appointments/:id/reject', requireAdmin, (request, response, next) =>
    changeAppointmentStatus(request, response, next, 'rechazada', ['pendiente']),
  );

  router.post('/appointments/:id/cancel', requireAdmin, (request, response, next) =>
    changeAppointmentStatus(request, response, next, 'cancelada', ['pendiente', 'agendada']),
  );

  return router;
};
