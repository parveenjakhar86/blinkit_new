const Customer = require('../../model/Customer');

exports.getAll = async (req, res) => {
  try {
    const customers = await Customer.find().sort({ createdAt: -1 });
    res.json(customers);
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch customers' });
  }
};

exports.create = async (req, res) => {
  try {
    const normalizedPhone = String(req.body.phone || '').replace(/\D/g, '').slice(-10);
    const payload = {
      name: req.body.name,
      email: req.body.email || (normalizedPhone ? `${normalizedPhone}@blinkit.customer` : undefined),
      phone: normalizedPhone,
      address: req.body.address || '',
      state: req.body.state || '',
      pinCode: req.body.pinCode || '',
      password: req.body.password || 'customer123',
      status: req.body.status || 'active'
    };

    const customer = new Customer(payload);
    await customer.save();
    res.status(201).json(customer);
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ message: 'Customer email already exists' });
    }
    res.status(400).json({ message: error.message || 'Failed to create customer' });
  }
};

exports.update = async (req, res) => {
  try {
    const normalizedPhone = String(req.body.phone || '').replace(/\D/g, '').slice(-10);
    const updateData = {
      name: req.body.name,
      email: req.body.email || (normalizedPhone ? `${normalizedPhone}@blinkit.customer` : undefined),
      phone: normalizedPhone,
      address: req.body.address || '',
      state: req.body.state || '',
      pinCode: req.body.pinCode || '',
      status: req.body.status || 'active'
    };

    if (req.body.password) {
      updateData.password = req.body.password;
    }

    const customer = await Customer.findByIdAndUpdate(req.params.id, updateData, { new: true });

    if (!customer) {
      return res.status(404).json({ message: 'Customer not found' });
    }

    res.json(customer);
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ message: 'Customer email already exists' });
    }
    res.status(400).json({ message: error.message || 'Failed to update customer' });
  }
};

exports.remove = async (req, res) => {
  try {
    const customer = await Customer.findByIdAndDelete(req.params.id);
    if (!customer) {
      return res.status(404).json({ message: 'Customer not found' });
    }
    res.json({ message: 'Customer deleted' });
  } catch (error) {
    res.status(500).json({ message: 'Failed to delete customer' });
  }
};
