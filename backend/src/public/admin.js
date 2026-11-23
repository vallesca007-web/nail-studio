const state = { status: 'pendiente', preview: null, services: [] };

const escapeHtml = (value) => String(value ?? '')
  .replaceAll('&', '&amp;')
  .replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;')
  .replaceAll('"', '&quot;')
  .replaceAll("'", '&#039;');

const message = (text, isError = false) => {
  const element = document.querySelector('#message');
  element.textContent = text;
  element.style.color = isError ? '#b3261e' : '#8e3f5a';
};

async function api(path, options = {}) {
  const response = await fetch(path, {
    ...options,
    headers: { 'Content-Type': 'application/json', ...(options.headers || {}) },
  });
  let body = {};
  try { body = await response.json(); } catch {}
  if (response.status === 401) {
    showLogin();
  }
  if (!response.ok) throw new Error(body.error || `Error ${response.status}`);
  return body;
}

function showLogin() {
  document.querySelector('#loginView').classList.remove('hidden');
  document.querySelector('#adminView').classList.add('hidden');
}

function showAdmin() {
  document.querySelector('#loginView').classList.add('hidden');
  document.querySelector('#adminView').classList.remove('hidden');
  loadAppointments();
}

function setLoading(loading) {
  document.querySelector('#loading').classList.toggle('hidden', !loading);
}

document.querySelector('#loginForm').addEventListener('submit', async (event) => {
  event.preventDefault();
  const loginMessage = document.querySelector('#loginMessage');
  loginMessage.textContent = 'Cargando...';
  try {
    await api('/api/admin/login', {
      method: 'POST',
      body: JSON.stringify({
        user: document.querySelector('#loginUser').value,
        password: document.querySelector('#loginPassword').value,
      }),
    });
    loginMessage.textContent = '';
    showAdmin();
  } catch (error) {
    loginMessage.textContent = error.message;
  }
});

document.querySelector('#logoutButton').addEventListener('click', async () => {
  try { await api('/api/admin/logout', { method: 'POST', body: '{}' }); } catch {}
  showLogin();
});

document.querySelectorAll('.nav-button').forEach((button) => {
  button.addEventListener('click', () => {
    document.querySelectorAll('.nav-button').forEach((item) => item.classList.remove('active'));
    button.classList.add('active');
    document.querySelectorAll('.section').forEach((section) => section.classList.add('hidden'));
    document.querySelector(`#${button.dataset.section}Section`).classList.remove('hidden');
    document.querySelector('#sectionTitle').textContent =
      button.dataset.section === 'appointments' ? 'Citas' :
      button.dataset.section === 'specialists' ? 'Manicuristas' : 'Servicios';
    if (button.dataset.section === 'appointments') loadAppointments();
    if (button.dataset.section === 'specialists') loadSpecialists();
    if (button.dataset.section === 'services') loadServices();
  });
});

document.querySelectorAll('.tab').forEach((tab) => {
  tab.addEventListener('click', () => {
    document.querySelectorAll('.tab').forEach((item) => item.classList.remove('active'));
    tab.classList.add('active');
    state.status = tab.dataset.status;
    loadAppointments();
  });
});

document.querySelector('#appointmentSearch').addEventListener('input', debounce(loadAppointments, 300));
document.querySelector('#appointmentDate').addEventListener('change', loadAppointments);

function debounce(callback, delay) {
  let timeout;
  return () => {
    clearTimeout(timeout);
    timeout = setTimeout(callback, delay);
  };
}

