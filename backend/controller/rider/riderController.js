const mongoose = require('mongoose');

const Order = require('../../model/Order');
const Rider = require('../../model/Rider');

function buildAddress(details = {}) {
  return [details.address, details.state, details.pinCode]
    .filter((value) => String(value || '').trim())
    .join(', ');
}

function deterministicMetric(seed, min, spread) {
  const source = String(seed || '0')
    .split('')
    .reduce((sum, char) => sum + char.charCodeAt(0), 0);
  return min + (source % spread);
}

function toRiderOrder(orderDoc) {
  const order = orderDoc.toObject ? orderDoc.toObject() : orderDoc;
  const items = Array.isArray(order.products) ? order.products : [];
  const itemCount = items.reduce((sum, item) => sum + Number(item.quantity || 0), 0);
  const address = buildAddress(order.customerDetails || {});
  const distanceKm = deterministicMetric(order._id, 1.2, 30) / 10;
  const pickupEtaMin = deterministicMetric(`${order._id}-pickup`, 2, 6);
  const dropEtaMin = deterministicMetric(`${order._id}-drop`, 8, 12);
  const priority = Number(order.totalAmount || 0) >= 700
    ? 'High'
    : Number(order.totalAmount || 0) >= 450
      ? 'Medium'
      : 'Normal';

  return {
    id: String(order._id),
    orderNumber: String(order._id).slice(-6).toUpperCase(),
    customerName: order.customerDetails?.name || 'Customer',
    phone: order.customerDetails?.phone || '',
    area: order.customerDetails?.state || order.customerDetails?.address || 'Unknown area',
    fullAddress: address,
    items: itemCount,
    amount: Number(order.totalAmount || 0),
    distanceKm,
    pickupEtaMin,
    dropEtaMin,
    status: order.riderStatus || 'available',
    priority,
    paymentMethod: order.paymentMethod || 'cod',
    createdAt: order.createdAt,
  };
}

function startOfDay(date = new Date()) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate());
}

function startOfWeek(date = new Date()) {
  const day = date.getDay();
  const diff = day === 0 ? 6 : day - 1;
  return new Date(date.getFullYear(), date.getMonth(), date.getDate() - diff);
}

function nextFridaySettlement(date = new Date()) {
  const current = new Date(date);
  const friday = 5;
  const day = current.getDay();
  const delta = (friday - day + 7) % 7;
  current.setDate(current.getDate() + delta);
  current.setHours(18, 0, 0, 0);
  return current;
}

exports.getOrders = async (req, res) => {
  try {
    const riderId = new mongoose.Types.ObjectId(req.user.riderId);

    const activeDocs = await Order.find({
      rider: riderId,
      status: { $ne: 'cancelled' },
      riderStatus: { $in: ['accepted', 'picked_up'] },
    }).sort({ createdAt: -1 });

    const availableDocs = await Order.find({
      $or: [{ rider: null }, { rider: { $exists: false } }],
      status: 'pending',
      riderStatus: { $in: ['available', null] },
    })
      .sort({ createdAt: -1 })
      .limit(20);

    res.json({
      activeOrders: activeDocs.map(toRiderOrder),
      availableOrders: availableDocs.map(toRiderOrder),
    });
  } catch (error) {
    res.status(500).json({ message: 'Failed to fetch rider orders' });
  }
};

exports.acceptOrder = async (req, res) => {
  try {
    const order = await Order.findOneAndUpdate(
      {
        _id: req.params.id,
        $or: [{ rider: null }, { rider: { $exists: false } }],
        status: 'pending',
        riderStatus: { $in: ['available', null] },
      },
      {
        $set: {
          rider: req.user.riderId,
          riderAssignedAt: new Date(),
          riderStatus: 'accepted',
          status: 'processing',
        },
      },
      { new: true }
    );

    if (!order) {
      return res.status(404).json({ message: 'Order is no longer available' });
    }

    await Rider.findByIdAndUpdate(req.user.riderId, {
      $set: { lastSeenAt: new Date() },
    });

    return res.json({ message: 'Order accepted', order: toRiderOrder(order) });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to accept order' });
  }
};

exports.updateOrderStatus = async (req, res) => {
  try {
    const nextStatus = String(req.body.status || '').trim().toLowerCase();
    if (!['accepted', 'picked_up', 'delivered'].includes(nextStatus)) {
      return res.status(400).json({ message: 'Invalid rider status' });
    }

    const order = await Order.findOne({
      _id: req.params.id,
      rider: req.user.riderId,
    });

    if (!order) {
      return res.status(404).json({ message: 'Order not found for this rider' });
    }

    order.riderStatus = nextStatus;
    if (nextStatus === 'delivered') {
      order.status = 'completed';
      order.riderDeliveredAt = new Date();
    } else {
      order.status = 'processing';
    }

    await order.save();
    await Rider.findByIdAndUpdate(req.user.riderId, {
      $set: { lastSeenAt: new Date() },
    });
    return res.json({ message: 'Order status updated', order: toRiderOrder(order) });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to update rider order status' });
  }
};

exports.updateAvailability = async (req, res) => {
  try {
    const availabilityStatus = String(req.body.availabilityStatus || '').toLowerCase();
    if (!['offline', 'online'].includes(availabilityStatus)) {
      return res.status(400).json({ message: 'Invalid availability status' });
    }

    const rider = await Rider.findByIdAndUpdate(
      req.user.riderId,
      {
        $set: {
          availabilityStatus,
          lastSeenAt: new Date(),
        },
      },
      { new: true }
    );

    if (!rider) {
      return res.status(404).json({ message: 'Rider not found' });
    }

    return res.json({
      message: 'Availability updated',
      rider: {
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
      },
    });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to update rider availability' });
  }
};

exports.getEarnings = async (req, res) => {
  try {
    const riderId = new mongoose.Types.ObjectId(req.user.riderId);
    const deliveredOrders = await Order.find({
      rider: riderId,
      riderStatus: 'delivered',
      status: 'completed',
    }).sort({ createdAt: -1 });

    const todayStart = startOfDay();
    const weekStart = startOfWeek();
    const now = new Date();

    let today = 0;
    let week = 0;
    let completedToday = 0;
    let cashCollected = 0;
    const weekly = [0, 0, 0, 0, 0, 0, 0];

    for (const order of deliveredOrders) {
      const amount = Number(order.totalAmount || 0);
      const createdAt = new Date(order.riderDeliveredAt || order.createdAt);
      const dayIndex = (createdAt.getDay() + 6) % 7;

      if (createdAt >= weekStart && createdAt <= now) {
        week += amount;
        weekly[dayIndex] += amount;
      }

      if (createdAt >= todayStart && createdAt <= now) {
        today += amount;
        completedToday += 1;
        if (order.paymentMethod === 'cod') {
          cashCollected += amount;
        }
      }
    }

    const incentives = deliveredOrders.filter((order) => Number(order.totalAmount || 0) >= 700).length * 40;
    const walletBalance = Math.max(0, week + incentives - cashCollected);
    const maxBar = weekly.reduce((max, value) => (value > max ? value : max), 0);
    const weeklyBars = weekly.map((value) => {
      if (maxBar <= 0) return 0.1;
      const ratio = value / maxBar;
      const normalized = Math.max(0.1, Math.min(1, ratio));
      return Number(normalized.toFixed(2));
    });

    return res.json({
      today,
      week,
      incentives,
      walletBalance,
      completedToday,
      cashCollected,
      nextSettlement: nextFridaySettlement().toISOString(),
      weeklyBars,
    });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to fetch rider earnings' });
  }
};