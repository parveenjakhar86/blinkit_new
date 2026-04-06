const jwt = require('jsonwebtoken');
const Customer = require('../../model/Customer');

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const customer = await Customer.findOne({ email });
    if (!customer) {
      return res.status(401).json({ message: 'Customer not found' });
    }

    if (customer.password !== password) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    if (customer.status !== 'active') {
      return res.status(403).json({ message: 'Customer account is blocked' });
    }

    const token = jwt.sign(
      { customerId: customer._id, email: customer.email, role: 'customer' },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({ token, customer });
  } catch (error) {
    res.status(500).json({ message: 'Customer login failed' });
  }
};
