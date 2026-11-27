import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'models/admin.dart';
import 'models/user_model.dart';
import 'services/admin_service.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale locale = const Locale('id');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'User & Admin Manager (NIM 048)',
      locale: locale,
      supportedLocales: const [
        Locale('id'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomeScreen(
        onLanguageChanged: (value) {
          setState(() {
            locale = Locale(value);
          });
        },
      ),
    );
  }
}

// ==========================================
// HALAMAN UTAMA: DAFTAR USER & DAFTAR ADMIN
// ==========================================

class HomeScreen extends StatefulWidget {
  final Function(String) onLanguageChanged;

  const HomeScreen({
    super.key,
    required this.onLanguageChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentTab = 0; // 0 = Users, 1 = Admins

  late Future<List<User>> futureUsers;
  late Future<List<Admin>> futureAdmins;

  final lookupIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureUsers = ApiService.getUsers();
    futureAdmins = AdminService.getAdmins();
  }

  @override
  void dispose() {
    lookupIdController.dispose();
    super.dispose();
  }

  void refreshAll() {
    setState(() {
      futureUsers = ApiService.getUsers();
      futureAdmins = AdminService.getAdmins();
    });
  }

  Future<void> _openDetailById() async {
    final id = int.tryParse(lookupIdController.text.trim());
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan ID angka yang valid')),
      );
      return;
    }

    if (currentTab == 0) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserDetailScreen(userId: id),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminDetailScreen(
            adminId: id,
            onDeleted: refreshAll,
          ),
        ),
      );
    }
    refreshAll();
  }

  Future<void> _confirmDeleteAdmin(Admin admin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Admin'),
        content: Text(
          'Hapus Admin "${admin.name}" dengan ID ${admin.id}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final deleted = await AdminService.deleteAdmin(admin.id);
      refreshAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deleted
                  ? 'Admin ID ${admin.id} berhasil dihapus'
                  : 'Admin ID ${admin.id} tidak ditemukan',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User & Admin Manager (NIM 048)'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: refreshAll,
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset Data Awal',
            onPressed: () async {
              await ApiService.resetToDefault();
              await AdminService.resetToDefault();
              refreshAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data User & Admin di-reset ke awal'),
                  ),
                );
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: widget.onLanguageChanged,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'id', child: Text('Bahasa Indonesia')),
              PopupMenuItem(value: 'en', child: Text('English')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ApiTesterScreen(defaultNimUserId: 1048),
            ),
          ).then((_) => refreshAll());
        },
        icon: const Icon(Icons.api),
        label: const Text('Test API User'),
      ),
      body: Column(
        children: [
          // SWITCH TAB: USER vs ADMIN
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Daftar User (ID 1048)'),
                  icon: Icon(Icons.people),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Daftar Admin (ID 2048)'),
                  icon: Icon(Icons.admin_panel_settings),
                ),
              ],
              selected: {currentTab},
              onSelectionChanged: (selection) {
                setState(() {
                  currentTab = selection.first;
                  lookupIdController.clear();
                });
              },
            ),
          ),

          // CARI DETAIL BERDASARKAN ID
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: lookupIdController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      isDense: true,
                      border: const OutlineInputBorder(),
                      hintText: currentTab == 0
                          ? 'Cari Detail User by ID (cth: 1048)'
                          : 'Cari Detail Admin by ID (cth: 2048)',
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _openDetailById,
                  child: const Text('Detail'),
                ),
              ],
            ),
          ),

          // KONTEN DAFTAR
          Expanded(
            child: currentTab == 0
                ? _buildUserList(language)
                : _buildAdminList(language),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(AppLocalizations language) {
    return FutureBuilder<List<User>>(
      future: futureUsers,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(language.errorMessage),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: refreshAll,
                  child: Text(language.retry),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return Center(child: Text(language.noData));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  '${user.name} (ID: ${user.id})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${user.email} • ${user.city}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserDetailScreen(userId: user.id),
                    ),
                  ).then((_) => refreshAll());
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdminList(AppLocalizations language) {
    return FutureBuilder<List<Admin>>(
      future: futureAdmins,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(language.errorMessage),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: refreshAll,
                  child: Text(language.retry),
                ),
              ],
            ),
          );
        }

        final admins = snapshot.data ?? [];
        if (admins.isEmpty) {
          return const Center(child: Text('Tidak ada data Admin'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: admins.length,
          itemBuilder: (context, index) {
            final admin = admins[index];
            final initial =
            admin.name.isNotEmpty ? admin.name[0].toUpperCase() : 'A';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo.shade100,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  '${admin.name} (ID: ${admin.id})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${admin.email} • ${admin.department}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Hapus Admin',
                  onPressed: () => _confirmDeleteAdmin(admin),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminDetailScreen(
                        adminId: admin.id,
                        onDeleted: refreshAll,
                      ),
                    ),
                  ).then((_) => refreshAll());
                },
              ),
            );
          },
        );
      },
    );
  }
}

// ==========================================
// DETAIL USER BERDASARKAN ID
// ==========================================