async function loadAppointments() {
  setLoading(true);
  try {
    const search = document.querySelector('#appointmentSearch').value;
    const date = document.querySelector('#appointmentDate').value;
    const params = new URLSearchParams({ status: state.status });
    if (search) params.set('search', search);
    if (date) params.set('date', date);
    const rows = await api(`/api/admin/appointments?${params}`);
    const list = document.querySelector('#appointmentsList');
    if (!rows.length) {
      list.innerHTML = '<div class="card">No hay citas para mostrar.</div>';
      return;
    }
    list.innerHTML = rows.map((row) => {
      const dateText = row.fecha;
      const timeText = String(row.hora).slice(0,5);
      return `<article class="card">
        <div class="card-row">
          <div>
            <h2>${escapeHtml(row.correo)}</h2>
            <div class="meta">${escapeHtml(row.telefono || 'Sin teléfono')}</div>
          </div>
          <span class="badge">${escapeHtml(row.estado)}</span>
        </div>
        <div class="meta">
          ${escapeHtml(row.servicio)} · $${Number(row.precio || 0).toFixed(2)}<br>
          Manicurista: ${escapeHtml(row.manicurista || 'Sin asignar')}<br>
          ${dateText} · ${timeText}
        </div>
        ${row.estado === 'pendiente'
          ? `<button class="primary confirm-button" data-id="${escapeHtml(row.id)}">Confirmar</button>`
          : ''}
      </article>`;
    }).join('');
    document.querySelectorAll('.confirm-button').forEach((button) => {
      button.addEventListener('click', () => confirmAppointment(button.dataset.id));
    });
  } catch (error) {
    message(error.message, true);
  } finally {
    setLoading(false);
  }
}

async function confirmAppointment(eventId) {
  try {
    await api(`/api/admin/appointments/${encodeURIComponent(eventId)}/confirm`, {
      method: 'POST',
      body: '{}',
    });
    message('Cita confirmada.');
    await loadAppointments();
  } catch (error) {
    message(error.message, true);
  }
}

document.querySelector('#addSpecialistButton').addEventListener('click', () => {
  document.querySelector('#specialistForm').classList.toggle('hidden');
});

document.querySelector('#specialistForm').addEventListener('submit', async (event) => {
  event.preventDefault();
  const form = new FormData(event.currentTarget);
  try {
    await api('/api/admin/specialists', {
      method: 'POST',
      body: JSON.stringify({ nombre: form.get('name') }),
    });
    event.currentTarget.reset();
    event.currentTarget.classList.add('hidden');
    message('Manicurista agregada.');
    loadSpecialists();
  } catch (error) { message(error.message, true); }
});

async function loadSpecialists() {
  setLoading(true);
  try {
    const rows = await api('/api/admin/specialists');
    const list = document.querySelector('#specialistsList');
    list.innerHTML = rows.length ? rows.map((row) => `<article class="card">
      <div class="card-row"><div><h3>${escapeHtml(row.nombre)}</h3></div>
      <button class="secondary delete-specialist" data-id="${escapeHtml(row.id)}" data-name="${escapeHtml(row.nombre)}">Eliminar</button></div>
    </article>`).join('') : '<div class="card">No hay manicuristas activas.</div>';
    document.querySelectorAll('.delete-specialist').forEach((button) => button.addEventListener('click', async () => {
      if (!confirm(`¿Eliminar a ${button.dataset.name}?`)) return;
      try {
        await api(`/api/admin/specialists/${encodeURIComponent(button.dataset.id)}`, { method: 'DELETE', body: '{}' });
        message('Manicurista eliminada o desactivada.');
        loadSpecialists();
      } catch (error) { message(error.message, true); }
    }));
  } catch (error) { message(error.message, true); } finally { setLoading(false); }
}

document.querySelector('#addServiceButton').addEventListener('click', () => {
  document.querySelector('#serviceForm').classList.toggle('hidden');
});

document.querySelector('#serviceForm').addEventListener('submit', async (event) => {
  event.preventDefault();
  const form = new FormData(event.currentTarget);
  try {
    await api('/api/admin/services', {
      method: 'POST',
      body: JSON.stringify({
        nombre: form.get('name'),
        costo: Number(form.get('price')),
        duracion_min: Number(form.get('durationMinutes')),
      }),
    });
    event.currentTarget.reset();
    event.currentTarget.classList.add('hidden');
    message('Servicio agregado.');
    loadServices();
  } catch (error) { message(error.message, true); }
});

