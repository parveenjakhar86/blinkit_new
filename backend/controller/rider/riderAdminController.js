const Rider = require('../../model/Rider');
const Order = require('../../model/Order');

function normalizePhone(phone = '') {
  return String(phone).replace(/\D/g, '').slice(-10);
}

function buildRiderEmail(phone) {
  return `${phone}@blinkit.rider`;
}

function groupOrdersByRider(orders) {
  return orders.reduce((map, order) => {
    const riderId = String(order.rider || '');
    if (!riderId) return map;
    if (!map.has(riderId)) {
      map.set(riderId, []);
    }
    map.get(riderId).push(order);
    return map;
  }, new Map());
}

function buildStats(rider, orders) {
  const activeOrders = orders.filter(
    (order) => ['accepted', 'picked_up'].includes(order.riderStatus) && order.status !== 'cancelled'
  );
  const acceptedOrders = orders.filter((order) => !!order.riderAssignedAt).length;
  const deliveredOrders = orders.filter((order) => order.riderStatus === 'delivered').length;

  const acceptanceTimes = orders
    .filter((order) => order.riderAssignedAt && order.createdAt)
    .map((order) => {
      const assignedAt = new Date(order.riderAssignedAt).getTime();
      const createdAt = new Date(order.createdAt).getTime();
      return Math.max(0, (assignedAt - createdAt) / 60000);
    });

  const averageAcceptMinutes = acceptanceTimes.length
    ? Number((acceptanceTimes.reduce((sum, value) => sum + value, 0) / acceptanceTimes.length).toFixed(1))
    : 0;

  const lastAcceptedAt = orders
    .filter((order) => order.riderAssignedAt)
    .map((order) => new Date(order.riderAssignedAt))
    .sort((left, right) => right.getTime() - left.getTime())[0] || null;

  const currentOrderStatus = activeOrders[0]?.riderStatus || '';

  return {
    activeOrders: activeOrders.length,
    acceptedOrders,
    deliveredOrders,
    averageAcceptMinutes,
    currentOrderStatus,
    lastAcceptedAt,
  };
}

function toAdminRider(rider, stats) {
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
    ...stats,
  };
}

async function withStats(riders) {
  const riderIds = riders.map((rider) => rider._id);
  const orders = await Order.find({ rider: { $in: riderIds } })
    .select('rider status riderStatus riderAssignedAt createdAt')
    .lean();
  const grouped = groupOrdersByRider(orders);

  return riders.map((rider) =>
    toAdminRider(rider, buildStats(rider, grouped.get(String(rider._id)) || []))
  );
}

exports.getAll = async (req, res) => {
  try {
    const riders = await Rider.find().sort({ createdAt: -1 });
    res.json(await withStats(riders));
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch riders' });
  }
};

exports.create = async (req, res) => {
  try {
    const phone = normalizePhone(req.body.phone);
    const rider = await Rider.create({
      name: req.body.name,
      email: req.body.email || (phone ? buildRiderEmail(phone) : undefined),
      phone,
      vehicleNumber: req.body.vehicleNumber || '',
      zone: req.body.zone || '',
      availabilityStatus: req.body.availabilityStatus || 'offline',
      lastSeenAt: req.body.lastSeenAt || null,
      status: req.body.status || 'active',
    });

    res.status(201).json(toAdminRider(rider, buildStats(rider, [])));
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ message: 'Rider phone or email already exists' });
    }
    res.status(400).json({ message: error.message || 'Failed to create rider' });
  }
};

exports.update = async (req, res) => {
  try {
    const phone = normalizePhone(req.body.phone);
    const updateData = {
      name: req.body.name,
      email: req.body.email || (phone ? buildRiderEmail(phone) : undefined),
      phone,
      vehicleNumber: req.body.vehicleNumber || '',
      zone: req.body.zone || '',
      availabilityStatus: req.body.availabilityStatus || 'offline',
      status: req.body.status || 'active',
    };

    const rider = await Rider.findByIdAndUpdate(req.params.id, updateData, { new: true });
    if (!rider) {
      return res.status(404).json({ message: 'Rider not found' });
    }

    const orders = await Order.find({ rider: rider._id })
      .select('rider status riderStatus riderAssignedAt createdAt')
      .lean();

    res.json(toAdminRider(rider, buildStats(rider, orders)));
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ message: 'Rider phone or email already exists' });
    }
    res.status(400).json({ message: error.message || 'Failed to update rider' });
  }
};

exports.remove = async (req, res) => {
  try {
    const rider = await Rider.findByIdAndDelete(req.params.id);
    if (!rider) {
      return res.status(404).json({ message: 'Rider not found' });
    }
    await Order.updateMany({ rider: rider._id }, {
      $set: { rider: null, riderStatus: 'available', riderAssignedAt: null },
    });
    res.json({ message: 'Rider deleted' });
  } catch (error) {
    res.status(500).json({ message: 'Failed to delete rider' });
  }
};