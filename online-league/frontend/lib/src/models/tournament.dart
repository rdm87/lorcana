class PrizeShare {
  final int position;
  final double percentage;
  PrizeShare({required this.position, required this.percentage});
  Map<String, dynamic> toJson() => {'position': position, 'percentage': percentage};
  factory PrizeShare.fromJson(Map<String, dynamic> json) =>
      PrizeShare(position: json['position'], percentage: (json['percentage'] as num).toDouble());
}

class PublicRegistration {
  final int id;
  final String firstName;
  final String lastName;
  final DateTime createdAt;
  PublicRegistration({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.createdAt,
  });
  factory PublicRegistration.fromJson(Map<String, dynamic> json) => PublicRegistration(
        id: json['id'],
        firstName: json['first_name'],
        lastName: json['last_name'],
        createdAt: DateTime.parse(json['created_at']),
      );
}

// Full registration data — used for "my registration" and admin views
class FullRegistration extends PublicRegistration {
  final int tournamentId;
  final int? userId; // null for admin-added registrations
  final String discordAccount;
  final bool paid;

  FullRegistration({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.createdAt,
    required this.tournamentId,
    this.userId,
    required this.discordAccount,
    required this.paid,
  });

  factory FullRegistration.fromJson(Map<String, dynamic> json) => FullRegistration(
        id: json['id'],
        tournamentId: json['tournament_id'],
        userId: json['user_id'] as int?,
        discordAccount: json['discord_account'],
        firstName: json['first_name'],
        lastName: json['last_name'],
        paid: json['paid'] ?? false,
        createdAt: DateTime.parse(json['created_at']),
      );
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

  Tournament({
    required this.id,
    required this.title,
    required this.cap,
    required this.entryFeeEur,
    required this.paypalLink,
    required this.startDate,
    required this.endDate,
    required this.rulesDescription,
    required this.prizePlayersCount,
    required this.prizeDistribution,
    required this.registeredCount,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
        id: json['id'],
        title: json['title'],
        cap: json['cap'],
        entryFeeEur: (json['entry_fee_eur'] as num).toDouble(),
        paypalLink: json['paypal_link'],
        startDate: DateTime.parse(json['start_date']),
        endDate: DateTime.parse(json['end_date']),
        rulesDescription: json['rules_description'],
        prizePlayersCount: json['prize_players_count'],
        prizeDistribution:
            (json['prize_distribution'] as List).map((e) => PrizeShare.fromJson(e)).toList(),
        registeredCount: json['registered_count'],
      );
}

class TournamentDetail extends Tournament {
  final List<PublicRegistration> registrations;
  final List<FullRegistration>? adminRegistrations; // non-null only for admins
  final FullRegistration? myRegistration;

  TournamentDetail({
    required super.id,
    required super.title,
    required super.cap,
    required super.entryFeeEur,
    required super.paypalLink,
    required super.startDate,
    required super.endDate,
    required super.rulesDescription,
    required super.prizePlayersCount,
    required super.prizeDistribution,
    required super.registeredCount,
    required this.registrations,
    this.adminRegistrations,
    this.myRegistration,
  });

  factory TournamentDetail.fromJson(Map<String, dynamic> json) {
    final base = Tournament.fromJson(json);
    final adminList = json['admin_registrations'] as List?;
    return TournamentDetail(
      id: base.id,
      title: base.title,
      cap: base.cap,
      entryFeeEur: base.entryFeeEur,
      paypalLink: base.paypalLink,
      startDate: base.startDate,
      endDate: base.endDate,
      rulesDescription: base.rulesDescription,
      prizePlayersCount: base.prizePlayersCount,
      prizeDistribution: base.prizeDistribution,
      registeredCount: base.registeredCount,
      registrations: (json['registrations'] as List? ?? [])
          .map((e) => PublicRegistration.fromJson(e))
          .toList(),
      adminRegistrations:
          adminList?.map((e) => FullRegistration.fromJson(e)).toList(),
      myRegistration: json['my_registration'] == null
          ? null
          : FullRegistration.fromJson(json['my_registration']),
    );
  }
}
