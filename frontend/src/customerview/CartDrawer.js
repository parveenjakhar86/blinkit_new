import { useEffect, useState } from 'react';

function toDataUrl(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = () => reject(new Error('Failed to read image file'));
    reader.readAsDataURL(file);
  });
}

export default function CartDrawer({ cart, onClose, onCheckout, customerProfile }) {
  const [showCheckoutForm, setShowCheckoutForm] = useState(false);
  const [placing, setPlacing] = useState(false);
  const [formError, setFormError] = useState('');
  const [checkoutData, setCheckoutData] = useState({
    name: '',
    email: '',
    phone: '',
    address: '',
    image: '',
    paymentMethod: 'upi'
  });

  useEffect(() => {
    if (!customerProfile) return;
    setCheckoutData((prev) => ({
      ...prev,
      name: customerProfile.name || customerProfile.username || prev.name,
      email: customerProfile.email || prev.email,
      phone: customerProfile.phone || prev.phone,
      address: customerProfile.address || prev.address,
      image: customerProfile.image || prev.image
    }));
  }, [customerProfile]);

  const formatINR = (amount) =>
    new Intl.NumberFormat('en-IN', {
      style: 'currency',
      currency: 'INR',
      maximumFractionDigits: 0
    }).format(amount);

  const itemsTotal = cart.reduce((sum, item) => sum + Number(item.price || 0), 0);
  const originalTotal = cart.reduce((sum, item) => sum + Number(item.originalPrice || item.price || 0), 0);
  const savings = originalTotal - itemsTotal;
  const deliveryCharge = 0;
  const handlingCharge = 2;
  const grandTotal = itemsTotal + handlingCharge + deliveryCharge;

  const handleCheckoutClick = async () => {
    if (!cart.length) {
      setFormError('Cart is empty');
      return;
    }

    setShowCheckoutForm(true);
    setFormError('');
  };

  const handleCustomerImage = async (event) => {
    const file = event.target.files && event.target.files[0];
    if (!file) return;
    try {
      const dataUrl = await toDataUrl(file);
      setCheckoutData((prev) => ({ ...prev, image: dataUrl }));
    } catch (error) {
      setFormError(error.message);
    }
  };

  const handlePlaceOrder = async (event) => {
    event.preventDefault();
    setFormError('');

    if (!checkoutData.name || !checkoutData.phone || !checkoutData.address) {
      setFormError('Name, phone and address are required');
      return;
    }

    setPlacing(true);
    try {
      const payload = {
        customerDetails: {
          name: checkoutData.name,
          email: checkoutData.email,
          phone: checkoutData.phone,
          address: checkoutData.address,
          image: checkoutData.image
        },
        paymentMethod: checkoutData.paymentMethod,
        totalAmount: grandTotal,
        products: cart.map((item) => ({
          product: item._id || undefined,
          name: item.name,
          price: item.price,
          quantity: 1
        }))
      };

      await onCheckout(payload);
      setShowCheckoutForm(false);
      onClose();
    } catch (error) {
      setFormError(error.message || 'Failed to place order');
    } finally {
      setPlacing(false);
    }
  };

  return (
    <div style={{
      position: 'fixed',
      top: 0,
      right: 0,
      width: 410,
      height: '100vh',
      background: '#fff',
      boxShadow: '-8px 0 32px #0002',
      zIndex: 1000,
      display: 'flex',
      flexDirection: 'column',
      fontFamily: 'Poppins, Arial, sans-serif',
      transition: 'right 0.3s',
    }}>
      <div style={{ padding: '22px 28px 16px 18px', borderBottom: '1px solid #f0f0f0', display: 'flex', alignItems: 'center', gap: 12 }}>
        <button onClick={onClose} style={{ background: 'none', border: 'none', fontSize: 28, cursor: 'pointer', color: '#222', fontWeight: 600, marginRight: 8 }}>&larr;</button>
        <span style={{ fontWeight: 700, fontSize: 22, letterSpacing: '-1px' }}>My Cart</span>
        <span style={{ flex: 1 }} />
      </div>

      <div style={{ flex: 1, overflowY: 'auto', padding: 24, background: '#f6faff' }}>
        <div style={{ background: '#eaf3ff', borderRadius: 14, padding: 16, marginBottom: 18, fontWeight: 600, fontSize: 16, color: '#1a73e8', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span>Your total savings</span>
          <span>{formatINR(savings)}</span>
        </div>

        <div style={{ background: '#fff', borderRadius: 14, padding: 18, marginBottom: 18, boxShadow: '0 2px 12px #e0e0e0' }}>
          <div style={{ fontSize: 13, color: '#888', marginBottom: 10 }}>Shipment of {cart.length} item{cart.length !== 1 ? 's' : ''}</div>
          {cart.map((item, idx) => (
            <div key={idx} style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '10px 0', background: '#f8f8f8', borderRadius: 10, padding: 8 }}>
              <img src={item.image} alt={item.name} style={{ width: 48, height: 48, borderRadius: 8, objectFit: 'cover', border: '1px solid #eee' }} />
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600, fontSize: 14 }}>{item.name}</div>
                <div style={{ color: '#888', fontSize: 12 }}>{item.volume}</div>
                <div style={{ fontWeight: 700, fontSize: 15, color: '#222' }}>{formatINR(item.price)}</div>
              </div>
              <span style={{ fontWeight: 600, fontSize: 14, color: '#222' }}>1</span>
            </div>
          ))}
        </div>

        <div style={{ background: '#fff', borderRadius: 14, padding: 18, marginBottom: 18, boxShadow: '0 2px 12px #e0e0e0' }}>
          <div style={{ fontWeight: 700, fontSize: 15, marginBottom: 8 }}>Bill details</div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
            <span>Items total</span>
            <span>{formatINR(itemsTotal)}</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
            <span>Handling charge</span>
            <span>{formatINR(handlingCharge)}</span>
          </div>
          <div style={{ borderTop: '1px dashed #ddd', margin: '10px 0' }}></div>
          <div style={{ display: 'flex', justifyContent: 'space-between', fontWeight: 700 }}>
            <span>Grand total</span>
            <span>{formatINR(grandTotal)}</span>
          </div>
        </div>
      </div>

      <div style={{ padding: 18, borderTop: '1px solid #eee', background: '#fff', boxShadow: '0 -2px 8px #eee' }}>
        {formError && <div style={{ color: '#dc2626', fontSize: 13, marginBottom: 8 }}>{formError}</div>}

        {showCheckoutForm && (
          <form onSubmit={handlePlaceOrder} style={{ marginBottom: 12, display: 'grid', gap: 8 }}>
            <div style={{ fontWeight: 600, fontSize: 14, color: '#374151' }}>Customer Details</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              {checkoutData.image ? (
                <img src={checkoutData.image} alt="customer" style={{ width: 52, height: 52, borderRadius: '50%', objectFit: 'cover', border: '1px solid #d1d5db' }} />
              ) : (
                <div style={{ width: 52, height: 52, borderRadius: '50%', background: '#f3f4f6', border: '1px solid #d1d5db', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#9ca3af', fontSize: 12 }}>Photo</div>
              )}
              <input type="file" accept="image/*" onChange={handleCustomerImage} style={{ flex: 1, border: '1px solid #d1d5db', borderRadius: 8, padding: '8px 10px', fontSize: 12, background: '#fff' }} />
            </div>
            <input placeholder="Full name" value={checkoutData.name} onChange={(e) => setCheckoutData((prev) => ({ ...prev, name: e.target.value }))} style={{ border: '1px solid #d1d5db', borderRadius: 8, padding: '8px 10px', fontSize: 13 }} />
            <input placeholder="Email (optional)" value={checkoutData.email} onChange={(e) => setCheckoutData((prev) => ({ ...prev, email: e.target.value }))} style={{ border: '1px solid #d1d5db', borderRadius: 8, padding: '8px 10px', fontSize: 13 }} />
            <input placeholder="Phone" value={checkoutData.phone} onChange={(e) => setCheckoutData((prev) => ({ ...prev, phone: e.target.value }))} style={{ border: '1px solid #d1d5db', borderRadius: 8, padding: '8px 10px', fontSize: 13 }} />
            <textarea placeholder="Delivery address" value={checkoutData.address} onChange={(e) => setCheckoutData((prev) => ({ ...prev, address: e.target.value }))} rows={2} style={{ border: '1px solid #d1d5db', borderRadius: 8, padding: '8px 10px', fontSize: 13, resize: 'vertical' }} />
            <select value={checkoutData.paymentMethod} onChange={(e) => setCheckoutData((prev) => ({ ...prev, paymentMethod: e.target.value }))} style={{ border: '1px solid #d1d5db', borderRadius: 8, padding: '8px 10px', fontSize: 13 }}>
              <option value="upi">UPI</option>
              <option value="credit_card">Credit Card</option>
              <option value="cod">Cash on Delivery</option>
            </select>

            <div style={{ border: '1px solid #e5e7eb', borderRadius: 8, padding: 10, background: '#f9fafb' }}>
              <div style={{ fontWeight: 600, fontSize: 14, color: '#374151', marginBottom: 8 }}>Product Purchase Details</div>
              {cart.map((item, idx) => (
                <div key={idx} style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
                  <img src={item.image} alt={item.name} style={{ width: 36, height: 36, borderRadius: 6, objectFit: 'cover' }} />
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 12, color: '#111827' }}>{item.name}</div>
                    <div style={{ fontSize: 11, color: '#6b7280' }}>Qty: 1</div>
                  </div>
                  <div style={{ fontSize: 12, fontWeight: 600 }}>{formatINR(item.price)}</div>
                </div>
              ))}
              <div style={{ borderTop: '1px dashed #d1d5db', marginTop: 6, paddingTop: 6, display: 'flex', justifyContent: 'space-between', fontSize: 12, fontWeight: 600 }}>
                <span>Payment: {checkoutData.paymentMethod === 'credit_card' ? 'Credit Card' : checkoutData.paymentMethod.toUpperCase()}</span>
                <span>Total: {formatINR(grandTotal)}</span>
              </div>
            </div>

            <button type="submit" disabled={placing} style={{ background: '#166534', color: '#fff', border: 'none', borderRadius: 8, padding: '10px 0', cursor: 'pointer', fontSize: 14 }}>
              {placing ? 'Placing...' : 'Place Order'}
            </button>
          </form>
        )}

        <button
          style={{
            width: '100%',
            background: 'linear-gradient(90deg, #00c853 60%, #009624 100%)',
            color: '#fff',
            fontWeight: 500,
            fontSize: 18,
            border: 'none',
            borderRadius: 12,
            padding: '14px 0',
            cursor: 'pointer',
            boxShadow: '0 2px 12px #00c85333',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            gap: 2,
          }}
          onClick={handleCheckoutClick}
        >
          <span style={{ fontWeight: 600, fontSize: 16, marginRight: 2 }}>{formatINR(grandTotal)} <span style={{ fontWeight: 400, fontSize: 13, opacity: 0.85 }}>TOTAL</span></span>
          <span style={{ fontWeight: 500, fontSize: 16, display: 'flex', alignItems: 'center', marginLeft: 0 }}>
            Proceed <span style={{ fontSize: 20, marginLeft: 2, fontWeight: 400 }}>&#8594;</span>
          </span>
        </button>
      </div>
    </div>
  );
}
