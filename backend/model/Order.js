// Order model for MongoDB
const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  customer: { type: mongoose.Schema.Types.ObjectId, ref: 'Customer' },
  rider: { type: mongoose.Schema.Types.ObjectId, ref: 'Rider', default: null },
  customerDetails: {
    name: { type: String },
    email: { type: String },
    phone: { type: String },
    address: { type: String },
    state: { type: String },
    pinCode: { type: String },
    image: { type: String }
  },
  products: [{
    product: { type: mongoose.Schema.Types.ObjectId, ref: 'Product' },
    name: { type: String },
    price: { type: Number, default: 0 },
    quantity: { type: Number, default: 1 }
  }],
  paymentMethod: { type: String, enum: ['upi', 'credit_card', 'cod'], default: 'cod' },
  totalAmount: { type: Number, default: 0 },
  status: { type: String, enum: ['pending', 'processing', 'completed', 'cancelled'], default: 'pending' },
  riderStatus: {
    type: String,
    enum: ['available', 'accepted', 'picked_up', 'delivered'],
    default: 'available'
  },
  riderAssignedAt: { type: Date, default: null },
  riderDeliveredAt: { type: Date, default: null },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Order', orderSchema);
