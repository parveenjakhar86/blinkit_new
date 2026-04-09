import '../models/rider_order.dart';

class RiderMetric {
  const RiderMetric(this.label, this.value);

  final String label;
  final String value;
}

class RiderZone {
  const RiderZone({
    required this.name,
    required this.load,
    required this.incentive,
  });

  final String name;
  final String load;
  final String incentive;
}

const riderName = 'Parveen Rider';

const todayMetrics = <RiderMetric>[
  RiderMetric('Completed', '18'),
  RiderMetric('Cash Collected', 'Rs 2,430'),
  RiderMetric('Rating', '4.9'),
  RiderMetric('Online Time', '7h 40m'),
];

const earningsMetrics = <RiderMetric>[
  RiderMetric('Today', 'Rs 1,280'),
  RiderMetric('This Week', 'Rs 8,940'),
  RiderMetric('Incentives', 'Rs 1,650'),
  RiderMetric('Wallet Balance', 'Rs 2,140'),
];

const weeklyBars = <double>[0.45, 0.72, 0.58, 0.91, 0.87, 0.63, 0.41];

const activeOrders = <RiderOrder>[
  RiderOrder(
    id: 'BLK-3021',
    orderNumber: 'BLK-3021',
    customerName: 'Riya Sharma',
    area: 'Sector 14',
    items: 7,
    amount: 684,
    distanceKm: 2.1,
    pickupEtaMin: 4,
    dropEtaMin: 12,
    status: 'Picked up',
    priority: 'High',
  ),
  RiderOrder(
    id: 'BLK-3024',
    orderNumber: 'BLK-3024',
    customerName: 'Vikram Singh',
    area: 'Model Town',
    items: 4,
    amount: 391,
    distanceKm: 1.4,
    pickupEtaMin: 2,
    dropEtaMin: 9,
    status: 'Ready at store',
    priority: 'Medium',
  ),
];

const availableOrders = <RiderOrder>[
  RiderOrder(
    id: 'BLK-3030',
    orderNumber: 'BLK-3030',
    customerName: 'Arjun Mehta',
    area: 'Civil Lines',
    items: 11,
    amount: 921,
    distanceKm: 3.8,
    pickupEtaMin: 5,
    dropEtaMin: 17,
    status: 'Assigned nearby',
    priority: 'Surge',
  ),
  RiderOrder(
    id: 'BLK-3032',
    orderNumber: 'BLK-3032',
    customerName: 'Nisha Gupta',
    area: 'Green Park',
    items: 5,
    amount: 448,
    distanceKm: 1.8,
    pickupEtaMin: 3,
    dropEtaMin: 10,
    status: 'Waiting for rider',
    priority: 'Normal',
  ),
  RiderOrder(
    id: 'BLK-3035',
    orderNumber: 'BLK-3035',
    customerName: 'Karan Bedi',
    area: 'Shastri Nagar',
    items: 8,
    amount: 706,
    distanceKm: 2.9,
    pickupEtaMin: 6,
    dropEtaMin: 15,
    status: 'Packed',
    priority: 'High',
  ),
];

const topZones = <RiderZone>[
  RiderZone(name: 'City Center', load: 'Busy', incentive: '+Rs 40/order'),
  RiderZone(name: 'Sector 62', load: 'Moderate', incentive: '+Rs 20/order'),
  RiderZone(name: 'Raj Nagar', load: 'Busy', incentive: '+Rs 30/order'),
];