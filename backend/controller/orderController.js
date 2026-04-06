// Order management controller
const Order = require('../model/Order');

// Get all orders
exports.getAll = async (req, res) => {
  const orders = await Order.find().populate('user').populate('products.product');
  res.json(orders);
};

// Create order
exports.create = async (req, res) => {
  const order = new Order(req.body);
  await order.save();
  res.status(201).json(order);
};

// Update order status
exports.update = async (req, res) => {
  const order = await Order.findByIdAndUpdate(req.params.id, req.body, { new: true });
  res.json(order);
};

// Delete order
exports.remove = async (req, res) => {
  await Order.findByIdAndDelete(req.params.id);
  res.json({ message: 'Order deleted' });
};
