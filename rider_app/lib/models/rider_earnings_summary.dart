class RiderEarningsSummary {
  const RiderEarningsSummary({
    required this.today,
    required this.week,
    required this.incentives,
    required this.walletBalance,
    required this.completedToday,
    required this.cashCollected,
    required this.nextSettlement,
    required this.weeklyBars,
  });

  final double today;
  final double week;
  final double incentives;
  final double walletBalance;
  final int completedToday;
  final double cashCollected;
  final String nextSettlement;
  final List<double> weeklyBars;

  factory RiderEarningsSummary.fromJson(Map<String, dynamic> json) {
    final weeklyRaw = json['weeklyBars'];
    return RiderEarningsSummary(
      today: (json['today'] as num?)?.toDouble() ?? 0,
      week: (json['week'] as num?)?.toDouble() ?? 0,
      incentives: (json['incentives'] as num?)?.toDouble() ?? 0,
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0,
      completedToday: (json['completedToday'] as num?)?.toInt() ?? 0,
      cashCollected: (json['cashCollected'] as num?)?.toDouble() ?? 0,
      nextSettlement: (json['nextSettlement'] ?? '').toString(),
      weeklyBars: weeklyRaw is List
          ? weeklyRaw.map((value) => (value as num).toDouble()).toList()
          : const [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
    );
  }
}