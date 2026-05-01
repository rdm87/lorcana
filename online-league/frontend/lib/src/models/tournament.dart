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

class FullRegistration extends PublicRegistration {
  final int tournamentId;
  final int? userId;
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

class MatchPlayer {
  final int id;
  final String firstName;
  final String lastName;
  MatchPlayer({required this.id, required this.firstName, required this.lastName});
  factory MatchPlayer.fromJson(Map<String, dynamic> json) =>
      MatchPlayer(id: json['id'], firstName: json['first_name'], lastName: json['last_name']);
  String get fullName => '$firstName $lastName';
}

class MatchResult {
  final int id;
  final int tournamentId;
  final int reg1Id;
  final int reg2Id;
  final MatchPlayer reg1;
  final MatchPlayer reg2;
  final int? gamesReg1;
  final int? gamesReg2;
  final int? proposedByRegId;
  final String resultStatus; // pending | proposed | confirmed

  MatchResult({
    required this.id,
    required this.tournamentId,
    required this.reg1Id,
    required this.reg2Id,
    required this.reg1,
    required this.reg2,
    this.gamesReg1,
    this.gamesReg2,
    this.proposedByRegId,
    required this.resultStatus,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) => MatchResult(
        id: json['id'],
        tournamentId: json['tournament_id'],
        reg1Id: json['reg1_id'],
        reg2Id: json['reg2_id'],
        reg1: MatchPlayer.fromJson(json['reg1']),
        reg2: MatchPlayer.fromJson(json['reg2']),
        gamesReg1: json['games_reg1'] as int?,
        gamesReg2: json['games_reg2'] as int?,
        proposedByRegId: json['proposed_by_reg_id'] as int?,
        resultStatus: json['result_status'],
      );
}

class StandingEntry {
  final int regId;
  final String firstName;
  final String lastName;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int points;
  final int gamesWon;
  final int gamesLost;

  StandingEntry({
    required this.regId,
    required this.firstName,
    required this.lastName,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.points,
    required this.gamesWon,
    required this.gamesLost,
  });

  factory StandingEntry.fromJson(Map<String, dynamic> json) => StandingEntry(
        regId: json['reg_id'],
        firstName: json['first_name'],
        lastName: json['last_name'],
        played: json['played'],
        wins: json['wins'],
        draws: json['draws'],
        losses: json['losses'],
        points: json['points'],
        gamesWon: json['games_won'],
        gamesLost: json['games_lost'],
      );

  String get fullName => '$firstName $lastName';
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
  final String status; // registration | ongoing | completed

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
    required this.status,
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
        status: json['status'] ?? 'registration',
      );
}

class TournamentDetail extends Tournament {
  final List<PublicRegistration> registrations;
  final List<FullRegistration>? adminRegistrations;
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
    required super.status,
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
      status: base.status,
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
