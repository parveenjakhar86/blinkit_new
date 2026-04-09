// Order management controller
const Order = require('../../model/Order');

function normalizeItems(items = []) {
  return items.map((item) => ({
    product: item.product || undefined,
    name: item.name || item.productName || '',
    price: Number(item.price || 0),
    quantity: Number(item.quantity || 1)
  }));
}

function calculateTotal(items = []) {
  return items.reduce((sum, item) => {
    const price = Number(item.price || item?.product?.price || 0);
    const quantity = Number(item.quantity || 0);
    return sum + price * quantity;
  }, 0);
}

function toDisplayOrder(orderDoc) {
  const order = orderDoc.toObject ? orderDoc.toObject() : orderDoc;
  const total = Number(order.totalAmount || calculateTotal(order.products || []));
  const customerDetails = order.customerDetails || {};
  const addressParts = [
    customerDetails.address,
    customerDetails.state,
    customerDetails.pinCode,
  ].filter((value) => String(value || '').trim().length > 0);

  return {
    ...order,
    customerDetails: {
      ...customerDetails,
      fullAddress: addressParts.join(', '),
    },
    total
  };
}

// Get all orders
exports.getAll = async (req, res) => {
  const orders = await Order.find()
    .populate('user')
    .populate('products.product')
    .sort({ createdAt: -1 });
  res.json(orders.map(toDisplayOrder));
};

// Create order
exports.create = async (req, res) => {
  const products = normalizeItems(req.body.products || []);
  const order = new Order({
    user: req.body.user,
    customerDetails: req.body.customerDetails,
    products,
    paymentMethod: req.body.paymentMethod || 'cod',
    totalAmount: Number(req.body.totalAmount || calculateTotal(products)),
    status: req.body.status || 'pending'
  });
  await order.save();
  res.status(201).json(toDisplayOrder(order));
};

// Public checkout order placement
exports.placeOrder = async (req, res) => {
  try {
    const products = normalizeItems(req.body.products || []);
    if (!products.length) {
      return res.status(400).json({ message: 'Cart is empty' });
    }

    const customerDetails = req.body.customerDetails || {};
    if (
      !customerDetails.name ||
      !customerDetails.address ||
      !customerDetails.phone ||
      !customerDetails.state ||
      !customerDetails.pinCode
    ) {
      return res.status(400).json({
        message: 'Customer name, phone, address, state and pin code are required'
      });
    }

    const paymentMethod = req.body.paymentMethod || 'cod';
    const allowed = ['upi', 'credit_card', 'cod'];
    if (!allowed.includes(paymentMethod)) {
      return res.status(400).json({ message: 'Invalid payment method' });
    }

    const order = new Order({
      customerDetails: {
        name: customerDetails.name,
        email: customerDetails.email || '',
        phone: customerDetails.phone,
        address: customerDetails.address,
        state: customerDetails.state,
        pinCode: String(customerDetails.pinCode || ''),
        image: customerDetails.image || ''
      },
      products,
      paymentMethod,
      totalAmount: Number(req.body.totalAmount || calculateTotal(products)),
      status: 'pending'
    });

    await order.save();
    res.status(201).json({
      message: 'Order placed successfully',
      order: toDisplayOrder(order)
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to place order' });
  }
};

// Update order status
exports.update = async (req, res) => {
  const payload = {};
  if (req.body.status) {
    payload.status = String(req.body.status).toLowerCase();
  }

  const order = await Order.findByIdAndUpdate(req.params.id, payload, { new: true })
    .populate('user')
    .populate('products.product');

  if (!order) {
    return res.status(404).json({ message: 'Order not found' });
  }

  res.json(toDisplayOrder(order));
};

// Delete order
exports.remove = async (req, res) => {
  await Order.findByIdAndDelete(req.params.id);
  res.json({ message: 'Order deleted' });
};
