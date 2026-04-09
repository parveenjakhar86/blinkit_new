import React, { useState, useEffect } from 'react';
import CustomerView from './customerview/CustomerView';
import AdminLogin from './admin/AdminLogin';
import AdminDashboard from './admin/AdminDashboard';
import UserManagement from './admin/user/UserManagement';
import CustomerManagement from './admin/customer/CustomerManagement';
import OrderManagement from './admin/order/OrderManagement';
import ProductManagement from './admin/product/ProductManagement';
import AdminSidebar from './admin/AdminSidebar';
import UserLogin from './manager/ManagerLogin';
import ManagerDashboard from './manager/ManagerDashboard';
import { clearAuthSession, getAdminToken, getManagerToken } from './utils/auth';

// Main app with customer and admin flows
export default function App() {
  const [adminStep, setAdminStep] = useState('customer'); // 'customer', 'login', 'dashboard', 'user', 'customer-management', 'order', 'product', 'manager-login', 'manager-dashboard'
  const [isAdminLoggedIn, setIsAdminLoggedIn] = useState(false);
  const [isManagerLoggedIn, setIsManagerLoggedIn] = useState(false);

  // Check login on mount
  useEffect(() => {
    const adminToken = getAdminToken();
    setIsAdminLoggedIn(!!adminToken);
    if (adminToken && adminStep === 'login') setAdminStep('dashboard');
    if (!adminToken && ["dashboard", "user", "customer-management"].includes(adminStep)) setAdminStep('login');

    const managerToken = getManagerToken();
    setIsManagerLoggedIn(!!managerToken);
    if (managerToken && adminStep === 'manager-login') setAdminStep('manager-dashboard');
    if (!managerToken && adminStep === 'manager-dashboard') setAdminStep('manager-login');
    if (!adminToken && !managerToken && ["order", "product"].includes(adminStep)) setAdminStep('login');
  }, [adminStep]);

  // Navigation handler for admin dashboard
  const handleAdminNavigate = (section) => setAdminStep(section);
  const handleAdminLogout = () => {
    clearAuthSession();
    setIsAdminLoggedIn(false);
    setIsManagerLoggedIn(false);
    setAdminStep('login');
  };

  const handleManagerLogout = () => {
    clearAuthSession();
    setIsAdminLoggedIn(false);
    setIsManagerLoggedIn(false);
    setAdminStep('manager-login');
  };

  if (adminStep === 'login') return <AdminLogin onLogin={() => { setIsAdminLoggedIn(true); setAdminStep('dashboard'); }} onManagerLogin={() => setAdminStep('manager-login')} />;
  if (adminStep === 'manager-login') return <UserLogin onLogin={() => { setIsManagerLoggedIn(true); setAdminStep('manager-dashboard'); }} onBack={() => setAdminStep('login')} />;

  // Admin pages with sidebar (protected)
  if (["dashboard", "user", "customer-management", "order", "product"].includes(adminStep) && isAdminLoggedIn) {
    let content = null;
    if (adminStep === 'dashboard') content = <AdminDashboard onNavigate={handleAdminNavigate} />;
    if (adminStep === 'user') content = <UserManagement />;
    if (adminStep === 'customer-management') content = <CustomerManagement />;
    if (adminStep === 'order') content = <OrderManagement />;
    if (adminStep === 'product') content = <ProductManagement />;
    return (
      <div className="flex min-h-screen bg-gray-50">
        <AdminSidebar current={adminStep} onNavigate={handleAdminNavigate} onLogout={handleAdminLogout} />
        <div className="flex-1">{content}</div>
      </div>
    );
  }

  if (["order", "product"].includes(adminStep) && isManagerLoggedIn) {
    let content = null;
    if (adminStep === 'order') content = <OrderManagement />;
    if (adminStep === 'product') content = <ProductManagement />;
    return (
      <div className="flex min-h-screen bg-gray-50">
        <AdminSidebar current={adminStep} onNavigate={handleAdminNavigate} onLogout={handleManagerLogout} hideUserManagement={true} hideCustomerManagement={true} />
        <div className="flex-1">{content}</div>
      </div>
    );
  }

  // Manager dashboard (protected, uses AdminDashboard but hides User Management)
  if (adminStep === 'manager-dashboard' && isManagerLoggedIn) {
    return (
      <div className="flex min-h-screen bg-gray-50">
        <AdminSidebar current={adminStep} onNavigate={handleAdminNavigate} onLogout={handleManagerLogout} hideUserManagement={true} hideCustomerManagement={true} />
        <div className="flex-1">
          <AdminDashboard onNavigate={handleAdminNavigate} hideUserManagement={true} />
        </div>
      </div>
    );
  }

  // Show customer view with admin access button in header
  return <CustomerView onAdminLogin={() => setAdminStep('login')} />;
}
