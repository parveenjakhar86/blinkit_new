// User management controller
const User = require('../model/user/user');

// Get all users
exports.getAll = async (req, res) => {
  const users = await User.find();
  res.json(users);
};

// Create user
exports.create = async (req, res) => {
  const user = new User(req.body);
  await user.save();
  res.status(201).json(user);
};

// Update user
exports.update = async (req, res) => {
  const user = await User.findByIdAndUpdate(req.params.id, req.body, { new: true });
  res.json(user);
};

// Delete user
exports.remove = async (req, res) => {
  await User.findByIdAndDelete(req.params.id);
  res.json({ message: 'User deleted' });
};
