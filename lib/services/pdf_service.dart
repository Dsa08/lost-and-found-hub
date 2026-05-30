import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/item_model.dart';

/// **PdfService**
/// Layanan utilitas untuk membuat (generate) dokumen PDF.
/// Digunakan untuk membuat "Sertifikat Serah Terima Barang" sebagai bukti fisik
/// atau digital bahwa barang telah dikembalikan dari penemu ke pemilik asli.
class PdfService {
  /// **Fungsi generateSertifikat**
  /// Membuat layout PDF menggunakan package `pdf` dan memicu dialog Print/Share bawaan OS menggunakan `printing`.
  static Future<void> generateSertifikat({
    required ItemModel item,
    required String namaOwner,
    required String namaFinder,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ──
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue700,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'SERTIFIKAT SERAH TERIMA BARANG',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Lost & Found Hub',
                      style: const pw.TextStyle(
                        fontSize: 13,
                        color: PdfColors.blue100,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // ── Status Badge ──
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green100,
                  borderRadius: pw.BorderRadius.circular(20),
                  border: pw.Border.all(color: PdfColors.green700),
                ),
                child: pw.Text(
                  '✓ BARANG BERHASIL DIKEMBALIKAN',
                  style: pw.TextStyle(
                    color: PdfColors.green800,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),

              pw.SizedBox(height: 20),

              // ── Info Barang ──
              _buildSection('Informasi Barang', [
                _buildRow('Nama Barang', item.judul),
                _buildRow('Kategori', item.kategori.name[0].toUpperCase() + item.kategori.name.substring(1)),
                _buildRow('Deskripsi', item.deskripsi),
                _buildRow('Lokasi Kejadian', item.lokasi.namaLokasi),
                _buildRow('Tanggal Laporan', _formatDate(item.createdAt)),
              ]),

              pw.SizedBox(height: 16),

              // ── Info Pihak ──
              _buildSection('Pihak yang Terlibat', [
                _buildRow('Pemilik Barang (Owner)', namaOwner),
                _buildRow('Penemu Barang (Finder)', namaFinder),
              ]),

              pw.SizedBox(height: 16),

              // ── Info Bounty ──
              if (item.nominalBounty > 0)
                _buildSection('Informasi Bounty', [
                  _buildRow('Nominal Bounty', '${item.nominalBounty} Poin'),
                  _buildRow('Status Jaminan Poin', 'Dicairkan ✓'),
                ]),

              pw.SizedBox(height: 16),

              // ── Tanggal Selesai ──
              _buildSection('Penyelesaian', [
                _buildRow('Tanggal Selesai', _formatDate(DateTime.now())),
                _buildRow('Status Akhir', 'Resolved'),
                _buildRow('ID Laporan', item.itemId),
              ]),

              pw.Spacer(),

              // ── Footer ──
              pw.Divider(color: PdfColors.grey400),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Dokumen ini digenerate otomatis oleh Lost & Found Hub',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    _formatDate(DateTime.now()),
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Simpan dan share PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'sertifikat_${item.itemId.substring(0, 8)}.pdf',
    );
  }

  static pw.Widget _buildSection(String title, List<pw.Widget> rows) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  static pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 160,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
          ),
          pw.Text(': ', style: const pw.TextStyle(fontSize: 11)),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}