class UserDetailScreen extends StatelessWidget {
  final int userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail User #$userId'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<User>(
        future: ApiService.getUser(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final user = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: ${user.id}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      'Nama: ${user.name}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Email: ${user.email}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Kota: ${user.city}', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// DETAIL ADMIN BERDASARKAN ID + HAPUS ADMIN
// ==========================================

class AdminDetailScreen extends StatefulWidget {
  final int adminId;
  final VoidCallback? onDeleted;

  const AdminDetailScreen({
    super.key,
    required this.adminId,
    this.onDeleted,
  });

  @override
  State<AdminDetailScreen> createState() => _AdminDetailScreenState();
}

class _AdminDetailScreenState extends State<AdminDetailScreen> {
  late Future<Admin> futureAdmin;
  bool isDeleting = false;

  @override
  void initState() {
    super.initState();
    futureAdmin = AdminService.getAdmin(widget.adminId);
  }

  Future<void> _handleDelete() async {
    setState(() => isDeleting = true);
    final success = await AdminService.deleteAdmin(widget.adminId);
    setState(() => isDeleting = false);

    if (!mounted) return;

    if (success) {
      widget.onDeleted?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Admin ID ${widget.adminId} berhasil dihapus')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Admin ID ${widget.adminId} tidak ditemukan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Admin #${widget.adminId}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Admin>(
        future: futureAdmin,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final admin = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${admin.id}',
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          'Nama: ${admin.name}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Email: ${admin.email}',
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('Departemen: ${admin.department}',
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: isDeleting ? null : _handleDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.delete),
                  label: Text(
                    isDeleting ? 'Menghapus...' : 'Hapus Admin ID ${admin.id}',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// API TESTER USER (GET, POST, PUT, PATCH, DELETE)
// ==========================================

class ApiTesterScreen extends StatefulWidget {
  final int defaultNimUserId;

  const ApiTesterScreen({
    super.key,
    required this.defaultNimUserId,
  });

  @override
  State<ApiTesterScreen> createState() => _ApiTesterScreenState();
}

class _ApiTesterScreenState extends State<ApiTesterScreen> {
  String selectedMethod = 'GET';
  final idController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  bool isLoading = false;
  dynamic result;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    idController.text = widget.defaultNimUserId.toString();
  }

  @override
  void dispose() {
    idController.dispose();
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> sendRequest() async {
    final id = int.tryParse(idController.text.trim());

    if (selectedMethod != 'POST' && id == null) {
      _showSnack('Masukkan ID pengguna yang valid');
      return;
    }
    if (selectedMethod != 'GET' &&
        selectedMethod != 'DELETE' &&
        nameController.text.trim().isEmpty) {
      _showSnack('Nama tidak boleh kosong');
      return;
    }
    if ((selectedMethod == 'POST' || selectedMethod == 'PUT') &&
        emailController.text.trim().isEmpty) {
      _showSnack('Email tidak boleh kosong');
      return;
    }

    setState(() {
      isLoading = true;
      result = null;
      errorMessage = null;
    });

    try {
      dynamic response;
      switch (selectedMethod) {
        case 'GET':
          final user = await ApiService.getUser(id!);
          response = user.toJson();
          break;
        case 'POST':
          response = await ApiService.createUser(
            nameController.text.trim(),
            emailController.text.trim(),
          );
          break;
        case 'PUT':
          response = await ApiService.updateUser(
            id!,
            nameController.text.trim(),
            emailController.text.trim(),
          );
          break;
        case 'PATCH':
          response = await ApiService.patchUser(
            id!,
            nameController.text.trim(),
          );
          break;
        case 'DELETE':
          final success = await ApiService.deleteUser(id!);
          response = {
            'success': success,
            'message': success
                ? 'Pengguna berhasil dihapus'
                : 'Gagal menghapus pengguna',
          };
          break;
      }

      setState(() => result = response);
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isGet = selectedMethod == 'GET';
    final isPost = selectedMethod == 'POST';
    final isPut = selectedMethod == 'PUT';
    final isDelete = selectedMethod == 'DELETE';

    return Scaffold(
      appBar: AppBar(
        title: const Text('API Method Tester (User)'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: selectedMethod,
              decoration: const InputDecoration(
                labelText: 'HTTP Method',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'GET', child: Text('GET - Ambil User')),
                DropdownMenuItem(
                    value: 'POST', child: Text('POST - Tambah User (ID 1048)')),
                DropdownMenuItem(
                    value: 'PUT', child: Text('PUT - Update Nama & Email')),
                DropdownMenuItem(
                    value: 'PATCH',
                    child: Text('PATCH - Tambah "- Flutter Developer"')),
                DropdownMenuItem(
                    value: 'DELETE', child: Text('DELETE - Hapus User')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    selectedMethod = val;
                    result = null;
                    errorMessage = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            if (!isPost) ...[
              TextField(
                controller: idController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'User ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (!isGet && !isDelete) ...[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (isPost || isPut) ...[
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : sendRequest,
                icon: const Icon(Icons.send),
                label: Text(isLoading ? 'Mengirim...' : 'Kirim Request'),
              ),
            ),
            const SizedBox(height: 24),
            if (result != null || errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: errorMessage != null
                      ? Colors.red.withValues(alpha: 0.08)
                      : Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: errorMessage != null ? Colors.red : Colors.green,
                  ),
                ),
                child: SelectableText(
                  errorMessage ??
                      const JsonEncoder.withIndent('  ').convert(result),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}