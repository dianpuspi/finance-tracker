import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';
import 'transaction_detail_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  List<Transaction> _transactions = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Memuat data user dan transaksi
  Future<void> _loadData() async {
    try {
      final transactions = await _storageService.getTransactions();
      final user = await _storageService.getCurrentUser();
      
      double income = 0;
      double expense = 0;
      
      // Hitung total pemasukan dan pengeluaran
      for (var transaction in transactions) {
        if (transaction.type == 'income') {
          income += transaction.amount;
        } else {
          expense += transaction.amount;
        }
      }
      
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _totalIncome = income;
          _totalExpense = expense;
          _balance = income - expense;
          _user = user;
        });
      }
    } catch (e) {
      print('Error loading home data: $e');
      if (mounted) _showSnackBar('Gagal memuat data');
    }
  }

  // Format angka menjadi format mata uang Rupiah
  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  // Menentukan salam berdasarkan waktu saat ini
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  // Menghitung statistik transaksi hari ini
  Map<String, double> _getTodayStats() {
    final today = DateTime.now();
    double todayIncome = 0;
    double todayExpense = 0;

    for (var transaction in _transactions) {
      if (transaction.dateTime.year == today.year &&
          transaction.dateTime.month == today.month &&
          transaction.dateTime.day == today.day) {
        if (transaction.type == 'income') {
          todayIncome += transaction.amount;
        } else {
          todayExpense += transaction.amount;
        }
      }
    }

    return {'income': todayIncome, 'expense': todayExpense};
  }

  // Menghitung statistik transaksi bulan ini
  Map<String, double> _getMonthlyStats() {
    final now = DateTime.now();
    double monthlyIncome = 0;
    double monthlyExpense = 0;

    for (var transaction in _transactions) {
      if (transaction.dateTime.year == now.year &&
          transaction.dateTime.month == now.month) {
        if (transaction.type == 'income') {
          monthlyIncome += transaction.amount;
        } else {
          monthlyExpense += transaction.amount;
        }
      }
    }

    return {'income': monthlyIncome, 'expense': monthlyExpense};
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
    final recentTransactions = _transactions.reversed.take(5).toList(); // 5 transaksi terbaru
    final todayStats = _getTodayStats();
    final monthlyStats = _getMonthlyStats();

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.orange,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBalanceCard(),
                    const SizedBox(height: 24),
                    _buildStatsRow(todayStats, monthlyStats),
                    const SizedBox(height: 24),
                    _buildRecentTransactionsHeader(),
                    _buildTransactionsList(recentTransactions),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // AppBar dengan background gradient dan sapaan
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.darkBlue,
      title: const Text(
        'Beranda',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.darkBlue, Color(0xFF1a1d22)],
            ),
          ),
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _user?.name ?? 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card untuk menampilkan saldo total
  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.orange, Color(0xFFFF9A76)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Saldo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      _balance >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _balance >= 0 ? 'Surplus' : 'Defisit',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _formatCurrency(_balance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                  'Pemasukan',
                  _totalIncome,
                  Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBalanceItem(
                  'Pengeluaran',
                  _totalExpense,
                  Icons.arrow_upward,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Item untuk menampilkan pemasukan/pengeluaran dalam card saldo
  Widget _buildBalanceItem(String title, double amount, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Baris untuk menampilkan statistik pengeluaran
  Widget _buildStatsRow(Map<String, double> todayStats, Map<String, double> monthlyStats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Pengeluaran Hari Ini',
            todayStats['expense']!,
            Icons.today,
            AppColors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Pengeluaran Bulan Ini',
            monthlyStats['expense']!,
            Icons.calendar_month,
            AppColors.darkBlue,
          ),
        ),
      ],
    );
  }

  // Card untuk menampilkan statistik
  Widget _buildStatCard(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 12,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Header untuk bagian transaksi terbaru
  Widget _buildRecentTransactionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Transaksi Terbaru',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (_transactions.isNotEmpty)
          TextButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
              _loadData(); // Refresh data setelah kembali
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.orange),
            child: const Row(
              children: [
                Text('Lihat Semua'),
                SizedBox(width: 1),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
      ],
    );
  }

  // List untuk menampilkan transaksi terbaru
  Widget _buildTransactionsList(List<Transaction> recentTransactions) {
    if (recentTransactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
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
                'Tambahkan transaksi pertama Anda',
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

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentTransactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildTransactionCard(recentTransactions[index]),
    );
  }

  // Card untuk menampilkan detail transaksi
  Widget _buildTransactionCard(Transaction transaction) {
    final bool isIncome = transaction.type == 'income';
    final Color color = isIncome ? AppColors.green : AppColors.red;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          transaction.category,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text(
              DateFormat('dd MMM yyyy, HH:mm').format(transaction.dateTime),
              style: TextStyle(
                color: AppColors.grey.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'} ${_formatCurrency(transaction.amount)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: () => _navigateToDetail(transaction),
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
    if (result == true) _loadData(); // Refresh data setelah kembali
  }
}