// Controller for admin authentication

const jwt = require('jsonwebtoken');
const Admin = require('../model/user/admin');
const JWT_SECRET = process.env.JWT_SECRET;

// POST /api/admin/login
// Body: { email, password }
// Returns: { token }
exports.login = async (req, res) => {
  const { email, password } = req.body;
  const admin = await Admin.findOne({ email });
  console.log('JWT_SECRET at login:', process.env.JWT_SECRET);
  if (admin && admin.password === password) {
    const token = jwt.sign({ email, role: 'admin' }, process.env.JWT_SECRET, { expiresIn: '2h' });
    return res.json({ token });
  }
  res.status(401).json({ message: 'Invalid credentials' });
};
