const mongoose = require('mongoose');

const riderSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    phone: { type: String, required: true, unique: true, index: true },
    vehicleNumber: { type: String, default: '' },
    zone: { type: String, default: '' },
    status: { type: String, enum: ['active', 'block'], default: 'active' },
    pendingOtp: { type: String, default: null },
    pendingOtpExpiresAt: { type: Date, default: null },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Rider', riderSchema);