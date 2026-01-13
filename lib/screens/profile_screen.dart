import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storageService = StorageService();
  User? _user;
  bool _isFeedbackExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Memuat data user saat ini
  Future<void> _loadData() async {
    try {
      final user = await _storageService.getCurrentUser();
      if (mounted) {
        setState(() => _user = user);
      }
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        _showSnackBar('Gagal memuat profil', AppColors.red);
      }
    }
  }

  // Menampilkan snackbar pesan
  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Membuka URL dengan error handling
  Future<void> _launchUrl(Uri url, String errorMessage) async {
    setState(() => _isFeedbackExpanded = false);
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar(errorMessage, AppColors.red);
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan', AppColors.red);
    }
  }

  // Mengirim feedback melalui WhatsApp
  Future<void> _sendFeedbackViaWhatsApp() async {
    const phoneNumber = '6288233165112';
    final username = _user?.username ?? 'user';
    final message = 'FEEDBACK FINANCE TRACKER\n\nDari: ${_user?.name ?? 'User'} (@$username)\n\n[Tuliskan feedback Anda di sini]\n\nTerima kasih.';
    final url = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');
    
    await _launchUrl(url, 'Tidak dapat membuka WhatsApp');
  }

  // Mengirim feedback melalui Email
  Future<void> _sendFeedbackViaEmail() async {
    const email = 'dianpus2424@gmail.com';
    final subject = 'Feedback Finance Tracker';
    final username = _user?.username ?? 'user';
    final body = 'FEEDBACK FINANCE TRACKER\n\nDari: ${_user?.name ?? 'User'} (@$username)\n\n[Tuliskan feedback Anda di sini]\n\nTerima kasih.';
    final url = Uri.parse('mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');
    
    await _launchUrl(url, 'Tidak dapat membuka aplikasi email');
  }

  // Mengganti username
  Future<void> _changeUsername() async {
    final usernameController = TextEditingController(text: _user?.username);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ganti Username'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(
                labelText: 'Username Baru',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.person_outline),
                hintText: 'Masukkan username baru',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Username harus minimal 3 karakter dan belum digunakan user lain.',
              style: TextStyle(fontSize: 12, color: AppColors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newUsername = usernameController.text.trim();
              if (newUsername.isEmpty || newUsername.length < 3) {
                _showSnackBar('Username minimal 3 karakter', AppColors.red);
                return;
              }
              Navigator.pop(context, newUsername);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final success = await _storageService.updateUsername(result);
        
        if (success) {
          _showSnackBar('Username berhasil diubah', AppColors.green);
          _loadData();
        } else {
          _showSnackBar('Username sudah digunakan', AppColors.red);
        }
      } catch (e) {
        print('Error updating username: $e');
        _showSnackBar('Terjadi kesalahan', AppColors.red);
      }
    }
  }

  // Mengganti password
  Future<void> _changePassword() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ganti Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password Lama',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password Baru',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock_open),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.check_circle_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (oldPasswordController.text != _user?.password) {
                _showSnackBar('Password lama salah', AppColors.red);
                return;
              }

              if (newPasswordController.text != confirmPasswordController.text) {
                _showSnackBar('Password baru tidak cocok', AppColors.red);
                return;
              }

              if (newPasswordController.text.isEmpty || newPasswordController.text.length < 6) {
                _showSnackBar('Password minimal 6 karakter', AppColors.red);
                return;
              }

              Navigator.pop(context, true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final success = await _storageService.updateUserPassword(newPasswordController.text);
        
        if (success) {
          _showSnackBar('Password berhasil diubah', AppColors.green);
          _loadData();
        } else {
          _showSnackBar('Gagal mengubah password', AppColors.red);
        }
      } catch (e) {
        print('Error updating password: $e');
        _showSnackBar('Terjadi kesalahan', AppColors.red);
      }
    }
  }

  // Menampilkan dialog FAQ
  void _showFAQ() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.orange),
            SizedBox(width: 12),
            Text('FAQ / Bantuan'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFAQItem(
                'Bagaimana cara menambah transaksi?',
                'Tekan tombol + di bagian bawah tengah layar, lalu isi form transaksi.',
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                'Bagaimana cara mengedit transaksi?',
                'Tap pada transaksi yang ingin diedit, lalu tekan icon edit di pojok kanan atas.',
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                'Bagaimana cara menghapus transaksi?',
                'Tap pada transaksi, lalu tekan icon hapus di pojok kanan atas.',
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                'Bagaimana cara melihat laporan?',
                'Buka tab Laporan di menu bawah untuk melihat statistik dan grafik keuangan.',
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                'Apakah data saya aman?',
                'Ya, semua data disimpan secara lokal di perangkat Anda dan tidak dikirim ke server.',
              ),
              const SizedBox(height: 16),
              _buildFAQItem(
                'Bagaimana cara ganti password?',
                'Buka Profil > Ganti Password, masukkan password lama dan password baru.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // Widget untuk item FAQ
  Widget _buildFAQItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          answer,
          style: const TextStyle(
            color: AppColors.grey,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // Logout user
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _storageService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  // Menampilkan dialog tentang aplikasi
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: AppColors.orange,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Finance Tracker'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text(
              'Versi 1.0.0',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Aplikasi pencatatan keuangan untuk mengelola pemasukan dan pengeluaran.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.person_outline, size: 18, color: AppColors.grey),
                SizedBox(width: 8),
                Text(
                  'Developer',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Dian Puspitasari',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'NPM: 23670171',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Profil Saya'),
        centerTitle: false,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Overlay untuk feedback FAB
          if (_isFeedbackExpanded)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _isFeedbackExpanded = false),
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),
          
          // Konten utama
          SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildMenuCard(
                        icon: Icons.person_outline,
                        iconColor: AppColors.orange,
                        title: 'Ganti Username',
                        subtitle: 'Ubah username akun Anda',
                        onTap: _changeUsername,
                      ),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        icon: Icons.lock_outline,
                        iconColor: AppColors.orange,
                        title: 'Ganti Password',
                        subtitle: 'Ubah password akun Anda',
                        onTap: _changePassword,
                      ),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        icon: Icons.help_outline,
                        iconColor: AppColors.darkBlue,
                        title: 'FAQ / Bantuan',
                        subtitle: 'Pertanyaan yang sering ditanyakan',
                        onTap: _showFAQ,
                      ),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        icon: Icons.info_outline,
                        iconColor: AppColors.darkBlue,
                        title: 'Tentang Aplikasi',
                        subtitle: 'Informasi aplikasi & developer',
                        onTap: _showAboutDialog,
                      ),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        icon: Icons.logout,
                        iconColor: AppColors.red,
                        title: 'Keluar',
                        subtitle: 'Logout dari akun',
                        onTap: _logout,
                        textColor: AppColors.red,
                      ),
                      const SizedBox(height: 100), // Spasi untuk FAB
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Floating Action Button untuk feedback
          _buildFeedbackFAB(),
        ],
      ),
    );
  }

  // Header profil dengan foto dan info user
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.darkBlue,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.person,
                  size: 45,
                  color: Colors.white,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _user?.name ?? 'User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '@${_user?.username ?? ''}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FAB untuk mengirim feedback (WhatsApp/Email)
  Widget _buildFeedbackFAB() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // FAB WhatsApp
          AnimatedScale(
            scale: _isFeedbackExpanded ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: _isFeedbackExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: FloatingActionButton(
                heroTag: 'whatsapp',
                onPressed: _sendFeedbackViaWhatsApp,
                backgroundColor: const Color(0xFF25D366),
                child: const Icon(Icons.chat, color: Colors.white),
              ),
            ),
          ),
          if (_isFeedbackExpanded) const SizedBox(height: 12),
          
          // FAB Email
          AnimatedScale(
            scale: _isFeedbackExpanded ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: _isFeedbackExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: FloatingActionButton(
                heroTag: 'email',
                onPressed: _sendFeedbackViaEmail,
                backgroundColor: AppColors.darkBlue,
                child: const Icon(Icons.email, color: Colors.white),
              ),
            ),
          ),
          if (_isFeedbackExpanded) const SizedBox(height: 12),
          
          // Main FAB
          FloatingActionButton(
            heroTag: 'feedback_main',
            onPressed: () => setState(() => _isFeedbackExpanded = !_isFeedbackExpanded),
            backgroundColor: AppColors.orange,
            child: AnimatedRotation(
              turns: _isFeedbackExpanded ? 0.125 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isFeedbackExpanded ? Icons.close : Icons.feedback_outlined,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card untuk menu profil
  Widget _buildMenuCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: textColor ?? AppColors.darkBlue,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.grey,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: textColor ?? AppColors.grey,
        ),
      ),
    );
  }
}