import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../utils/ui_helpers.dart';
import '../utils/validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import 'auth/login_page.dart';
import 'help_page.dart';
import 'owner/my_venues_page.dart';

// Tab "Akun": isi halaman saja (tanpa Scaffold), karena dipasang sebagai
// tab di dalam Scaffold milik HomePage (pelanggan) dan OwnerHomePage (pemilik).
class AccountPage extends StatefulWidget {
  final bool isAdminView;
  const AccountPage({super.key, this.isAdminView = false});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _saving = false;

  AppUser get _user => AuthService.instance.currentUser!;
  Color get _accent =>
      widget.isAdminView ? Colors.indigo.shade600 : Colors.pink.shade300;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _user.fullName);
    _phoneController = TextEditingController(text: _user.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await AuthService.instance.updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (mounted) showMessage(context, 'Profil berhasil disimpan');
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: _accent.withOpacity(0.12),
        child: Icon(icon, color: _accent, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
    );
  }

  Widget _buildMenu(AppUser user) {
    // Admin tidak memakai panduan maupun menu pemilik: hanya info akun.
    if (widget.isAdminView) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          if (!widget.isAdminView) ...[
            _menuTile(
              icon: Icons.storefront_outlined,
              title: user.isOwner ? 'Kelola Lapangan' : 'Daftarkan Lapanganmu',
              subtitle: user.isOwner
                  ? 'Atur pesanan, lihat ulasan & rating lapangan/kelasmu'
                  : 'Punya lapangan padel? Ajukan agar bisa disewa',
              onTap: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MyVenuesPage()));
                if (mounted) setState(() {});
              },
            ),
            const Divider(height: 1),
          ],
          _menuTile(
            icon: Icons.help_outline,
            title: 'Pusat Bantuan',
            subtitle: 'Panduan penggunaan, FAQ, dan unduh PDF',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    HelpPage(role: user.isOwner ? 'pemilik' : 'pelanggan'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: _accent,
                      child: Text(
                        user.initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.fullName.isEmpty ? '(tanpa nama)' : user.fullName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Text(user.email,
                        style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.roleLabel,
                        style: TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildMenu(user),
                const SizedBox(height: 24),
                const Text('Ubah Profil',
                    style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _nameController,
                        label: 'Nama Lengkap',
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            Validators.required(v, field: 'Nama lengkap'),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _phoneController,
                        label: 'Nomor HP',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: Validators.phone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: 'Simpan Perubahan',
                  loading: _saving,
                  onPressed: _save,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _logout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Keluar',
                      style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}