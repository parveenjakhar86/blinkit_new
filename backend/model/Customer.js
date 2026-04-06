const mongoose = require('mongoose');

const customerSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    phone: { type: String, default: '' },
    address: { type: String, default: '' },
    password: { type: String, default: 'customer123' },
    status: { type: String, enum: ['active', 'block'], default: 'active' }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Customer', customerSchema);
