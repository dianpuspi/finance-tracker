import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/transaction_model.dart';
import '../utils/app_theme.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final StorageService _storageService = StorageService();

  String _selectedType = 'expense';
  String _selectedCategory = '';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Daftar kategori transaksi
  final List<String> _incomeCategories = [
    'Gaji', 'Bonus', 'Investasi', 'Bisnis', 'Hadiah', 'Lainnya',
  ];

  final List<String> _expenseCategories = [
    'Makanan', 'Transportasi', 'Belanja', 'Tagihan', 'Hiburan', 
    'Kesehatan', 'Pendidikan', 'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Inisialisasi data untuk mode edit
  void _initializeData() {
    if (widget.transaction != null) {
      _selectedType = widget.transaction!.type;
      _selectedCategory = widget.transaction!.category;
      _amountController.text = widget.transaction!.amount.toString();
      _descriptionController.text = widget.transaction!.description;
      _selectedDate = widget.transaction!.dateTime;
      _selectedTime = TimeOfDay.fromDateTime(widget.transaction!.dateTime);
    } else {
      _selectedCategory = _expenseCategories[0];
    }
  }

  // Memilih tanggal
  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.orange,
            onPrimary: Colors.white,
            onSurface: AppColors.darkBlue,
          ),
        ),
        child: child!,
      ),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  // Memilih waktu
  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.orange,
            onPrimary: Colors.white,
            onSurface: AppColors.darkBlue,
          ),
        ),
        child: child!,
      ),
    );

    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  // Menyimpan atau mengupdate transaksi
  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final dateTime = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute,
    );

    final transaction = Transaction(
      id: widget.transaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedType,
      amount: double.parse(_amountController.text),
      category: _selectedCategory,
      description: _descriptionController.text,
      dateTime: dateTime,
    );

    final bool isEdit = widget.transaction != null;
    
    if (isEdit) {
      await _storageService.updateTransaction(transaction);
    } else {
      await _storageService.addTransaction(transaction);
    }

    if (mounted) {
      _showSnackBar(
        isEdit ? 'Transaksi berhasil diupdate' : 'Transaksi berhasil ditambahkan',
      );
      Navigator.pop(context, true);
    }
  }

  // Menampilkan snackbar feedback
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _selectedType == 'income' ? _incomeCategories : _expenseCategories;
    
    // Reset kategori jika tidak sesuai dengan tipe transaksi
    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = categories[0];
    }

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: Text(widget.transaction != null ? 'Edit Transaksi' : 'Tambah Transaksi'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Tipe Transaksi'),
              const SizedBox(height: 12),
              _buildTypeSelector(),
              const SizedBox(height: 24),
              _buildSectionTitle('Nominal'),
              const SizedBox(height: 12),
              _buildAmountField(),
              const SizedBox(height: 24),
              _buildSectionTitle('Kategori'),
              const SizedBox(height: 12),
              _buildCategoryDropdown(categories),
              const SizedBox(height: 24),
              _buildSectionTitle('Keterangan'),
              const SizedBox(height: 12),
              _buildDescriptionField(),
              const SizedBox(height: 24),
              _buildSectionTitle('Tanggal & Waktu'),
              const SizedBox(height: 12),
              _buildDateTimePicker(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // Widget judul bagian
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  // Selector tipe transaksi (Pengeluaran/Pemasukan)
  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeButton(
            'Pengeluaran', 'expense', Icons.arrow_upward_rounded, AppColors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTypeButton(
            'Pemasukan', 'income', Icons.arrow_downward_rounded, AppColors.green,
          ),
        ),
      ],
    );
  }

  // Button untuk memilih tipe transaksi
  Widget _buildTypeButton(String label, String type, IconData icon, Color color) {
    final bool isSelected = _selectedType == type;
    
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : AppColors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : AppColors.grey, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Field input nominal
  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: 'Masukkan nominal',
        prefixText: 'Rp ',
        prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.orange, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Nominal tidak boleh kosong';
        }
        if (double.tryParse(value) == null || double.parse(value) <= 0) {
          return 'Nominal harus lebih dari 0';
        }
        return null;
      },
    );
  }

  // Dropdown untuk memilih kategori
  Widget _buildCategoryDropdown(List<String> categories) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        hintText: 'Pilih kategori',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.orange, width: 2),
        ),
      ),
      items: categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCategory = value!),
    );
  }

  // Field input keterangan
  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Masukkan keterangan',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.orange, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Keterangan tidak boleh kosong';
        }
        return null;
      },
    );
  }

  // Picker untuk tanggal dan waktu
  Widget _buildDateTimePicker() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildPickerButton(
            icon: Icons.calendar_today_rounded,
            label: DateFormat('dd MMM yyyy').format(_selectedDate),
            onTap: _selectDate,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPickerButton(
            icon: Icons.access_time_rounded,
            label: _selectedTime.format(context),
            onTap: _selectTime,
          ),
        ),
      ],
    );
  }

  // Button untuk memilih tanggal/waktu
  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.grey.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Button untuk menyimpan transaksi
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: Text(
          widget.transaction != null ? 'Update Transaksi' : 'Simpan Transaksi',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}