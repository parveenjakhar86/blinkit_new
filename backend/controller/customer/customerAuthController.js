const jwt = require('jsonwebtoken');
const Customer = require('../../model/Customer');

const OTP_TTL_MS = 5 * 60 * 1000;

function normalizePhone(phone = '') {
  return String(phone).replace(/\D/g, '').slice(-10);
}

function buildCustomerEmail(phone) {
  return `${phone}@blinkit.customer`;
}

function generateOtp() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function signCustomerToken(customer) {
  return jwt.sign(
    {
      customerId: customer._id,
      email: customer.email,
      phone: customer.phone,
      role: 'customer'
    },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );
}

function toCustomerPayload(customer) {
  return {
    _id: customer._id,
    name: customer.name,
    email: customer.email,
    phone: customer.phone,
    address: customer.address,
    state: customer.state,
    pinCode: customer.pinCode,
    status: customer.status,
    createdAt: customer.createdAt,
    updatedAt: customer.updatedAt
  };
}

exports.sendOtp = async (req, res) => {
  try {
    const phone = normalizePhone(req.body.phone);
    const name = String(req.body.name || 'Customer').trim();

    if (phone.length != 10) {
      return res.status(400).json({ message: 'Enter a valid 10-digit phone number' });
    }

    let customer = await Customer.findOne({ phone });
    const otp = generateOtp();
    const expiresAt = new Date(Date.now() + OTP_TTL_MS);

    if (!customer) {
      customer = await Customer.create({
        name: name || 'Customer',
        email: buildCustomerEmail(phone),
        phone,
        password: otp,
        status: 'active',
        pendingOtp: otp,
        pendingOtpExpiresAt: expiresAt
      });
    } else {
      customer.pendingOtp = otp;
      customer.pendingOtpExpiresAt = expiresAt;
      if (!customer.phone) {
        customer.phone = phone;
      }
      if (!customer.email) {
        customer.email = buildCustomerEmail(phone);
      }
      if ((!customer.name || customer.name === 'Customer') && name) {
        customer.name = name;
      }
      await customer.save();
    }

    res.json({
      message: 'OTP sent successfully',
      phone,
      otp,
      isNewCustomer: !customer.address && !customer.pinCode && !customer.state
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to send OTP' });
  }
};

exports.verifyOtp = async (req, res) => {
  try {
    const phone = normalizePhone(req.body.phone);
    const otp = String(req.body.otp || '').trim();
    const name = String(req.body.name || '').trim();

    if (phone.length != 10) {
      return res.status(400).json({ message: 'Enter a valid 10-digit phone number' });
    }

    if (otp.length != 6) {
      return res.status(400).json({ message: 'Enter the 6-digit OTP' });
    }

    const customer = await Customer.findOne({ phone });
    if (!customer) {
      return res.status(404).json({ message: 'Customer account not found for this phone number' });
    }

    if (customer.status !== 'active') {
      return res.status(403).json({ message: 'Customer account is blocked' });
    }

    if (!customer.pendingOtp || !customer.pendingOtpExpiresAt) {
      return res.status(400).json({ message: 'Request a new OTP to continue' });
    }

    if (customer.pendingOtp !== otp) {
      return res.status(400).json({ message: 'Invalid OTP' });
    }

    if (customer.pendingOtpExpiresAt.getTime() < Date.now()) {
      customer.pendingOtp = null;
      customer.pendingOtpExpiresAt = null;
      await customer.save();
      return res.status(400).json({ message: 'OTP expired. Request a new OTP.' });
    }

    if (name) {
      customer.name = name;
    }
    if (!customer.email) {
      customer.email = buildCustomerEmail(phone);
    }

    customer.pendingOtp = null;
    customer.pendingOtpExpiresAt = null;
    await customer.save();

    const token = signCustomerToken(customer);
    res.json({ token, customer: toCustomerPayload(customer) });
  } catch (error) {
    res.status(500).json({ message: 'OTP verification failed' });
  }
};

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

    const token = signCustomerToken(customer);

    res.json({ token, customer: toCustomerPayload(customer) });
  } catch (error) {
    res.status(500).json({ message: 'Customer login failed' });
  }
};
