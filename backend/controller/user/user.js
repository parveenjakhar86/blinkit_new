// User management controller
const User = require('../../model/user/user');

// Get all users
exports.getAll = async (req, res) => {
  const users = await User.find({ role: { $ne: 'customer' } });
  res.json(users);
};

// Create user
exports.create = async (req, res) => {
  let userData = { ...req.body };
  if (userData.role === 'customer') {
    return res.status(400).json({ message: 'Use customer management for customer records' });
  }
  // Set default password for admin, manager, staff if not provided
  if ((userData.role === 'admin' || userData.role === 'manager' || userData.role === 'staff') && !userData.password) {
    userData.password = 'admin123';
  }
  const user = new User(userData);
  await user.save();
  res.status(201).json(user);
};

// Update user
exports.update = async (req, res) => {
  if (req.body.role === 'customer') {
    return res.status(400).json({ message: 'Use customer management for customer records' });
  }
  const user = await User.findByIdAndUpdate(req.params.id, req.body, { new: true });
  res.json(user);
};

// Delete user
exports.remove = async (req, res) => {
  await User.findByIdAndDelete(req.params.id);
  res.json({ message: 'User deleted' });
};
