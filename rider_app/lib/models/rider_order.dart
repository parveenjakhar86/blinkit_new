class RiderOrder {
  const RiderOrder({
    required this.id,
    required this.customerName,
    required this.area,
    required this.items,
    required this.amount,
    required this.distanceKm,
    required this.pickupEtaMin,
    required this.dropEtaMin,
    required this.status,
    required this.priority,
  });

  final String id;
  final String customerName;
  final String area;
  final int items;
  final double amount;
  final double distanceKm;
  final int pickupEtaMin;
  final int dropEtaMin;
  final String status;
  final String priority;

  factory RiderOrder.fromJson(Map<String, dynamic> json) {
    return RiderOrder(
      id: (json['id'] ?? '').toString(),
      customerName: (json['customerName'] ?? 'Customer').toString(),
      area: (json['area'] ?? '').toString(),
      items: (json['items'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      pickupEtaMin: (json['pickupEtaMin'] as num?)?.toInt() ?? 0,
      dropEtaMin: (json['dropEtaMin'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'available').toString(),
      priority: (json['priority'] ?? 'Normal').toString(),
    );
  }
}