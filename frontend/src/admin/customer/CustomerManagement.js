import React, { useEffect, useState } from 'react';
import { getAdminToken } from '../../utils/auth';

const initialCustomer = {
  name: '',
  email: '',
  phone: '',
  address: '',
  password: '',
  status: 'active'
};

export default function CustomerManagement() {
  const [customers, setCustomers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');

  const [showAdd, setShowAdd] = useState(false);
  const [newCustomer, setNewCustomer] = useState(initialCustomer);
  const [addError, setAddError] = useState('');

  const [showEdit, setShowEdit] = useState(false);
  const [editCustomer, setEditCustomer] = useState(null);
  const [editPassword, setEditPassword] = useState('');
  const [editError, setEditError] = useState('');

  const adminToken = getAdminToken();

  const fetchCustomers = () => {
    if (!adminToken) {
      setError('Admin login required');
      setLoading(false);
      return;
    }

    setLoading(true);
    setError('');
    fetch('/api/admin/customers', {
      headers: {
        Authorization: 'Bearer ' + adminToken
      }
    })
      .then(async (res) => {
        const data = await res.json();
        if (!res.ok) {
          throw new Error(data.message || 'Failed to fetch customers');
        }
        return data;
      })
      .then((data) => {
        setCustomers(data);
        setLoading(false);
      })
      .catch((err) => {
        setError(err.message);
        setLoading(false);
      });
  };

  useEffect(() => {
    fetchCustomers();
  }, []);

  const filteredCustomers = customers.filter((customer) => {
    const key = search.toLowerCase();
    return (
      customer.name?.toLowerCase().includes(key) ||
      customer.email?.toLowerCase().includes(key) ||
      customer.phone?.toLowerCase().includes(key)
    );
  });

  const handleStatusToggle = (customer) => {
    const nextStatus = customer.status === 'active' ? 'block' : 'active';
    fetch(`/api/admin/customers/${customer._id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Bearer ' + adminToken
      },
      body: JSON.stringify({
        ...customer,
        status: nextStatus,
        password: ''
      })
    })
      .then(async (res) => {
        const data = await res.json();
        if (!res.ok) {
          throw new Error(data.message || 'Failed to update customer');
        }
        return data;
      })
      .then(() => fetchCustomers())
      .catch((err) => alert(err.message));
  };

  const handleAddCustomer = (e) => {
    e.preventDefault();
    setAddError('');

    fetch('/api/admin/customers', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Bearer ' + adminToken
      },
      body: JSON.stringify(newCustomer)
    })
      .then(async (res) => {
        const data = await res.json();
        if (!res.ok) {
          throw new Error(data.message || 'Failed to add customer');
        }
        return data;
      })
      .then(() => {
        setShowAdd(false);
        setNewCustomer(initialCustomer);
        fetchCustomers();
      })
      .catch((err) => setAddError(err.message));
  };

  const handleEditOpen = (customer) => {
    setEditCustomer({ ...customer });
    setEditPassword('');
    setEditError('');
    setShowEdit(true);
  };

  const handleEditSubmit = (e) => {
    e.preventDefault();
    setEditError('');

    const payload = {
      ...editCustomer,
      password: editPassword
    };

    fetch(`/api/admin/customers/${editCustomer._id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Bearer ' + adminToken
      },
      body: JSON.stringify(payload)
    })
      .then(async (res) => {
        const data = await res.json();
        if (!res.ok) {
          throw new Error(data.message || 'Failed to update customer');
        }
        return data;
      })
      .then(() => {
        setShowEdit(false);
        setEditCustomer(null);
        setEditPassword('');
        fetchCustomers();
      })
      .catch((err) => setEditError(err.message));
  };

  const handleDelete = (customer) => {
    if (!window.confirm(`Delete customer ${customer.name}?`)) {
      return;
    }

    fetch(`/api/admin/customers/${customer._id}`, {
      method: 'DELETE',
      headers: {
        Authorization: 'Bearer ' + adminToken
      }
    })
      .then(async (res) => {
        const data = await res.json();
        if (!res.ok) {
          throw new Error(data.message || 'Failed to delete customer');
        }
        return data;
      })
      .then(() => fetchCustomers())
      .catch((err) => alert(err.message));
  };

  return (
    <div className="p-8 bg-gray-50 min-h-screen">
      <h2 className="text-2xl font-bold mb-6 text-gray-800">Customer Management</h2>

      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-6 gap-4">
        <input
          type="text"
          placeholder="Search customers..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full sm:w-72 px-4 py-2 border rounded-lg focus:outline-none focus:ring"
        />
        <button
          className="bg-green-600 text-white px-5 py-2 rounded-lg font-semibold shadow hover:bg-green-700 transition"
          onClick={() => setShowAdd(true)}
        >
          + Add Customer
        </button>
      </div>

      {showAdd && (
        <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-30 z-50">
          <form onSubmit={handleAddCustomer} className="bg-white p-6 rounded-lg shadow-lg w-full max-w-md">
            <h3 className="text-lg font-bold mb-4">Add Customer</h3>
            <input className="w-full mb-2 p-2 border rounded" placeholder="Name" value={newCustomer.name} onChange={(e) => setNewCustomer({ ...newCustomer, name: e.target.value })} required />
            <input className="w-full mb-2 p-2 border rounded" placeholder="Email" type="email" value={newCustomer.email} onChange={(e) => setNewCustomer({ ...newCustomer, email: e.target.value })} required />
            <input className="w-full mb-2 p-2 border rounded" placeholder="Phone" value={newCustomer.phone} onChange={(e) => setNewCustomer({ ...newCustomer, phone: e.target.value })} />
            <input className="w-full mb-2 p-2 border rounded" placeholder="Address" value={newCustomer.address} onChange={(e) => setNewCustomer({ ...newCustomer, address: e.target.value })} />
            <input className="w-full mb-2 p-2 border rounded" placeholder="Password (default customer123)" type="password" value={newCustomer.password} onChange={(e) => setNewCustomer({ ...newCustomer, password: e.target.value })} />
            <select className="w-full mb-2 p-2 border rounded" value={newCustomer.status} onChange={(e) => setNewCustomer({ ...newCustomer, status: e.target.value })}>
              <option value="active">Active</option>
              <option value="block">Blocked</option>
            </select>
            {addError && <div className="text-red-500 mb-2">{addError}</div>}
            <div className="flex gap-2 justify-end">
              <button type="button" className="px-4 py-2 bg-gray-200 rounded" onClick={() => setShowAdd(false)}>Cancel</button>
              <button type="submit" className="px-4 py-2 bg-green-600 text-white rounded">Add</button>
            </div>
          </form>
        </div>
      )}

      {showEdit && editCustomer && (
        <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-30 z-50">
          <form onSubmit={handleEditSubmit} className="bg-white p-6 rounded-lg shadow-lg w-full max-w-md">
            <h3 className="text-lg font-bold mb-4">Edit Customer</h3>
            <input className="w-full mb-2 p-2 border rounded" placeholder="Name" value={editCustomer.name} onChange={(e) => setEditCustomer({ ...editCustomer, name: e.target.value })} required />
            <input className="w-full mb-2 p-2 border rounded" placeholder="Email" type="email" value={editCustomer.email} onChange={(e) => setEditCustomer({ ...editCustomer, email: e.target.value })} required />
            <input className="w-full mb-2 p-2 border rounded" placeholder="Phone" value={editCustomer.phone || ''} onChange={(e) => setEditCustomer({ ...editCustomer, phone: e.target.value })} />
            <input className="w-full mb-2 p-2 border rounded" placeholder="Address" value={editCustomer.address || ''} onChange={(e) => setEditCustomer({ ...editCustomer, address: e.target.value })} />
            <input className="w-full mb-2 p-2 border rounded" placeholder="New Password (optional)" type="password" value={editPassword} onChange={(e) => setEditPassword(e.target.value)} />
            <select className="w-full mb-2 p-2 border rounded" value={editCustomer.status} onChange={(e) => setEditCustomer({ ...editCustomer, status: e.target.value })}>
              <option value="active">Active</option>
              <option value="block">Blocked</option>
            </select>
            {editError && <div className="text-red-500 mb-2">{editError}</div>}
            <div className="flex gap-2 justify-end">
              <button type="button" className="px-4 py-2 bg-gray-200 rounded" onClick={() => setShowEdit(false)}>Cancel</button>
              <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded">Update</button>
            </div>
          </form>
        </div>
      )}

      <div className="bg-white rounded-xl shadow p-4 overflow-x-auto">
        {loading ? (
          <div className="text-gray-500">Loading customers...</div>
        ) : error ? (
          <div className="text-red-500">{error}</div>
        ) : (
          <table className="min-w-full text-sm">
            <thead>
              <tr className="text-left text-gray-500 border-b">
                <th className="py-2 pr-4">Name</th>
                <th className="py-2 pr-4">Email</th>
                <th className="py-2 pr-4">Phone</th>
                <th className="py-2 pr-4">Address</th>
                <th className="py-2 pr-4">Status</th>
                <th className="py-2">Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredCustomers.map((customer) => (
                <tr key={customer._id} className="border-b hover:bg-gray-50">
                  <td className="py-2 pr-4 font-medium">{customer.name}</td>
                  <td className="py-2 pr-4">{customer.email}</td>
                  <td className="py-2 pr-4">{customer.phone || '-'}</td>
                  <td className="py-2 pr-4">{customer.address || '-'}</td>
                  <td className="py-2 pr-4">
                    <span className={`px-2 py-1 rounded text-xs font-semibold ${customer.status === 'active' ? 'bg-green-100 text-green-700' : 'bg-gray-200 text-gray-500'}`}>
                      {customer.status}
                    </span>
                  </td>
                  <td className="py-2 flex gap-2">
                    <button
                      className={`px-3 py-1 rounded transition ${customer.status === 'active' ? 'bg-gray-200 text-gray-700 hover:bg-gray-300' : 'bg-green-100 text-green-700 hover:bg-green-200'}`}
                      onClick={() => handleStatusToggle(customer)}
                    >
                      {customer.status === 'active' ? 'Deactivate' : 'Activate'}
                    </button>
                    <button
                      className="px-3 py-1 rounded bg-blue-100 text-blue-700 hover:bg-blue-200 transition"
                      onClick={() => handleEditOpen(customer)}
                    >
                      Edit
                    </button>
                    <button
                      className="px-3 py-1 rounded bg-red-100 text-red-700 hover:bg-red-200 transition"
                      onClick={() => handleDelete(customer)}
                    >
                      Delete
                    </button>
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
