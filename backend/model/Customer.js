const mongoose = require('mongoose');

const customerSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    phone: { type: String, default: '', index: true },
    address: { type: String, default: '' },
    state: { type: String, default: '' },
    pinCode: { type: String, default: '' },
    password: { type: String, default: 'customer123' },
    status: { type: String, enum: ['active', 'block'], default: 'active' },
    pendingOtp: { type: String, default: null },
    pendingOtpExpiresAt: { type: Date, default: null }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Customer', customerSchema);
