
import React, { useState, useEffect } from "react";
import { getAuthHeaders, getAuthRole } from "../../utils/auth";

function toTitleCase(value) {
  if (!value) return "";
  return value.charAt(0).toUpperCase() + value.slice(1);
}

function formatINR(value) {
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 0
  }).format(Number(value || 0));
}

function inferPinCode(...values) {
  const combinedText = values.map((value) => String(value || '').toLowerCase()).join(' ');

  for (const value of values) {
    const text = String(value || '');
    const match = text.match(/\b\d{6}\b/);
    if (match) {
      return match[0];
    }
  }

  if (combinedText.includes('palwal')) {
    return '121102';
  }

  return '';
}

function inferState(addressText) {
  const text = String(addressText || '').toLowerCase();
  if (!text) return '';

  const keywordMap = [
    ['haryana', ['haryana', 'palwal', 'faridabad', 'gurugram', 'gurgaon', 'panipat', 'rohtak', 'hisar', 'sonipat', 'karnal']],
    ['uttar pradesh', ['uttar pradesh', 'noida', 'greater noida', 'ghaziabad', 'meerut', 'lucknow', 'kanpur']],
    ['delhi', ['delhi', 'new delhi']],
    ['rajasthan', ['rajasthan', 'jaipur', 'jodhpur', 'kota']],
    ['punjab', ['punjab', 'ludhiana', 'amritsar', 'mohali']],
  ];

  for (const [stateName, keywords] of keywordMap) {
    if (keywords.some((keyword) => text.includes(keyword))) {
      return stateName
        .split(' ')
        .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
        .join(' ');
    }
  }

  return '';
}

function normalizeOrder(order) {
  const items = Array.isArray(order.products) ? order.products : [];
  const totalQuantity = items.reduce(
    (sum, item) => sum + Number(item.quantity || 0),
    0,
  );
  const customerDetails = order.customerDetails || {};
  const sourceAddressText = [
    customerDetails.fullAddress,
    customerDetails.address,
    order.address,
    order.deliveryAddress,
  ].filter(Boolean).join(', ');
  const address =
    customerDetails.address ||
    order.address ||
    order.deliveryAddress ||
    '';
  const state =
    customerDetails.state ||
    order.state ||
    order.deliveryState ||
    inferState(sourceAddressText);
  const pinCode =
    customerDetails.pinCode ||
    order.pinCode ||
    order.deliveryPinCode ||
    inferPinCode(sourceAddressText);
  const addressParts = [
    address,
    state,
    pinCode,
  ].filter((value) => String(value || '').trim());

  return {
    ...order,
    id: order._id,
    customer:
      order.customerDetails?.name ||
      order.user?.username ||
      order.user?.email ||
      "Guest",
    amount: formatINR(order.total || order.totalAmount || order.amount || 0),
    status: (order.status || "pending").toLowerCase(),
    date: order.createdAt ? order.createdAt.slice(0, 10) : "",
    customerDetails: {
      ...customerDetails,
      address,
      state,
      pinCode,
      fullAddress: customerDetails.fullAddress || addressParts.join(', '),
    },
    items,
    totalQuantity,
    primaryImage:
      items[0]?.product?.image ||
      order.customerDetails?.image ||
      "",
  };
}

function stopRowClick(handler) {
  return (event) => {
    event.stopPropagation();
    handler();
  };
}

