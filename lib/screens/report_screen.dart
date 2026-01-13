import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storage_service.dart';
import '../models/transaction_model.dart';
import '../utils/app_theme.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final StorageService _storageService = StorageService();
  List<Transaction> _transactions = [];
  DateTime _selectedMonth = DateTime.now();
  double _totalIncome = 0;
  double _totalExpense = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Memuat data transaksi untuk bulan yang dipilih
  Future<void> _loadData() async {
    try {
      final transactions = await _storageService.getTransactions();
      
      // Filter transaksi berdasarkan bulan yang dipilih
      final filteredTransactions = transactions.where((t) {
        return t.dateTime.year == _selectedMonth.year &&
            t.dateTime.month == _selectedMonth.month;
      }).toList();

      double income = 0;
      double expense = 0;

      // Hitung total pemasukan dan pengeluaran
      for (var transaction in filteredTransactions) {
        if (transaction.type == 'income') {
          income += transaction.amount;
        } else {
          expense += transaction.amount;
        }
      }

      if (mounted) {
        setState(() {
          _transactions = filteredTransactions;
          _totalIncome = income;
          _totalExpense = expense;
        });
      }
    } catch (e) {
      print('Error loading report data: $e');
      if (mounted) _showSnackBar('Gagal memuat data laporan');
    }
  }

  // Mengubah bulan yang dipilih (sebelum/sesudah)
  void _changeMonth(int months) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + months,
        1,
      );
    });
    _loadData();
  }

  // Format angka menjadi format mata uang Rupiah
  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  // Menghitung total per kategori berdasarkan tipe transaksi
  Map<String, double> _getCategoryTotals(String type) {
    final Map<String, double> totals = {};
    
    for (var transaction in _transactions) {
      if (transaction.type == type) {
        totals[transaction.category] = 
            (totals[transaction.category] ?? 0) + transaction.amount;
      }
    }
    
    return totals;
  }

  // Membuat teks laporan untuk dibagikan
  String _generateReportText() {
    final monthYear = DateFormat('MMMM yyyy').format(_selectedMonth);
    final balance = _totalIncome - _totalExpense;
    final expenseTotals = _getCategoryTotals('expense');
    final incomeTotals = _getCategoryTotals('income');

    String report = '📊 LAPORAN KEUANGAN\n';
    report += '━━━━━━━━━━━━━━━━━━━━━━\n';
    report += 'Periode: $monthYear\n';
    report += '━━━━━━━━━━━━━━━━━━━━━━\n\n';
    
    report += '💰 RINGKASAN\n';
    report += '━━━━━━━━━━━━━━━━━━━━━━\n';
    report += '📥 Pemasukan: ${_formatCurrency(_totalIncome)}\n';
    report += '📤 Pengeluaran: ${_formatCurrency(_totalExpense)}\n';
    report += '━━━━━━━━━━━━━━━━━━━━━━\n';
    report += '💵 Selisih: ${_formatCurrency(balance)}\n';
    report += balance >= 0 ? '✅ Surplus\n\n' : '⚠️ Defisit\n\n';

    // Tambahkan detail pengeluaran per kategori
    if (expenseTotals.isNotEmpty) {
      report += '📤 PENGELUARAN PER KATEGORI\n';
      report += '━━━━━━━━━━━━━━━━━━━━━━\n';
      expenseTotals.forEach((category, amount) {
        final percentage = (amount / _totalExpense * 100);
        report += '• $category\n';
        report += '  ${_formatCurrency(amount)} (${percentage.toStringAsFixed(1)}%)\n';
      });
      report += '\n';
    }

    // Tambahkan detail pemasukan per kategori
    if (incomeTotals.isNotEmpty) {
      report += '📥 PEMASUKAN PER KATEGORI\n';
      report += '━━━━━━━━━━━━━━━━━━━━━━\n';
      incomeTotals.forEach((category, amount) {
        final percentage = (amount / _totalIncome * 100);
        report += '• $category\n';
        report += '  ${_formatCurrency(amount)} (${percentage.toStringAsFixed(1)}%)\n';
      });
      report += '\n';
    }

    report += '━━━━━━━━━━━━━━━━━━━━━━\n';
    report += 'Dibuat dengan Finance Tracker\n';

    return report;
  }

  // Menampilkan snackbar pesan error
  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Membagikan laporan melalui WhatsApp
  Future<void> _shareViaWhatsApp() async {
    if (_transactions.isEmpty) {
      _showSnackBar('Tidak ada data untuk dibagikan');
      return;
    }

    final reportText = _generateReportText();
    final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(reportText)}');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Tidak dapat membuka WhatsApp');
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseTotals = _getCategoryTotals('expense');
    final incomeTotals = _getCategoryTotals('income');

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.orange,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMonthSelector(),
              const SizedBox(height: 16),
              _buildSummarySection(),
              const SizedBox(height: 16),
              if (expenseTotals.isNotEmpty) ...[
                _buildSectionTitle('Statistik Pengeluaran'),
                const SizedBox(height: 12),
                _buildStatisticsCard(expenseTotals, _totalExpense),
                const SizedBox(height: 16),
              ],
              if (incomeTotals.isNotEmpty) ...[
                _buildSectionTitle('Statistik Pemasukan'),
                const SizedBox(height: 12),
                _buildStatisticsCard(incomeTotals, _totalIncome),
              ],
              if (_transactions.isEmpty) _buildEmptyState(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: _transactions.isNotEmpty ? _buildShareFAB() : null,
    );
  }

  // Selector untuk memilih bulan
  Widget _buildMonthSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 28),
              onPressed: () => _changeMonth(-1), // Bulan sebelumnya
            ),
            Text(
              DateFormat('MMMM yyyy').format(_selectedMonth),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, size: 28),
              onPressed: () => _changeMonth(1), // Bulan berikutnya
            ),
          ],
        ),
      ),
    );
  }

  // Section ringkasan pemasukan, pengeluaran, dan selisih
  Widget _buildSummarySection() {
    final balance = _totalIncome - _totalExpense;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Pemasukan',
                    _totalIncome,
                    AppColors.green,
                    Icons.arrow_downward_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Pengeluaran',
                    _totalExpense,
                    AppColors.red,
                    Icons.arrow_upward_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: balance >= 0 
                      ? [AppColors.green.withOpacity(0.1), AppColors.green.withOpacity(0.05)]
                      : [AppColors.red.withOpacity(0.1), AppColors.red.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: balance >= 0 
                      ? AppColors.green.withOpacity(0.3) 
                      : AppColors.red.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        balance >= 0 
                            ? Icons.trending_up_rounded 
                            : Icons.trending_down_rounded,
                        color: balance >= 0 ? AppColors.green : AppColors.red,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Selisih',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatCurrency(balance),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: balance >= 0 ? AppColors.green : AppColors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card untuk menampilkan pemasukan/pengeluaran
  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Judul untuk section
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // Card untuk menampilkan statistik dengan pie chart
  Widget _buildStatisticsCard(Map<String, double> totals, double total) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: _buildPieChartSections(totals, total),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ..._buildCategoryList(totals, total), // Daftar kategori
          ],
        ),
      ),
    );
  }

  // List kategori dengan persentase
  List<Widget> _buildCategoryList(Map<String, double> totals, double total) {
    return totals.entries.map((entry) {
      final percentage = (entry.value / total * 100);
      final index = totals.keys.toList().indexOf(entry.key);
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getColorForIndex(index),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(entry.key),
              ],
            ),
            Text(
              '${_formatCurrency(entry.value)} (${percentage.toStringAsFixed(1)}%)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }).toList();
  }

  // Tampilan ketika tidak ada transaksi
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 80,
              color: AppColors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada transaksi',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan transaksi untuk melihat laporan',
              style: TextStyle(
                color: AppColors.grey.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FAB untuk membagikan laporan
  Widget _buildShareFAB() {
    return FloatingActionButton.extended(
      onPressed: _shareViaWhatsApp,
      backgroundColor: const Color(0xFF25D366), // Warna WhatsApp
      icon: const Icon(Icons.share_rounded, color: Colors.white),
      label: const Text(
        'Bagikan',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Membuat section untuk pie chart
  List<PieChartSectionData> _buildPieChartSections(Map<String, double> totals, double total) {
    final entries = totals.entries.toList();

    return List.generate(entries.length, (index) {
      final entry = entries[index];
      final percentage = (entry.value / total * 100);
      
      return PieChartSectionData(
        color: _getColorForIndex(index),
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });
  }

  // Mendapatkan warna berdasarkan index (untuk pie chart)
  Color _getColorForIndex(int index) {
    final colors = [
      AppColors.orange,
      AppColors.green,
      AppColors.darkBlue,
      AppColors.lightBlue,
      const Color(0xFF9B59B6), // Purple
      const Color(0xFFE67E22), // Orange
      const Color(0xFF1ABC9C), // Teal
      AppColors.red,
    ];
    return colors[index % colors.length];
  }
}