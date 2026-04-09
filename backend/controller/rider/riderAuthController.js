const jwt = require('jsonwebtoken');
const Rider = require('../../model/Rider');

const OTP_TTL_MS = 5 * 60 * 1000;

function normalizePhone(phone = '') {
  return String(phone).replace(/\D/g, '').slice(-10);
}

function buildRiderEmail(phone) {
  return `${phone}@blinkit.rider`;
}

function generateOtp() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function signRiderToken(rider) {
  return jwt.sign(
    {
      riderId: rider._id,
      email: rider.email,
      phone: rider.phone,
      role: 'rider',
    },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );
}

function toRiderPayload(rider) {
  return {
    _id: rider._id,
    name: rider.name,
    email: rider.email,
    phone: rider.phone,
    vehicleNumber: rider.vehicleNumber,
    zone: rider.zone,
    availabilityStatus: rider.availabilityStatus,
    lastSeenAt: rider.lastSeenAt,
    status: rider.status,
    createdAt: rider.createdAt,
    updatedAt: rider.updatedAt,
  };
}

exports.sendOtp = async (req, res) => {
  try {
    const phone = normalizePhone(req.body.phone);
    const name = String(req.body.name || 'Rider').trim();

    if (phone.length !== 10) {
      return res.status(400).json({ message: 'Enter a valid 10-digit phone number' });
    }

    let rider = await Rider.findOne({ phone });
    const otp = generateOtp();
    const expiresAt = new Date(Date.now() + OTP_TTL_MS);

    if (!rider) {
      rider = await Rider.create({
        name: name || 'Rider',
        email: buildRiderEmail(phone),
        phone,
        availabilityStatus: 'offline',
        status: 'active',
        pendingOtp: otp,
        pendingOtpExpiresAt: expiresAt,
      });
    } else {
      rider.pendingOtp = otp;
      rider.pendingOtpExpiresAt = expiresAt;
      if (!rider.email) {
        rider.email = buildRiderEmail(phone);
      }
      if ((!rider.name || rider.name === 'Rider') && name) {
        rider.name = name;
      }
      await rider.save();
    }

    return res.json({
      message: 'OTP sent successfully',
      phone,
      otp,
      isNewRider: !rider.vehicleNumber && !rider.zone,
    });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to send OTP' });
  }
};

exports.verifyOtp = async (req, res) => {
  try {
    const phone = normalizePhone(req.body.phone);
    const otp = String(req.body.otp || '').trim();
    const name = String(req.body.name || '').trim();

    if (phone.length !== 10) {
      return res.status(400).json({ message: 'Enter a valid 10-digit phone number' });
    }

    if (otp.length !== 6) {
      return res.status(400).json({ message: 'Enter the 6-digit OTP' });
    }

    const rider = await Rider.findOne({ phone });
    if (!rider) {
      return res.status(404).json({ message: 'Rider account not found for this phone number' });
    }

    if (rider.status !== 'active') {
      return res.status(403).json({ message: 'Rider account is blocked' });
    }

    if (!rider.pendingOtp || !rider.pendingOtpExpiresAt) {
      return res.status(400).json({ message: 'Request a new OTP to continue' });
    }

    if (rider.pendingOtp !== otp) {
      return res.status(400).json({ message: 'Invalid OTP' });
    }

    if (rider.pendingOtpExpiresAt.getTime() < Date.now()) {
      rider.pendingOtp = null;
      rider.pendingOtpExpiresAt = null;
      await rider.save();
      return res.status(400).json({ message: 'OTP expired. Request a new OTP.' });
    }

    if (name) {
      rider.name = name;
    }
    if (!rider.email) {
      rider.email = buildRiderEmail(phone);
    }

    rider.pendingOtp = null;
    rider.pendingOtpExpiresAt = null;
    rider.lastSeenAt = new Date();
    await rider.save();

    const token = signRiderToken(rider);
    return res.json({ token, rider: toRiderPayload(rider) });
  } catch (error) {
    return res.status(500).json({ message: 'OTP verification failed' });
  }
};