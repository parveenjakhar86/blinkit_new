
import React, { useState, useEffect } from "react";

function toTitleCase(value) {
  if (!value) return "";
  return value.charAt(0).toUpperCase() + value.slice(1);
}

export default function OrderManagement() {
  const [orders, setOrders] = useState([]);
  const [viewOrder, setViewOrder] = useState(null);
  const [editOrder, setEditOrder] = useState(null);
  const [editStatus, setEditStatus] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  // Fetch orders from backend
  useEffect(() => {
    setLoading(true);
    fetch("/api/admin/orders", {
      headers: {
        'Authorization': 'Bearer ' + (localStorage.getItem('adminToken') || localStorage.getItem('managerToken'))
      }
    })
      .then(res => {
        if (!res.ok) {
          return res.json().then(data => {
            throw new Error(data.message || "Failed to fetch orders");
          });
        }
        return res.json();
      })
      .then(data => {
        setOrders(data.map(order => ({
          ...order,
          id: order._id,
          customer: order.user?.username || order.user?.email || 'N/A',
          amount: `Rs ${Number(order.total || order.amount || 0).toFixed(2)}`,
          status: (order.status || 'pending').toLowerCase(),
          date: order.createdAt ? order.createdAt.slice(0, 10) : ''
        })));
        setLoading(false);
      })
      .catch(err => {
        setError(err.message);
        setLoading(false);
      });
  }, []);

  const handleView = (order) => setViewOrder(order);
  const handleUpdate = (order) => {
    setEditOrder(order);
    setEditStatus(order.status);
  };
  const handleUpdateSubmit = (e) => {
    e.preventDefault();
    fetch(`/api/admin/orders/${editOrder.id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + (localStorage.getItem('adminToken') || localStorage.getItem('managerToken'))
      },
      body: JSON.stringify({ status: editStatus })
    })
      .then(res => {
        if (!res.ok) {
          return res.json().then(data => {
            throw new Error(data.message || "Failed to update order");
          });
        }
        return res.json();
      })
      .then(updated => {
        setOrders(orders.map(o => o.id === updated._id ? {
          ...o,
          status: (updated.status || 'pending').toLowerCase()
        } : o));
        setEditOrder(null);
      })
      .catch(err => {
        alert(err.message);
      });
  };

  return (
    <div className="p-8 bg-gray-50 min-h-screen">
      <h2 className="text-2xl font-bold mb-6 text-gray-800">Order Management</h2>
      {/* Search and Filter */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-6 gap-4">
        <input
          type="text"
          placeholder="Search orders..."
          className="w-full sm:w-64 px-4 py-2 border rounded-lg focus:outline-none focus:ring"
        />
        <button className="bg-blue-600 text-white px-5 py-2 rounded-lg font-semibold shadow hover:bg-blue-700 transition">Export</button>
      </div>
      {/* Order Table */}
      <div className="bg-white rounded-xl shadow p-4 overflow-x-auto">
        {loading ? (
          <div className="text-gray-500">Loading orders...</div>
        ) : error ? (
          <div className="text-red-500">{error}</div>
        ) : (
          <table className="min-w-full text-sm">
            <thead>
              <tr className="text-left text-gray-500 border-b">
                <th className="py-2 pr-4">Order ID</th>
                <th className="py-2 pr-4">Customer</th>
                <th className="py-2 pr-4">Amount</th>
                <th className="py-2 pr-4">Status</th>
                <th className="py-2 pr-4">Date</th>
                <th className="py-2">Actions</th>
              </tr>
            </thead>
            <tbody>
              {orders.map((order) => (
                <tr key={order.id} className="border-b hover:bg-gray-50">
                  <td className="py-2 pr-4 font-medium">#{order.id}</td>
                  <td className="py-2 pr-4">{order.customer}</td>
                  <td className="py-2 pr-4">{order.amount}</td>
                  <td className="py-2 pr-4">
                    <span className={`px-2 py-1 rounded text-xs font-semibold ${order.status === "completed" ? "bg-green-100 text-green-700" : order.status === "pending" ? "bg-yellow-100 text-yellow-700" : order.status === "processing" ? "bg-blue-100 text-blue-700" : "bg-red-100 text-red-700"}`}>{toTitleCase(order.status)}</span>
                  </td>
                  <td className="py-2 pr-4">{order.date}</td>
                  <td className="py-2 flex gap-2">
                    <button className="px-3 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition" onClick={() => handleView(order)}>View</button>
                    <button className="px-3 py-1 bg-green-100 text-green-700 rounded hover:bg-green-200 transition" onClick={() => handleUpdate(order)}>Update</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* View Modal */}
      {viewOrder && (
        <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-30 z-50">
          <div className="bg-white p-6 rounded-lg shadow-lg w-full max-w-md">
            <h3 className="text-lg font-bold mb-4">Order Details</h3>
            <div className="mb-2"><b>Order ID:</b> #{viewOrder.id}</div>
            <div className="mb-2"><b>Customer:</b> {viewOrder.customer}</div>
            <div className="mb-2"><b>Amount:</b> {viewOrder.amount}</div>
            <div className="mb-2"><b>Status:</b> {toTitleCase(viewOrder.status)}</div>
            <div className="mb-2"><b>Date:</b> {viewOrder.date}</div>
            <div className="flex gap-2 justify-end mt-4">
              <button className="px-4 py-2 bg-gray-200 rounded" onClick={() => setViewOrder(null)}>Close</button>
            </div>
          </div>
        </div>
      )}

      {/* Update Modal */}
      {editOrder && (
        <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-30 z-50">
          <form onSubmit={handleUpdateSubmit} className="bg-white p-6 rounded-lg shadow-lg w-full max-w-md">
            <h3 className="text-lg font-bold mb-4">Update Order</h3>
            <div className="mb-2"><b>Order ID:</b> #{editOrder.id}</div>
            <div className="mb-2"><b>Customer:</b> {editOrder.customer}</div>
            <div className="mb-2"><b>Amount:</b> {editOrder.amount}</div>
            <div className="mb-2"><b>Date:</b> {editOrder.date}</div>
            <div className="mb-2">
              <b>Status:</b>
              <select className="ml-2 p-1 border rounded" value={editStatus} onChange={e => setEditStatus(e.target.value)}>
                <option value="completed">Completed</option>
                <option value="pending">Pending</option>
                <option value="processing">Processing</option>
                <option value="cancelled">Cancelled</option>
              </select>
            </div>
            <div className="flex gap-2 justify-end mt-4">
              <button type="button" className="px-4 py-2 bg-gray-200 rounded" onClick={() => setEditOrder(null)}>Cancel</button>
              <button type="submit" className="px-4 py-2 bg-green-600 text-white rounded">Update</button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}
