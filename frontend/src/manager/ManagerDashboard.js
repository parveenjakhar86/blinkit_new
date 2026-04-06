import React from 'react';

// Simple manager dashboard for product/order management
export default function ManagerDashboard() {
  return (
    <div className="min-h-screen bg-gray-50 p-8">
      <h1 className="text-3xl font-bold mb-8 text-blue-800">Manager Dashboard</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        <a href="/manager/products" className="bg-white p-6 rounded-lg shadow hover:shadow-lg text-lg font-semibold text-blue-700 border border-blue-200 hover:bg-blue-50 block text-center">Product Management</a>
        <a href="/manager/orders" className="bg-white p-6 rounded-lg shadow hover:shadow-lg text-lg font-semibold text-green-700 border border-green-200 hover:bg-green-50 block text-center">Order Management</a>
      </div>
    </div>
  );
}
