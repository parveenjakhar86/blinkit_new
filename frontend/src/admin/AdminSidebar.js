import React from 'react';
// You can use Heroicons or SVGs for icons. Here, we'll use emoji placeholders for simplicity.
const navItems = [
  { key: 'dashboard', label: 'Dashboard', icon: '🏠' },
  { key: 'user', label: 'User Management', icon: '👤' },
  { key: 'customer-management', label: 'Customer Management', icon: '🧑' },
  { key: 'order', label: 'Order Management', icon: '📦' },
  { key: 'product', label: 'Product Management', icon: '🛒' },
];

export default function AdminSidebar({ current, onNavigate, onLogout, hideUserManagement, hideCustomerManagement }) {
  return (
    <aside className="h-screen w-64 bg-white shadow-lg flex flex-col py-8 px-0 border-r border-gray-100">
      <div className="flex items-center justify-center mb-10">
        <span className="text-3xl font-bold text-green-600">Admin</span>
      </div>
      <nav className="flex flex-col gap-2">
        {navItems
          .filter(item => !(hideUserManagement && item.key === 'user'))
          .filter(item => !(hideCustomerManagement && item.key === 'customer-management'))
          .map(item => (
          <button
            key={item.key}
            className={`flex items-center gap-3 px-8 py-3 text-lg rounded-l-full font-medium transition-all duration-150 ${current === item.key ? 'bg-green-100 text-green-700 border-l-4 border-green-500 shadow' : 'hover:bg-gray-100 text-gray-700'}`}
            onClick={() => onNavigate(item.key)}
          >
            <span className="text-xl">{item.icon}</span>
            {item.label}
          </button>
        ))}
      </nav>
      <div className="flex-1" />
      <button
        className="mx-8 mb-4 px-4 py-2 bg-red-100 text-red-700 rounded-lg font-semibold hover:bg-red-200 transition"
        onClick={onLogout}
      >Logout</button>
    </aside>
  );
}