export default function OrderManagement() {
  const [orders, setOrders] = useState([]);
  const [viewOrder, setViewOrder] = useState(null);
  const [editOrder, setEditOrder] = useState(null);
  const [editStatus, setEditStatus] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const role = getAuthRole();

  // Fetch orders from backend
  useEffect(() => {
    setLoading(true);
    fetch("/api/admin/orders", {
      headers: getAuthHeaders(role)
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
        setOrders(data.map(normalizeOrder));
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
        ...getAuthHeaders(role)
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
        const normalized = normalizeOrder(updated);
        setOrders(orders.map(o => o.id === updated._id ? normalized : o));
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
                <th className="py-2 pr-4">Image</th>
                <th className="py-2 pr-4">Products</th>
                <th className="py-2 pr-4">Quantity</th>
                <th className="py-2 pr-4 min-w-[260px]">Complete Address</th>
                <th className="py-2 pr-4">State</th>
                <th className="py-2 pr-4">Pin Code</th>
                <th className="py-2 pr-4">Amount</th>
                <th className="py-2 pr-4">Status</th>
                <th className="py-2 pr-4">Date</th>
                <th className="py-2">Actions</th>
              </tr>
            </thead>
            <tbody>
              {orders.map((order) => (
                <tr
                  key={order.id}
                  className="cursor-pointer border-b hover:bg-gray-50"
                  onClick={() => handleView(order)}
                >
                  <td className="py-2 pr-4 font-medium">#{order.id}</td>
                  <td className="py-2 pr-4">{order.customer}</td>
                  <td className="py-2 pr-4">
                    {order.primaryImage ? (
                      <img
                        src={order.primaryImage}
                        alt={order.items[0]?.name || "Product"}
                        className="w-12 h-12 rounded object-cover border"
                      />
                    ) : (
                      <span className="text-gray-400">No image</span>
                    )}
                  </td>
                  <td className="py-2 pr-4">
                    <div className="max-w-xs space-y-1">
                      {order.items.length ? (
                        order.items.map((item, index) => (
                          <div key={`${order.id}-${index}`} className="truncate text-gray-700">
                            {item.name || item.product?.name || "Unnamed product"}
                          </div>
                        ))
                      ) : (
                        <span className="text-gray-400">No products</span>
                      )}
                    </div>
                  </td>
                  <td className="py-2 pr-4">{order.totalQuantity || "-"}</td>
                  <td className="py-2 pr-4">
                    <div className="max-w-sm whitespace-normal break-words leading-5 text-gray-700">
                      {order.customerDetails?.fullAddress || order.customerDetails?.address || "-"}
                    </div>
                  </td>
                  <td className="py-2 pr-4 font-medium text-gray-700">{order.customerDetails?.state || "-"}</td>
                  <td className="py-2 pr-4 font-medium text-gray-700">{order.customerDetails?.pinCode || "-"}</td>
                  <td className="py-2 pr-4">{order.amount}</td>
                  <td className="py-2 pr-4">
                    <span className={`px-2 py-1 rounded text-xs font-semibold ${order.status === "completed" ? "bg-green-100 text-green-700" : order.status === "pending" ? "bg-yellow-100 text-yellow-700" : order.status === "processing" ? "bg-blue-100 text-blue-700" : "bg-red-100 text-red-700"}`}>{toTitleCase(order.status)}</span>
                  </td>
                  <td className="py-2 pr-4">{order.date}</td>
                  <td className="py-2 flex gap-2">
                    <button
                      className="px-3 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition"
                      onClick={stopRowClick(() => handleView(order))}
                    >
                      View
                    </button>
                    <button
                      className="px-3 py-1 bg-green-100 text-green-700 rounded hover:bg-green-200 transition"
                      onClick={stopRowClick(() => handleUpdate(order))}
                    >
                      Update
                    </button>
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
          <div className="bg-white p-6 rounded-lg shadow-lg w-full max-w-2xl max-h-[85vh] overflow-y-auto">
            <h3 className="text-lg font-bold mb-4">Order Details</h3>
            <div className="grid gap-4 rounded-xl bg-gray-50 p-4 md:grid-cols-[120px_1fr]">
              <div className="flex items-start justify-center">
                {viewOrder.primaryImage ? (
                  <img
                    src={viewOrder.primaryImage}
                    alt={viewOrder.items[0]?.name || "Ordered product"}
                    className="h-28 w-28 rounded-xl border object-cover bg-white"
                  />
                ) : (
                  <div className="flex h-28 w-28 items-center justify-center rounded-xl border bg-white text-sm text-gray-400">
                    No image
                  </div>
                )}
              </div>
              <div className="grid gap-2 text-sm text-gray-700 md:grid-cols-2">
                <div><b>Order ID:</b> #{viewOrder.id}</div>
                <div><b>Customer:</b> {viewOrder.customer}</div>
                <div><b>Phone:</b> {viewOrder.customerDetails?.phone || "-"}</div>
                <div><b>Amount:</b> {viewOrder.amount}</div>
                <div><b>Status:</b> {toTitleCase(viewOrder.status)}</div>
                <div><b>Date:</b> {viewOrder.date}</div>
                <div><b>State:</b> {viewOrder.customerDetails?.state || "-"}</div>
                <div><b>Pin Code:</b> {viewOrder.customerDetails?.pinCode || "-"}</div>
                <div className="md:col-span-2"><b>Complete Address:</b> {viewOrder.customerDetails?.fullAddress || "-"}</div>
              </div>
            </div>
            <div className="mt-4">
              <b>Products:</b>
              <div className="mt-2 overflow-hidden rounded-lg border border-gray-200">
                <table className="min-w-full text-sm">
                  <thead className="bg-gray-50 text-left text-gray-500">
                    <tr>
                      <th className="px-3 py-2">Image</th>
                      <th className="px-3 py-2">Product Name</th>
                      <th className="px-3 py-2">Quantity</th>
                      <th className="px-3 py-2">Price</th>
                    </tr>
                  </thead>
                  <tbody>
                    {viewOrder.items.length ? (
                      viewOrder.items.map((item, index) => (
                        <tr key={`${viewOrder.id}-item-${index}`} className="border-t">
                          <td className="px-3 py-2">
                            {item.product?.image ? (
                              <img
                                src={item.product.image}
                                alt={item.name || item.product?.name || "Product"}
                                className="w-12 h-12 rounded object-cover border"
                              />
                            ) : (
                              <span className="text-gray-400">No image</span>
                            )}
                          </td>
                          <td className="px-3 py-2">{item.name || item.product?.name || "Unnamed product"}</td>
                          <td className="px-3 py-2">{item.quantity || 0}</td>
                          <td className="px-3 py-2">{formatINR(item.price || item.product?.price || 0)}</td>
                        </tr>
                      ))
                    ) : (
                      <tr>
                        <td className="px-3 py-3 text-gray-400" colSpan="4">No products found for this order.</td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
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
            <div className="mb-2"><b>Quantity:</b> {editOrder.totalQuantity || "-"}</div>
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
