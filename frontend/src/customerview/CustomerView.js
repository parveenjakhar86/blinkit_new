
import React, { useMemo, useState } from 'react';
import searchIcon from '../search.svg';
import CartDrawer from './CartDrawer';

const formatINR = (amount) =>
  new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(amount);

const categories = [
  { id: 1, name: 'Masala, Oil & More', image: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&w=240&q=80' },
  { id: 2, name: 'Sauces & Spreads', image: 'https://images.unsplash.com/photo-1606761568499-6d2451b23c66?auto=format&fit=crop&w=240&q=80' },
  { id: 3, name: 'Chicken, Meat & Fish', image: 'https://images.unsplash.com/photo-1603048297172-c92544798d5a?auto=format&fit=crop&w=240&q=80' },
  { id: 4, name: 'Organic & Healthy Living', image: 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?auto=format&fit=crop&w=240&q=80' },
  { id: 5, name: 'Baby Care', image: 'https://images.unsplash.com/photo-1608889825103-eb5ed706fc64?auto=format&fit=crop&w=240&q=80' },
  { id: 6, name: 'Pharma & Wellness', image: 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=240&q=80' },
  { id: 7, name: 'Cleaning Essentials', image: 'https://images.unsplash.com/photo-1563453392212-326f5e854473?auto=format&fit=crop&w=240&q=80' },
  { id: 8, name: 'Home & Office', image: 'https://images.unsplash.com/photo-1583947215259-38e31be8751f?auto=format&fit=crop&w=240&q=80' },
  { id: 9, name: 'Personal Care', image: 'https://images.unsplash.com/photo-1571781418606-70265b9cce90?auto=format&fit=crop&w=240&q=80' },
  { id: 10, name: 'Pet Care', image: 'https://images.unsplash.com/photo-1516734212186-a967f81ad0d7?auto=format&fit=crop&w=240&q=80' },
];

const products = [
  { id: 1, name: 'Amul Gold Full Cream Milk', price: 35, originalPrice: 38, image: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=600&q=80', delivery: '14 MINS', volume: '500 ml', section: 'Dairy, Bread & Eggs' },
  { id: 2, name: 'Amul Masti Pouch Curd', price: 35, originalPrice: 42, image: 'https://images.unsplash.com/photo-1488477304112-4944851de03d?auto=format&fit=crop&w=600&q=80', delivery: '14 MINS', volume: '390 g', section: 'Dairy, Bread & Eggs' },
  { id: 3, name: 'Amul Salted Butter', price: 58, originalPrice: 65, image: 'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?auto=format&fit=crop&w=600&q=80', delivery: '14 MINS', volume: '100 g', section: 'Dairy, Bread & Eggs' },
  { id: 4, name: 'Amul Masti Curd', price: 77, originalPrice: 90, image: 'https://images.unsplash.com/photo-1488477304112-4944851de03d?auto=format&fit=crop&w=600&q=80', delivery: '14 MINS', volume: '1 kg', section: 'Dairy, Bread & Eggs' },
  { id: 5, name: 'English Oven Premium White Bread', price: 60, originalPrice: 70, image: 'https://images.unsplash.com/photo-1608198093002-ad4e005484ec?auto=format&fit=crop&w=600&q=80', delivery: '14 MINS', volume: '700 g', section: 'Dairy, Bread & Eggs' },
  { id: 6, name: 'Amul Taaza Toned Milk', price: 29, originalPrice: 34, image: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=600&q=80', delivery: '14 MINS', volume: '500 ml', section: 'Dairy, Bread & Eggs' },
  { id: 7, name: 'Fresh Tomatoes', price: 34, originalPrice: 42, image: 'https://images.unsplash.com/photo-1546094096-0df4bcaaa337?auto=format&fit=crop&w=600&q=80', delivery: '11 MINS', volume: '1 kg', section: 'Daily Fresh' },
  { id: 8, name: 'Fresh Bananas', price: 45, originalPrice: 55, image: 'https://images.unsplash.com/photo-1574226516831-e1dff420e43e?auto=format&fit=crop&w=600&q=80', delivery: '11 MINS', volume: '1 dozen', section: 'Daily Fresh' },
  { id: 9, name: 'Farm Fresh Eggs', price: 92, originalPrice: 110, image: 'https://images.unsplash.com/photo-1518492104633-130d0cc84637?auto=format&fit=crop&w=600&q=80', delivery: '12 MINS', volume: '12 pcs', section: 'Daily Fresh' },
  { id: 10, name: 'Tata Tea Gold', price: 178, originalPrice: 210, image: 'https://images.unsplash.com/photo-1597318181409-cf64d0b5d8a2?auto=format&fit=crop&w=600&q=80', delivery: '12 MINS', volume: '500 g', section: 'Tea, Coffee & More' },
];

const sectionOrder = ['Dairy, Bread & Eggs', 'Daily Fresh', 'Tea, Coffee & More'];

export default function CustomerView({ onAdminLogin }) {
  const [cart, setCart] = useState([]);
  const [search, setSearch] = useState('');
  const [cartOpen, setCartOpen] = useState(false);
  const [customerProfile, setCustomerProfile] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem('customerProfile') || 'null');
    } catch {
      return null;
    }
  });

  const addToCart = (product) => {
    setCart((prev) => [...prev, product]);
  };

  const filteredProducts = useMemo(
    () => products.filter((product) => product.name.toLowerCase().includes(search.toLowerCase())),
    [search]
  );

  const handleCartCheckout = async (orderPayload) => {

    const res = await fetch('/api/orders/place', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(orderPayload)
    });

    const data = await res.json();
    if (!res.ok) {
      throw new Error(data.message || 'Failed to place order');
    }

    setCart([]);
    alert('Order placed successfully');
  };

  return (
    <div style={{ minHeight: '100vh', background: '#f6f7f9', fontFamily: 'Poppins, sans-serif', fontWeight: 400 }}>
      <header style={{ position: 'sticky', top: 0, zIndex: 40, background: '#fff', borderBottom: '1px solid #e5e7eb', display: 'flex', alignItems: 'center', gap: 14, padding: '10px 18px', flexWrap: 'wrap' }}>
        <span style={{ color: '#22c55e', fontWeight: 500, fontSize: 'clamp(20px, 2vw, 24px)', letterSpacing: '-0.5px' }}>blinkit</span>
        <div style={{ minWidth: 180, display: 'flex', flexDirection: 'column' }}>
          <span style={{ fontSize: 13, fontWeight: 400, lineHeight: 1.1 }}>Delivery in 14 minutes</span>
          <span style={{ fontSize: 11, color: '#6b7280', lineHeight: 1.3 }}>Parveen Jakhar, Home</span>
        </div>
        <div style={{ position: 'relative', flex: 1, minWidth: 220, maxWidth: 720 }}>
          <input
            type="text"
            placeholder="Search 'milk', 'bread', 'eggs'"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            style={{ width: '100%', border: '1px solid #e5e7eb', borderRadius: 10, padding: '11px 42px 11px 16px', background: '#f9fafb', fontSize: 13, outline: 'none' }}
          />
          <img src={searchIcon} alt="search" style={{ position: 'absolute', right: 14, top: '50%', transform: 'translateY(-50%)', width: 20, height: 20, opacity: 0.55 }} />
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <button
            style={{ border: 'none', background: '#111827', color: '#fff', borderRadius: 8, padding: '9px 13px', minWidth: 90, fontWeight: 400, fontSize: 13, cursor: 'pointer' }}
            onClick={onAdminLogin}
          >
            Admin
          </button>
          <button
            style={{ border: 'none', background: '#16a34a', color: '#fff', borderRadius: 8, padding: '9px 13px', minWidth: 90, fontWeight: 400, fontSize: 13, cursor: 'pointer' }}
            onClick={() => setCartOpen(true)}
          >
            Cart {cart.length > 0 ? `(${cart.length})` : ''}
          </button>
        </div>
      </header>

      <main style={{ maxWidth: 1520, margin: '0 auto', padding: '14px 16px 34px' }}>
        <div style={{ display: 'flex', gap: 22, overflowX: 'auto', paddingBottom: 10, marginBottom: 10, scrollbarWidth: 'thin' }}>
          {categories.map((category) => (
            <div key={category.id} style={{ minWidth: 118, textAlign: 'center', flexShrink: 0 }}>
              <img src={category.image} alt={category.name} style={{ width: 86, height: 86, borderRadius: 12, objectFit: 'cover', border: '1px solid #e5e7eb', background: '#fff', marginBottom: 8 }} />
              <div style={{ fontWeight: 400, fontSize: 12, color: '#374151', lineHeight: 1.25 }}>{category.name}</div>
            </div>
          ))}
        </div>

        {sectionOrder.map((section) => {
          const sectionItems = filteredProducts.filter((product) => product.section === section);
          if (!sectionItems.length) {
            return null;
          }

          return (
            <section key={section} style={{ marginTop: 18 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12, gap: 10 }}>
                <h2 style={{ fontWeight: 500, fontSize: 'clamp(20px, 2.5vw, 30px)', lineHeight: 1.1 }}>{section}</h2>
                <span style={{ color: '#16a34a', fontWeight: 400, fontSize: 'clamp(14px, 1.6vw, 16px)', cursor: 'pointer', whiteSpace: 'nowrap' }}>see all</span>
              </div>
              <div style={{ display: 'flex', gap: 14, overflowX: 'auto', paddingBottom: 6, scrollbarWidth: 'thin' }}>
                {sectionItems.map((product) => (
                  <article key={product.id} style={{ width: 'clamp(170px, 24vw, 210px)', flexShrink: 0, borderRadius: 12, border: '1px solid #e5e7eb', background: '#fff', padding: 12, display: 'flex', flexDirection: 'column' }}>
                    <img src={product.image} alt={product.name} style={{ width: '100%', height: 140, objectFit: 'contain', marginBottom: 8 }} />
                    <div style={{ fontSize: 10, fontWeight: 400, color: '#374151', marginBottom: 8 }}>{product.delivery}</div>
                    <div style={{ fontSize: 'clamp(14px, 1.5vw, 18px)', fontWeight: 400, lineHeight: 1.2, minHeight: 50, marginBottom: 6 }}>{product.name}</div>
                    <div style={{ fontSize: 'clamp(12px, 1.4vw, 14px)', color: '#6b7280', marginBottom: 14 }}>{product.volume}</div>
                    <div style={{ marginTop: 'auto', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                      <div style={{ fontWeight: 500, fontSize: 'clamp(15px, 1.8vw, 18px)' }}>{formatINR(product.price)}</div>
                      <button
                        onClick={() => addToCart(product)}
                        style={{ border: '1px solid #16a34a', color: '#16a34a', borderRadius: 8, padding: '6px 18px', fontWeight: 500, fontSize: 12, background: '#f0fdf4', cursor: 'pointer' }}
                      >
                        ADD
                      </button>
                    </div>
                  </article>
                ))}
              </div>
            </section>
          );
        })}
      </main>

      {cartOpen && (
        <CartDrawer
          cart={cart}
          onClose={() => setCartOpen(false)}
          onCheckout={handleCartCheckout}
          customerProfile={customerProfile}
        />
      )}
    </div>
  );
}
