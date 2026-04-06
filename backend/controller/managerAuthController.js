// Controller for manager login
const jwt = require('jsonwebtoken');
const User = require('../model/user/user');
const crypto = require('crypto');
const JWT_SECRET = process.env.JWT_SECRET || crypto.randomBytes(32).toString('hex');

// POST /api/manager/login
// Body: { email, password }
// Returns: { token }
exports.login = async (req, res) => {
  const { email, password } = req.body;
  const user = await User.findOne({ email, role: 'manager' });
  if (!user) return res.status(401).json({ message: 'Manager not found' });
  if (user.password !== password) return res.status(401).json({ message: 'Invalid credentials' });
  if (user.status !== 'active') return res.status(403).json({ message: 'Account is blocked' });
  const token = jwt.sign({ email, role: 'manager', id: user._id }, JWT_SECRET, { expiresIn: '2h' });
  res.json({ token });
};
