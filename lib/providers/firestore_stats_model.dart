/// **AppStats (Model Statistik Global)**
/// Model sederhana untuk menampung agregasi data statistik dari Firestore.
/// Menggunakan query `.count()` sehingga TIDAK perlu download seluruh dokumen.
/// Digunakan oleh Admin Dashboard untuk menampilkan ringkasan data.
class AppStats {
  final int totalBarang;
  final int totalSelesai;
  final int totalGuild;
  final int totalUsers;
  final int openDisputes;

  const AppStats({
    this.totalBarang = 0,
    this.totalSelesai = 0,
    this.totalGuild = 0,
    this.totalUsers = 0,
    this.openDisputes = 0,
  });
}