import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/transaction_model.dart';
import '../utils/app_theme.dart';
import 'transaction_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final StorageService _storageService = StorageService();
  List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];
  String _selectedType = 'all';
  String _selectedPeriod = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Memuat data transaksi dari storage
  Future<void> _loadData() async {
    try {
      final transactions = await _storageService.getTransactions();
      if (mounted) {
        setState(() {
          _allTransactions = transactions.reversed.toList(); // Terbaru di atas
          _applyFilters();
        });
      }
    } catch (e) {
      print('Error loading history: $e');
      if (mounted) _showSnackBar('Gagal memuat riwayat');
    }
  }

  // Menerapkan filter berdasarkan tipe dan periode
  void _applyFilters() {
    List<Transaction> filtered = List.from(_allTransactions);

    // Filter berdasarkan tipe transaksi
    if (_selectedType != 'all') {
      filtered = filtered.where((t) => t.type == _selectedType).toList();
    }

    // Filter berdasarkan periode waktu
    if (_selectedPeriod != 'all') {
      final now = DateTime.now();
      filtered = filtered.where((t) {
        switch (_selectedPeriod) {
          case 'today':
            return t.dateTime.year == now.year &&
                t.dateTime.month == now.month &&
                t.dateTime.day == now.day;
          case 'week':
            final weekAgo = now.subtract(const Duration(days: 7));
            return t.dateTime.isAfter(weekAgo);
          case 'month':
            return t.dateTime.year == now.year && t.dateTime.month == now.month;
          default:
            return true;
        }
      }).toList();
    }

    setState(() => _filteredTransactions = filtered);
  }

  // Format angka menjadi format mata uang Rupiah
  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: _filteredTransactions.isEmpty
                ? _buildEmptyState()
                : _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  // Bagian filter dropdown
  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterDropdown(
              label: 'Tipe',
              value: _selectedType,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Semua')),
                DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
                DropdownMenuItem(value: 'expense', child: Text('Pengeluaran')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                  _applyFilters();
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFilterDropdown(
              label: 'Periode',
              value: _selectedPeriod,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Semua')),
                DropdownMenuItem(value: 'today', child: Text('Hari Ini')),
                DropdownMenuItem(value: 'week', child: Text('Minggu Ini')),
                DropdownMenuItem(value: 'month', child: Text('Bulan Ini')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
                  _applyFilters();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget dropdown untuk filter
  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.grey.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.orange, width: 2),
            ),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  // Tampilan ketika tidak ada transaksi
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
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
            'Transaksi Anda akan muncul di sini',
            style: TextStyle(
              color: AppColors.grey.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // List transaksi dengan refresh indicator
  Widget _buildTransactionList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.orange,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredTransactions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => 
            _buildTransactionCard(_filteredTransactions[index]),
      ),
    );
  }

  // Card untuk menampilkan detail transaksi
  Widget _buildTransactionCard(Transaction transaction) {
    final bool isIncome = transaction.type == 'income';
    final Color color = isIncome ? AppColors.green : AppColors.red;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToDetail(transaction),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon kategori
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              
              // Detail transaksi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.category,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.description,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.grey.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(transaction.dateTime),
                          style: TextStyle(
                            color: AppColors.grey.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              
              // Jumlah dan status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'} ${_formatCurrency(transaction.amount)}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isIncome ? 'Masuk' : 'Keluar',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigasi ke halaman detail transaksi
  Future<void> _navigateToDetail(Transaction transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionDetailScreen(transaction: transaction),
      ),
    );
    if (result == true) _loadData(); // Refresh data jika ada perubahan
  }
}