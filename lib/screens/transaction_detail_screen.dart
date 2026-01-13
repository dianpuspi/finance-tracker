import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/transaction_model.dart';
import '../services/storage_service.dart';
import '../utils/app_theme.dart';
import 'add_transaction_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  // Format angka menjadi format mata uang Rupiah
  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  // Menghapus transaksi dengan konfirmasi
  Future<void> _deleteTransaction(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Transaksi'),
        content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final storageService = StorageService();
        final success = await storageService.deleteTransaction(transaction.id);
        
        if (success && context.mounted) {
          _showSnackBar(context, 'Transaksi berhasil dihapus');
          Navigator.pop(context, true);
        } else if (context.mounted) {
          _showSnackBar(context, 'Gagal menghapus transaksi');
        }
      } catch (e) {
        print('Error deleting transaction: $e');
        if (context.mounted) {
          _showSnackBar(context, 'Terjadi kesalahan');
        }
      }
    }
  }

  // Menampilkan snackbar pesan
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Membagikan detail transaksi ke WhatsApp
  Future<void> _shareToWhatsApp(BuildContext context) async {
    final bool isIncome = transaction.type == 'income';
    final String type = isIncome ? 'Pemasukan' : 'Pengeluaran';
    
    final message = '''
📊 *FINANCE TRACKER*
━━━━━━━━━━━━━━━━━━━━━━

*Tipe:* $type
*Kategori:* ${transaction.category}
*Nominal:* ${_formatCurrency(transaction.amount)}
*Keterangan:* ${transaction.description}
*Tanggal:* ${DateFormat('dd MMMM yyyy, HH:mm').format(transaction.dateTime)}

━━━━━━━━━━━━━━━━━━━━━━
Dibuat dengan Finance Tracker
    ''';

    final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          _showSnackBar(context, 'Tidak dapat membuka WhatsApp');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Terjadi kesalahan');
      }
    }
  }

  // Navigasi ke halaman edit transaksi
  Future<void> _navigateToEdit(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(transaction: transaction),
      ),
    );
    if (result == true && context.mounted) {
      Navigator.pop(context, true); // Kembali dengan status refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.type == 'income';
    final Color color = isIncome ? AppColors.green : AppColors.red;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit',
            onPressed: () => _navigateToEdit(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            tooltip: 'Hapus',
            onPressed: () => _deleteTransaction(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAmountCard(isIncome, color),
            const SizedBox(height: 16),
            _buildDetailsCard(),
            const SizedBox(height: 16),
            _buildShareCard(context),
          ],
        ),
      ),
    );
  }

  // Card untuk menampilkan jumlah dan tipe transaksi
  Widget _buildAmountCard(bool isIncome, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: color,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isIncome ? 'Pemasukan' : 'Pengeluaran',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${isIncome ? '+' : '-'} ${_formatCurrency(transaction.amount)}',
              style: TextStyle(
                color: color,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card untuk menampilkan detail lengkap transaksi
  Widget _buildDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              'Kategori',
              transaction.category,
              Icons.category_rounded,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Keterangan',
              transaction.description,
              Icons.description_rounded,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Tanggal',
              DateFormat('dd MMMM yyyy').format(transaction.dateTime),
              Icons.calendar_today_rounded,
            ),
            const Divider(height: 24),
            _buildDetailRow(
              'Waktu',
              DateFormat('HH:mm').format(transaction.dateTime),
              Icons.access_time_rounded,
            ),
          ],
        ),
      ),
    );
  }

  // Row untuk menampilkan satu item detail
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.orange, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Card untuk berbagi transaksi ke WhatsApp
  Widget _buildShareCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.share_rounded,
                    color: Color(0xFF25D366),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Bagikan Transaksi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _shareToWhatsApp(context),
                icon: const Icon(Icons.chat_rounded, size: 20),
                label: const Text(
                  'Kirim ke WhatsApp',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}