
import React, { useEffect, useMemo, useState } from "react";

const formatINR = (amount) =>
  new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 0
  }).format(Number(amount || 0));

export default function AdminDashboard() {
  const [orders, setOrders] = useState([]);
  const [productsCount, setProductsCount] = useState(0);
  const [usersCount, setUsersCount] = useState(0);
  const [loading, setLoading] = useState(true);

  const token = localStorage.getItem("adminToken") || localStorage.getItem("managerToken");

  useEffect(() => {
    const load = async () => {
      setLoading(true);
      try {
        const [orderRes, productRes, userRes] = await Promise.all([
          fetch("/api/admin/orders", { headers: { Authorization: `Bearer ${token}` } }),
          fetch("/api/admin/products", { headers: { Authorization: `Bearer ${token}` } }),
          fetch("/api/admin/users", { headers: { Authorization: `Bearer ${token}` } })
        ]);

        const orderData = orderRes.ok ? await orderRes.json() : [];
        const productData = productRes.ok ? await productRes.json() : [];
        const userData = userRes.ok ? await userRes.json() : [];

        setOrders(Array.isArray(orderData) ? orderData : []);
        setProductsCount(Array.isArray(productData) ? productData.length : 0);
        setUsersCount(Array.isArray(userData) ? userData.length : 0);
      } finally {
        setLoading(false);
      }
    };

    load();
  }, [token]);

  const stats = useMemo(() => {
    const today = new Date();
    const todayOrders = orders.filter((order) => {
      const date = new Date(order.createdAt);
      return (
        date.getDate() === today.getDate() &&
        date.getMonth() === today.getMonth() &&
        date.getFullYear() === today.getFullYear()
      );
    }).length;

    const revenue = orders.reduce((sum, order) => sum + Number(order.total || order.totalAmount || 0), 0);

    return [
      { label: "Total Users", value: usersCount, icon: "👤", color: "bg-blue-100 text-blue-700" },
      { label: "Orders Today", value: todayOrders, icon: "🛒", color: "bg-green-100 text-green-700" },
      { label: "Revenue", value: formatINR(revenue), icon: "💰", color: "bg-yellow-100 text-yellow-700" },
      { label: "Products", value: productsCount, icon: "📦", color: "bg-purple-100 text-purple-700" }
    ];
  }, [orders, productsCount, usersCount]);

  const recentOrders = orders.slice(0, 6);

  return (
    <div className="p-8 bg-gray-50 min-h-screen">
      <h1 className="text-3xl font-bold mb-8 text-gray-800">Dashboard</h1>
      {/* Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {stats.map((stat) => (
          <div
            key={stat.label}
            className={`flex items-center p-5 rounded-xl shadow-sm ${stat.color} transition-transform hover:scale-105`}
          >
            <span className="text-3xl mr-4">{stat.icon}</span>
            <div>
              <div className="text-xl font-semibold">{stat.value}</div>
              <div className="text-sm text-gray-600">{stat.label}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Summary & Chart Section */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Orders Summary */}
        <div className="col-span-2 bg-white rounded-xl shadow p-6">
          <h2 className="text-lg font-bold mb-4 text-gray-700">Recent Orders</h2>
          <div className="overflow-x-auto">
            {loading ? (
              <div className="text-gray-500">Loading dashboard...</div>
            ) : (
              <table className="min-w-full text-sm">
                <thead>
                  <tr className="text-left text-gray-500 border-b">
                    <th className="py-2 pr-4">Order ID</th>
                    <th className="py-2 pr-4">Customer</th>
                    <th className="py-2 pr-4">Amount</th>
                    <th className="py-2 pr-4">Status</th>
                    <th className="py-2">Date</th>
                  </tr>
                </thead>
                <tbody>
                  {recentOrders.map((order) => (
                    <tr key={order._id} className="border-b">
                      <td className="py-2 pr-4">#{order._id?.slice(-6)}</td>
                      <td className="py-2 pr-4">{order.customerDetails?.name || order.user?.username || order.user?.email || "Guest"}</td>
                      <td className="py-2 pr-4">{formatINR(order.total || order.totalAmount || 0)}</td>
                      <td className="py-2 pr-4">
                        <span className={`px-2 py-1 rounded ${order.status === "completed" ? "bg-green-100 text-green-700" : order.status === "pending" ? "bg-yellow-100 text-yellow-700" : "bg-gray-100 text-gray-700"}`}>
                          {order.status}
                        </span>
                      </td>
                      <td className="py-2">{order.createdAt ? new Date(order.createdAt).toLocaleDateString("en-IN") : "-"}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>

        {/* Chart Placeholder */}
        <div className="bg-white rounded-xl shadow p-6 flex flex-col items-center justify-center">
          <h2 className="text-lg font-bold mb-4 text-gray-700">Sales Overview</h2>
          <div className="w-full h-40 flex items-center justify-center text-gray-400">
            {/* Replace with chart component */}
            <span>Chart coming soon...</span>
          </div>
        </div>
      </div>
    </div>
  );
}