async function loadServices() {
  setLoading(true);
  try {
    state.services = await api('/api/admin/services');
    const select = document.querySelector('#priceServiceId');
    select.innerHTML = state.services.map((row) =>
      `<option value="${escapeHtml(row.id)}">${escapeHtml(row.nombre)}</option>`).join('');
    const list = document.querySelector('#servicesList');
    list.innerHTML = state.services.length ? state.services.map((row) => `<article class="card">
      <div class="card-row"><div><h3>${escapeHtml(row.nombre)}</h3><div class="meta">${row.duracion_min} minutos</div></div>
      <button class="secondary delete-service" data-id="${escapeHtml(row.id)}" data-name="${escapeHtml(row.nombre)}">Eliminar</button></div>
      <div class="price-line">Costo: $<input class="service-price" data-id="${escapeHtml(row.id)}" type="number" min="0.01" step="0.01" value="${Number(row.costo).toFixed(2)}">
      <button class="primary save-price" data-id="${escapeHtml(row.id)}">Guardar</button></div>
    </article>`).join('') : '<div class="card">No hay servicios.</div>';
    document.querySelectorAll('.save-price').forEach((button) => button.addEventListener('click', async () => {
      const input = document.querySelector(`.service-price[data-id="${CSS.escape(button.dataset.id)}"]`);
      try {
        await api(`/api/admin/services/${encodeURIComponent(button.dataset.id)}`, { method:'PUT', body:JSON.stringify({ costo:Number(input.value) }) });
        message('Precio actualizado.');
        loadServices();
      } catch (error) { message(error.message, true); }
    }));
    document.querySelectorAll('.delete-service').forEach((button) => button.addEventListener('click', async () => {
      if (!confirm(`¿Eliminar ${button.dataset.name}?`)) return;
      try {
        await api(`/api/admin/services/${encodeURIComponent(button.dataset.id)}`, { method:'DELETE', body:'{}' });
        message('Servicio eliminado o desactivado.');
        loadServices();
      } catch (error) { message(error.message, true); }
    }));
  } catch (error) { message(error.message, true); } finally { setLoading(false); }
}

document.querySelector('#adjustPricesButton').addEventListener('click', () => {
  document.querySelector('#adjustForm').classList.toggle('hidden');
});
document.querySelector('#adjustForm [name="scope"]').addEventListener('change', (event) => {
  document.querySelector('#priceServiceId').classList.toggle('hidden', event.target.value !== 'one');
});

async function previewPrices(apply = false) {
  const form = new FormData(document.querySelector('#adjustForm'));
  const scope = form.get('scope');
  try {
    state.preview = await api('/api/admin/services/adjust-prices', {
      method:'POST',
      body:JSON.stringify({
        type: form.get('type'), direction:form.get('direction'), amount:Number(form.get('amount')),
        serviceId: scope === 'one' ? form.get('serviceId') : null, apply,
      }),
    });
    document.querySelector('#pricePreview').innerHTML = state.preview.preview.map((row) =>
      `<div class="card"><strong>${escapeHtml(row.name)}</strong><div class="meta">$${row.oldPrice.toFixed(2)} → $${row.newPrice.toFixed(2)}</div></div>`
    ).join('');
    document.querySelector('#applyAdjustButton').classList.toggle('hidden', apply);
    if (apply) { message('Precios ajustados.'); loadServices(); }
  } catch (error) { message(error.message, true); }
}

document.querySelector('#previewAdjustButton').addEventListener('click', () => previewPrices(false));
document.querySelector('#applyAdjustButton').addEventListener('click', () => previewPrices(true));

api('/api/admin/me').then(showAdmin).catch(showLogin);
