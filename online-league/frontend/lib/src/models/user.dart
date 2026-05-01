class AppUser {
  final int id;
  final String discordId;
  final String username;
  final String? avatarUrl;
  final bool isAdmin;
  AppUser({required this.id, required this.discordId, required this.username, this.avatarUrl, required this.isAdmin});
  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'], discordId: json['discord_id'], username: json['username'], avatarUrl: json['avatar_url'], isAdmin: json['is_admin'] ?? false,
  );
}
