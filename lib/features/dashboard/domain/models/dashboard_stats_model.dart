class DashboardStatsModel {
  const DashboardStatsModel({
    required this.totalTickets,
    required this.pendingTickets,
    required this.inProgressTickets,
    required this.completedTickets,
    required this.totalUsers,
  });

  final int totalTickets;
  final int pendingTickets;
  final int inProgressTickets;
  final int completedTickets;
  final int totalUsers;

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalTickets: json['totalTickets'] as int? ?? 0,
      pendingTickets: json['pendingTickets'] as int? ?? 0,
      inProgressTickets: json['inProgressTickets'] as int? ?? 0,
      completedTickets: json['completedTickets'] as int? ?? 0,
      totalUsers: json['totalUsers'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTickets': totalTickets,
      'pendingTickets': pendingTickets,
      'inProgressTickets': inProgressTickets,
      'completedTickets': completedTickets,
      'totalUsers': totalUsers,
    };
  }
}

class MonthlyStatsModel {
  const MonthlyStatsModel({
    required this.received,
    required this.due,
  });

  final List<int> received;
  final List<int> due;

  factory MonthlyStatsModel.fromJson(Map<String, dynamic> json) {
    return MonthlyStatsModel(
      received: (json['received'] as List<dynamic>?)?.map((e) => e as int).toList() ??
          List.filled(12, 0),
      due: (json['due'] as List<dynamic>?)?.map((e) => e as int).toList() ??
          List.filled(12, 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'received': received,
      'due': due,
    };
  }
}
