// Controller for user login (admin, manager, staff)
const jwt = require('jsonwebtoken');
const User = require('../../model/user/user');


// POST /api/user/login
// Body: { email, password }
// Returns: { token }
exports.login = async (req, res) => {
  const { email, password } = req.body;
  // Only check users collection for admin, manager, staff
  const user = await User.findOne({ email, role: { $in: ['admin', 'manager', 'staff'] } });
  if (!user) return res.status(401).json({ message: 'User not found in users table' });
  if (user.password !== password) return res.status(401).json({ message: 'Invalid credentials' });
  if (user.status !== 'active') return res.status(403).json({ message: 'Account is blocked' });
  console.log('JWT_SECRET at user login:', process.env.JWT_SECRET);
  const token = jwt.sign({ email, role: user.role, id: user._id }, process.env.JWT_SECRET, { expiresIn: '2h' });
  res.json({ token, user });
};
