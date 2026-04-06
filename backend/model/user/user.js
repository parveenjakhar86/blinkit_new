// User model
const mongoose = require('mongoose');


const userSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  username: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  // Roles: admin (full), manager (manage products/orders), staff (limited), customer (shop only)
  role: { type: String, enum: ['admin', 'manager', 'staff', 'customer'], default: 'customer' },
  status: { type: String, enum: ['active', 'block'], default: 'active' } // Only active can login
});

module.exports = mongoose.model('User', userSchema);
