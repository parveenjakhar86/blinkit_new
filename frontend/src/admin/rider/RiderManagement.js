import React, { useEffect, useMemo, useState } from 'react';

import { getAdminToken } from '../../utils/auth';

const initialRider = {
  name: '',
  email: '',
  phone: '',
  vehicleNumber: '',
  zone: '',
  availabilityStatus: 'offline',
  status: 'active',
};

function formatDateTime(value) {
  if (!value) return '-';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '-';
  return date.toLocaleString('en-IN');
}

function formatAcceptMinutes(value) {
  const number = Number(value || 0);
  if (!number) return '-';
  return `${number.toFixed(1)} min`;
}

function RiderForm({ value, onChange, onSubmit, onCancel, title, error }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-30 p-4">
      <form onSubmit={onSubmit} className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-xl">
        <h3 className="mb-4 text-lg font-bold">{title}</h3>
        <div className="grid gap-3 sm:grid-cols-2">
          <input className="rounded border p-2" placeholder="Name" value={value.name} onChange={(e) => onChange({ ...value, name: e.target.value })} required />
          <input className="rounded border p-2" placeholder="Phone" value={value.phone} onChange={(e) => onChange({ ...value, phone: e.target.value })} required />
          <input className="rounded border p-2" placeholder="Email" type="email" value={value.email || ''} onChange={(e) => onChange({ ...value, email: e.target.value })} />
          <input className="rounded border p-2" placeholder="Vehicle Number" value={value.vehicleNumber || ''} onChange={(e) => onChange({ ...value, vehicleNumber: e.target.value })} />
          <input className="rounded border p-2" placeholder="Zone" value={value.zone || ''} onChange={(e) => onChange({ ...value, zone: e.target.value })} />
          <select className="rounded border p-2" value={value.availabilityStatus || 'offline'} onChange={(e) => onChange({ ...value, availabilityStatus: e.target.value })}>
            <option value="offline">Offline</option>
            <option value="online">Online</option>
          </select>
          <select className="rounded border p-2 sm:col-span-2" value={value.status || 'active'} onChange={(e) => onChange({ ...value, status: e.target.value })}>
            <option value="active">Active</option>
            <option value="block">Blocked</option>
          </select>
        </div>
        {error && <div className="mt-3 text-sm text-red-600">{error}</div>}
        <div className="mt-5 flex justify-end gap-2">
          <button type="button" className="rounded bg-gray-200 px-4 py-2" onClick={onCancel}>Cancel</button>
          <button type="submit" className="rounded bg-green-600 px-4 py-2 font-semibold text-white">Save</button>
        </div>
      </form>
    </div>
  );
}

