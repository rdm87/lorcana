class PrizeShare {
  final int position;
  final double percentage;
  PrizeShare({required this.position, required this.percentage});
  Map<String, dynamic> toJson() => {'position': position, 'percentage': percentage};
  factory PrizeShare.fromJson(Map<String, dynamic> json) => PrizeShare(position: json['position'], percentage: (json['percentage'] as num).toDouble());
}

class Tournament {
  final int id;
  final String title;
  final int cap;
  final double entryFeeEur;
  final String paypalLink;
  final DateTime startDate;
  final DateTime endDate;
  final String rulesDescription;
  final int prizePlayersCount;
  final List<PrizeShare> prizeDistribution;
  final int registeredCount;
  Tournament({required this.id, required this.title, required this.cap, required this.entryFeeEur, required this.paypalLink, required this.startDate, required this.endDate, required this.rulesDescription, required this.prizePlayersCount, required this.prizeDistribution, required this.registeredCount});
  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
    id: json['id'], title: json['title'], cap: json['cap'], entryFeeEur: (json['entry_fee_eur'] as num).toDouble(), paypalLink: json['paypal_link'],
    startDate: DateTime.parse(json['start_date']), endDate: DateTime.parse(json['end_date']), rulesDescription: json['rules_description'],
    prizePlayersCount: json['prize_players_count'], prizeDistribution: (json['prize_distribution'] as List).map((e) => PrizeShare.fromJson(e)).toList(), registeredCount: json['registered_count'],
  );
}
