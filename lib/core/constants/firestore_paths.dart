/// Semua path koleksi Firestore dipusatkan di sini.
/// Jika ada perubahan nama koleksi, cukup ubah di file ini.
class FirestorePaths {
  FirestorePaths._();

  // Root Collections
  static const String users = 'users';
  static const String items = 'items';
  static const String guilds = 'guilds';
  static const String verifications = 'verifications';
  static const String disputes = 'disputes';
  static const String transactionLogs = 'transaction_logs';
  static const String rateLimits = 'rate_limits';
  static const String admins = 'admins';

  // Subcollections
  static const String claims = 'claims';
  static const String chats = 'chats';
  static const String members = 'members';

  // Document Paths (helpers)
  static String userDoc(String uid) => '$users/$uid';
  static String itemDoc(String itemId) => '$items/$itemId';
  static String guildDoc(String guildId) => '$guilds/$guildId';
  static String verifDoc(String verifId) => '$verifications/$verifId';

  // Subcollection Paths
  static String itemClaims(String itemId) => '$items/$itemId/$claims';
  static String itemChats(String itemId) => '$items/$itemId/$chats';
  static String guildMembers(String guildId) => '$guilds/$guildId/$members';
  static String claimDoc(String itemId, String claimId) =>
      '$items/$itemId/$claims/$claimId';
}