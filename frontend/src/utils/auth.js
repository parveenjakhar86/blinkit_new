function safeParseJwt(token) {
  try {
    const parts = token.split('.');
    if (parts.length < 2) {
      return null;
    }

    const payload = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const normalized = payload.padEnd(Math.ceil(payload.length / 4) * 4, '=');

    return JSON.parse(window.atob(normalized));
  } catch (_) {
    return null;
  }
}

function getStoredSessions() {
  const sessions = [];
  const adminToken = localStorage.getItem('adminToken');
  const managerToken = localStorage.getItem('managerToken');

  if (adminToken) {
    sessions.push({ role: 'admin', token: adminToken });
  }

  if (managerToken) {
    sessions.push({ role: 'manager', token: managerToken });
  }

  return sessions;
}

function getNewestSession(sessions) {
  return [...sessions].sort((left, right) => {
    const leftPayload = safeParseJwt(left.token) || {};
    const rightPayload = safeParseJwt(right.token) || {};
    const leftIssuedAt = Number(leftPayload.iat || 0);
    const rightIssuedAt = Number(rightPayload.iat || 0);

    return rightIssuedAt - leftIssuedAt;
  })[0] || null;
}

export function getAuthRole() {
  const storedRole = localStorage.getItem('authRole');
  const sessions = getStoredSessions();

  if (!sessions.length) {
    localStorage.removeItem('authRole');
    return null;
  }

  if (storedRole === 'admin' && localStorage.getItem('adminToken')) {
    return storedRole;
  }

  if (storedRole === 'manager' && localStorage.getItem('managerToken')) {
    return storedRole;
  }

  if (sessions.length === 1) {
    localStorage.setItem('authRole', sessions[0].role);
    return sessions[0].role;
  }

  const newestSession = getNewestSession(sessions);
  if (!newestSession) {
    localStorage.removeItem('authRole');
    return null;
  }

  localStorage.setItem('authRole', newestSession.role);
  return newestSession.role;
}

export function getAuthToken(role = getAuthRole()) {
  if (role === 'admin') {
    return localStorage.getItem('adminToken');
  }

  if (role === 'manager') {
    return localStorage.getItem('managerToken');
  }

  return null;
}

export function getAdminToken() {
  return localStorage.getItem('adminToken');
}

export function getManagerToken() {
  return localStorage.getItem('managerToken');
}

export function getAuthHeaders(role) {
  const token = getAuthToken(role);

  return token ? { Authorization: `Bearer ${token}` } : {};
}

export function setAdminSession(token) {
  localStorage.setItem('adminToken', token);
  localStorage.removeItem('managerToken');
  localStorage.setItem('authRole', 'admin');
}

export function setManagerSession(token) {
  localStorage.setItem('managerToken', token);
  localStorage.removeItem('adminToken');
  localStorage.setItem('authRole', 'manager');
}

export function clearAuthSession() {
  localStorage.removeItem('adminToken');
  localStorage.removeItem('managerToken');
  localStorage.removeItem('authRole');
}