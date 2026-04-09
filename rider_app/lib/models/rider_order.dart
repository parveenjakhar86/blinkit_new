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
}