
import React, { useEffect, useState } from "react";
import { getAdminToken } from "../../utils/auth";

export default function UserManagement() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [showAdd, setShowAdd] = useState(false);
  const [newUser, setNewUser] = useState({ username: '', email: '', role: 'staff', password: '', status: 'active' });
  const [addError, setAddError] = useState('');
  const [showEdit, setShowEdit] = useState(false);
  const [editUser, setEditUser] = useState(null);
  const [editError, setEditError] = useState('');
  const [editPassword, setEditPassword] = useState('');
  const adminToken = getAdminToken();

  const fetchUsers = () => {
    if (!adminToken) {
      setError('Admin login required');
      setLoading(false);
      return;
    }

    setLoading(true);
    fetch("/api/admin/users", {
      headers: {
        'Authorization': 'Bearer ' + adminToken
      }
    })
      .then((res) => {
        if (!res.ok) throw new Error("Failed to fetch users");
        return res.json();
      })
      .then((data) => {
        setUsers(data);
        setLoading(false);
      })
      .catch((err) => {
        setError(err.message);
        setLoading(false);
      });
  }
  useEffect(() => {
    fetchUsers();
  }, []);

  // Change status handler
  const handleStatusChange = (user) => {
    const newStatus = user.status === 'active' ? 'block' : 'active';
    fetch(`/api/admin/users/${user._id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + adminToken
      },
      body: JSON.stringify({ status: newStatus })
    })
      .then(res => res.json())
      .then(() => fetchUsers());
  };

  // Add user handler
  const handleAddUser = (e) => {
    e.preventDefault();
    setAddError('');
    fetch('/api/admin/users', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + adminToken
      },
      body: JSON.stringify(newUser)
    })
      .then(async res => {
        if (!res.ok) {
          const data = await res.json();
          throw new Error(data.message || 'Failed to add user');
        }
        return res.json();
      })
      .then(() => {
        setShowAdd(false);
        setNewUser({ username: '', email: '', role: 'staff', password: '', status: 'active' });
        fetchUsers();
      })
      .catch(err => setAddError(err.message));
  };

  // Edit user handler (stub)
  const handleEditUser = (user) => {
    setEditUser({ ...user });
    setEditPassword('');
    setEditError('');
    setShowEdit(true);
  };

  const handleEditUserSubmit = (e) => {
    e.preventDefault();
    setEditError('');
    const updateData = { ...editUser };
    if (editPassword) {
      updateData.password = editPassword;
    }
    fetch(`/api/admin/users/${editUser._id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + adminToken
      },
      body: JSON.stringify(updateData)
    })
      .then(async res => {
        if (!res.ok) {
          const data = await res.json();
          throw new Error(data.message || 'Failed to update user');
        }
        return res.json();
      })
      .then(() => {
        setShowEdit(false);
        setEditUser(null);
        setEditPassword('');
        fetchUsers();
      })
      .catch(err => setEditError(err.message));
  };

  // Delete user handler
  const handleDeleteUser = (user) => {
    if (!window.confirm(`Are you sure you want to delete user ${user.username}?`)) return;
    fetch(`/api/admin/users/${user._id}`, {
      method: 'DELETE',
      headers: {
        'Authorization': 'Bearer ' + adminToken
      }
    })
      .then(res => res.json())
      .then(() => fetchUsers());
  };

  return (
    <div className="p-8 bg-gray-50 min-h-screen">
      <h2 className="text-2xl font-bold mb-6 text-gray-800">User Management</h2>
      {/* Search and Add User */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-6 gap-4">
        <input
          type="text"
          placeholder="Search users..."
          className="w-full sm:w-64 px-4 py-2 border rounded-lg focus:outline-none focus:ring"
        />
        <button
          className="bg-green-600 text-white px-5 py-2 rounded-lg font-semibold shadow hover:bg-green-700 transition"
          onClick={() => setShowAdd(true)}
        >+ Add User</button>
      </div>

      {/* Add User Modal */}
      {showAdd && (
        <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-30 z-50">
          <form onSubmit={handleAddUser} className="bg-white p-6 rounded-lg shadow-lg w-full max-w-md">
            <h3 className="text-lg font-bold mb-4">Add User</h3>
            <input className="w-full mb-2 p-2 border rounded" placeholder="Username" value={newUser.username} onChange={e => setNewUser({ ...newUser, username: e.target.value })} required />
            <input className="w-full mb-2 p-2 border rounded" placeholder="Email" type="email" value={newUser.email} onChange={e => setNewUser({ ...newUser, email: e.target.value })} required />
            <input className="w-full mb-2 p-2 border rounded" placeholder="Password" type="password" value={newUser.password} onChange={e => setNewUser({ ...newUser, password: e.target.value })} required />
            <select className="w-full mb-2 p-2 border rounded" value={newUser.role} onChange={e => setNewUser({ ...newUser, role: e.target.value })}>
              <option value="admin">Admin</option>
              <option value="manager">Manager</option>
              <option value="staff">Staff</option>
            </select>
            <select className="w-full mb-2 p-2 border rounded" value={newUser.status} onChange={e => setNewUser({ ...newUser, status: e.target.value })}>
              <option value="active">Active</option>
              <option value="block">Inactive</option>
            </select>
            {addError && <div className="text-red-500 mb-2">{addError}</div>}
            <div className="flex gap-2 justify-end">
              <button type="button" className="px-4 py-2 bg-gray-200 rounded" onClick={() => setShowAdd(false)}>Cancel</button>
              <button type="submit" className="px-4 py-2 bg-green-600 text-white rounded">Add</button>
            </div>
          </form>
        </div>
      )}
      {/* Edit User Modal */}
      {showEdit && editUser && (
        <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-30 z-50">
          <form onSubmit={handleEditUserSubmit} className="bg-white p-6 rounded-lg shadow-lg w-full max-w-md">
            <h3 className="text-lg font-bold mb-4">Edit User</h3>
            <input className="w-full mb-2 p-2 border rounded" placeholder="Username" value={editUser.username} onChange={e => setEditUser({ ...editUser, username: e.target.value })} required />
            <input className="w-full mb-2 p-2 border rounded" placeholder="Email" type="email" value={editUser.email} onChange={e => setEditUser({ ...editUser, email: e.target.value })} required />
            <input className="w-full mb-2 p-2 border rounded" placeholder="New Password (leave blank to keep current)" type="password" value={editPassword} onChange={e => setEditPassword(e.target.value)} />
            <select className="w-full mb-2 p-2 border rounded" value={editUser.role} onChange={e => setEditUser({ ...editUser, role: e.target.value })}>
              <option value="admin">Admin</option>
              <option value="manager">Manager</option>
              <option value="staff">Staff</option>
            </select>
            <select className="w-full mb-2 p-2 border rounded" value={editUser.status} onChange={e => setEditUser({ ...editUser, status: e.target.value })}>
              <option value="active">Active</option>
              <option value="block">Inactive</option>
            </select>
            {editError && <div className="text-red-500 mb-2">{editError}</div>}
            <div className="flex gap-2 justify-end">
              <button type="button" className="px-4 py-2 bg-gray-200 rounded" onClick={() => setShowEdit(false)}>Cancel</button>
              <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded">Update</button>
            </div>
          </form>
        </div>
      )}
      {/* User Table */}
      <div className="bg-white rounded-xl shadow p-4 overflow-x-auto">
        {loading ? (
          <div className="text-gray-500">Loading users...</div>
        ) : error ? (
          <div className="text-red-500">{error}</div>
        ) : (
          <table className="min-w-full text-sm">
            <thead>
              <tr className="text-left text-gray-500 border-b">
                <th className="py-2 pr-4">Username</th>
                <th className="py-2 pr-4">Email</th>
                <th className="py-2 pr-4">Role</th>
                <th className="py-2 pr-4">Status</th>
                <th className="py-2">Actions</th>
              </tr>
            </thead>
            <tbody>
              {users.map((user) => (
                <tr key={user._id} className="border-b hover:bg-gray-50">
                  <td className="py-2 pr-4 font-medium">{user.username}</td>
                  <td className="py-2 pr-4">{user.email}</td>
                  <td className="py-2 pr-4">{user.role}</td>
                  <td className="py-2 pr-4">
                    <span className={`px-2 py-1 rounded text-xs font-semibold ${user.status === "active" ? "bg-green-100 text-green-700" : "bg-gray-200 text-gray-500"}`}>{user.status}</span>
                  </td>
                  <td className="py-2 flex gap-2">
                    <button
                      className={`px-3 py-1 rounded transition ${user.status === 'active' ? 'bg-gray-200 text-gray-700 hover:bg-gray-300' : 'bg-green-100 text-green-700 hover:bg-green-200'}`}
                      onClick={() => handleStatusChange(user)}
                    >{user.status === 'active' ? 'Deactivate' : 'Activate'}</button>
                    <button
                      className="px-3 py-1 rounded bg-blue-100 text-blue-700 hover:bg-blue-200 transition"
                      onClick={() => handleEditUser(user)}
                    >Edit</button>
                    <button
                      className="px-3 py-1 rounded bg-red-100 text-red-700 hover:bg-red-200 transition"
                      onClick={() => handleDeleteUser(user)}
                    >Delete</button>
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