export default function RiderManagement() {
  const [riders, setRiders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [showAdd, setShowAdd] = useState(false);
  const [showEdit, setShowEdit] = useState(false);
  const [newRider, setNewRider] = useState(initialRider);
  const [editRider, setEditRider] = useState(null);
  const [formError, setFormError] = useState('');

  const adminToken = getAdminToken();

  const fetchRiders = () => {
    if (!adminToken) {
      setError('Admin login required');
      setLoading(false);
      return;
    }

    setLoading(true);
    setError('');
    fetch('/api/admin/riders', {
      headers: { Authorization: `Bearer ${adminToken}` },
    })
      .then(async (res) => {
        const data = await res.json();
        if (!res.ok) {
          throw new Error(data.message || 'Failed to fetch riders');
        }
        return data;
      })
      .then((data) => {
        setRiders(Array.isArray(data) ? data : []);
        setLoading(false);
      })
      .catch((err) => {
        setError(err.message);
        setLoading(false);
      });
  };

  useEffect(() => {
    fetchRiders();
  }, []);

  const filteredRiders = useMemo(() => {
    const key = search.toLowerCase();
    return riders.filter((rider) =>
      [
        rider.name,
        rider.email,
        rider.phone,
        rider.zone,
        rider.vehicleNumber,
        rider.currentOrderStatus,
      ].some((value) => String(value || '').toLowerCase().includes(key))
    );
  }, [riders, search]);

  const handleCreate = (event) => {
    event.preventDefault();
    setFormError('');

    fetch('/api/admin/riders', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${adminToken}`,
      },
      body: JSON.stringify(newRider),
    })
      .then(async (res) => {
        const data = await res.json();
        if (!res.ok) {
          throw new Error(data.message || 'Failed to create rider');
        }
        return data;
      })
      .then(() => {
        setShowAdd(false);
        setNewRider(initialRider);
        fetchRiders();
      })
      .catch((err) => setFormError(err.message));
  };

  const handleEdit = (event) => {
    event.preventDefault();
    setFormError('');

    fetch(`/api/admin/riders/${editRider._id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${adminToken}`,
      },
      body: JSON.stringify(editRider),
    })
      .then(async (res) => {
        const data = await res.json();
        if (!res.ok) {
          throw new Error(data.message || 'Failed to update rider');
        }
        return data;
      })
      .then(() => {
        setShowEdit(false);
        setEditRider(null);
        fetchRiders();
      })
      .catch((err) => setFormError(err.message));
  };

  const handleStatusToggle = (rider) => {
    fetch(`/api/admin/riders/${rider._id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${adminToken}`,
      },
      body: JSON.stringify({
        ...rider,
        status: rider.status === 'active' ? 'block' : 'active',
      }),
    }).then(() => fetchRiders());
  };

  const handleAvailabilityToggle = (rider) => {
    fetch(`/api/admin/riders/${rider._id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${adminToken}`,
      },
      body: JSON.stringify({
        ...rider,
        availabilityStatus: rider.availabilityStatus === 'online' ? 'offline' : 'online',
      }),
    }).then(() => fetchRiders());
  };

  const handleDelete = (rider) => {
    if (!window.confirm(`Delete rider ${rider.name}?`)) {
      return;
    }

    fetch(`/api/admin/riders/${rider._id}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${adminToken}` },
    }).then(() => fetchRiders());
  };

  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <div className="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="text-2xl font-bold text-gray-800">Rider Management</h2>
          <p className="mt-1 text-sm text-gray-500">Track rider details, offline or online status, accepted order flow and response timing.</p>
        </div>
        <button className="rounded-lg bg-green-600 px-5 py-2 font-semibold text-white shadow hover:bg-green-700 transition" onClick={() => { setFormError(''); setShowAdd(true); }}>
          + Add Rider
        </button>
      </div>

      <div className="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <input
          type="text"
          placeholder="Search riders..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full sm:w-80 rounded-lg border px-4 py-2 focus:outline-none focus:ring"
        />
        <div className="grid grid-cols-2 gap-3 sm:flex">
          <div className="rounded-xl bg-white px-4 py-3 shadow-sm">
            <div className="text-xs text-gray-500">Total Riders</div>
            <div className="text-xl font-bold">{riders.length}</div>
          </div>
          <div className="rounded-xl bg-white px-4 py-3 shadow-sm">
            <div className="text-xs text-gray-500">Online Riders</div>
            <div className="text-xl font-bold text-green-700">{riders.filter((rider) => rider.availabilityStatus === 'online').length}</div>
          </div>
        </div>
      </div>

      {showAdd && (
        <RiderForm
          value={newRider}
          onChange={setNewRider}
          onSubmit={handleCreate}
          onCancel={() => setShowAdd(false)}
          title="Add Rider"
          error={formError}
        />
      )}

      {showEdit && editRider && (
        <RiderForm
          value={editRider}
          onChange={setEditRider}
          onSubmit={handleEdit}
          onCancel={() => setShowEdit(false)}
          title="Edit Rider"
          error={formError}
        />
      )}

      <div className="overflow-x-auto rounded-xl bg-white p-4 shadow">
        {loading ? (
          <div className="text-gray-500">Loading riders...</div>
        ) : error ? (
          <div className="text-red-500">{error}</div>
        ) : (
          <table className="min-w-full text-sm">
            <thead>
              <tr className="border-b text-left text-gray-500">
                <th className="py-2 pr-4">Rider</th>
                <th className="py-2 pr-4">Phone</th>
                <th className="py-2 pr-4">Zone</th>
                <th className="py-2 pr-4">Vehicle</th>
                <th className="py-2 pr-4">Account</th>
                <th className="py-2 pr-4">Online Status</th>
                <th className="py-2 pr-4">Active Orders</th>
                <th className="py-2 pr-4">Accepted</th>
                <th className="py-2 pr-4">Delivered</th>
                <th className="py-2 pr-4">Avg Accept Time</th>
                <th className="py-2 pr-4">Current Order Status</th>
                <th className="py-2 pr-4">Last Accepted</th>
                <th className="py-2 pr-4">Last Seen</th>
                <th className="py-2">Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredRiders.map((rider) => (
                <tr key={rider._id} className="border-b hover:bg-gray-50 align-top">
                  <td className="py-3 pr-4">
                    <div className="font-semibold text-gray-800">{rider.name}</div>
                    <div className="text-xs text-gray-500">{rider.email || '-'}</div>
                  </td>
                  <td className="py-3 pr-4">{rider.phone || '-'}</td>
                  <td className="py-3 pr-4">{rider.zone || '-'}</td>
                  <td className="py-3 pr-4">{rider.vehicleNumber || '-'}</td>
                  <td className="py-3 pr-4">
                    <span className={`rounded px-2 py-1 text-xs font-semibold ${rider.status === 'active' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                      {rider.status}
                    </span>
                  </td>
                  <td className="py-3 pr-4">
                    <span className={`rounded px-2 py-1 text-xs font-semibold ${rider.availabilityStatus === 'online' ? 'bg-emerald-100 text-emerald-700' : 'bg-gray-200 text-gray-600'}`}>
                      {rider.availabilityStatus}
                    </span>
                  </td>
                  <td className="py-3 pr-4 font-semibold">{rider.activeOrders || 0}</td>
                  <td className="py-3 pr-4 font-semibold">{rider.acceptedOrders || 0}</td>
                  <td className="py-3 pr-4 font-semibold">{rider.deliveredOrders || 0}</td>
                  <td className="py-3 pr-4">{formatAcceptMinutes(rider.averageAcceptMinutes)}</td>
                  <td className="py-3 pr-4">{rider.currentOrderStatus || '-'}</td>
                  <td className="py-3 pr-4">{formatDateTime(rider.lastAcceptedAt)}</td>
                  <td className="py-3 pr-4">{formatDateTime(rider.lastSeenAt)}</td>
                  <td className="py-3">
                    <div className="flex flex-wrap gap-2">
                      <button className="rounded bg-blue-100 px-3 py-1 text-blue-700 hover:bg-blue-200" onClick={() => { setFormError(''); setEditRider({ ...rider }); setShowEdit(true); }}>
                        Edit
                      </button>
                      <button className="rounded bg-gray-100 px-3 py-1 text-gray-700 hover:bg-gray-200" onClick={() => handleAvailabilityToggle(rider)}>
                        {rider.availabilityStatus === 'online' ? 'Set Offline' : 'Set Online'}
                      </button>
                      <button className={`rounded px-3 py-1 ${rider.status === 'active' ? 'bg-yellow-100 text-yellow-700 hover:bg-yellow-200' : 'bg-green-100 text-green-700 hover:bg-green-200'}`} onClick={() => handleStatusToggle(rider)}>
                        {rider.status === 'active' ? 'Block' : 'Activate'}
                      </button>
                      <button className="rounded bg-red-100 px-3 py-1 text-red-700 hover:bg-red-200" onClick={() => handleDelete(rider)}>
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}