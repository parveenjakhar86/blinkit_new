// Order model
const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  customerDetails: {
    name: { type: String },
    email: { type: String },
    phone: { type: String },
    address: { type: String },
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
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Order', orderSchema);
