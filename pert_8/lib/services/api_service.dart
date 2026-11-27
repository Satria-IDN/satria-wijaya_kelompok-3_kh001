import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/user_model.dart';

class ApiService {
  static const int nimN = 48; // 3 digit terakhir NIM 20240801048
  static const int nimUserId = 1000 + nimN; // 1048

  static const String baseUrl = 'https://jsonplaceholder.typicode.com';
  static const String fileName = 'users.json';

  static Future<File> getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }

  static Future<String> getJsonFilePath() async {
    final file = await getLocalFile();
    return file.path;
  }

  static Future<File> _ensureFileInitialized() async {
    final file = await getLocalFile();

    if (!await file.exists()) {
      List<dynamic> initialData = [];
      try {
        final response = await http
            .get(Uri.parse('$baseUrl/users'))
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          initialData = jsonDecode(response.body) as List<dynamic>;
        }
      } catch (_) {
        initialData = initialData = List<dynamic>.from(_defaultUsers);
      }

      if (initialData.isEmpty) {
        initialData = initialData = List<dynamic>.from(_defaultUsers);
      }

      final hasNimUser = initialData.any((u) => _parseId(u['id']) == nimUserId);
      if (!hasNimUser) {
        initialData.add({
          'id': nimUserId,
          'name': 'Satria Wijaya',
          'email': 'satria.wijaya@student.esaunggul.ac.id',
          'address': {'city': 'Bekasi'},
        });
      }

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(initialData),
      );
    }

    return file;
  }

  static int _parseId(dynamic rawId) {
    if (rawId is int) return rawId;
    return int.tryParse(rawId?.toString() ?? '') ?? 0;
  }

  static Future<List<dynamic>> _readJsonFile() async {
    final file = await _ensureFileInitialized();
    final contents = await file.readAsString();
    return jsonDecode(contents) as List<dynamic>;
  }

  static Future<void> _writeJsonFile(List<dynamic> users) async {
    final file = await getLocalFile();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(users),
    );
  }

  // GET: Mengambil semua data User
  static Future<List<User>> getUsers() async {
    await Future.delayed(const Duration(milliseconds: 250));
    final rawList = await _readJsonFile();
    return rawList
        .map((item) => User.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // GET: Mengambil detail User berdasarkan ID
  static Future<User> getUser(int id) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final users = await _readJsonFile();

    final found = users.firstWhere(
          (element) => _parseId(element['id']) == id,
      orElse: () => null,
    );

    if (found != null) {
      return User.fromJson(Map<String, dynamic>.from(found));
    }

    throw Exception('Data pengguna dengan ID $id tidak ditemukan');
  }

  // POST: Menambahkan User baru berdasarkan ID dari NIM (1048)
  static Future<Map<String, dynamic>> createUser(
      String name,
      String email, {
        String city = 'Bekasi',
      }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final users = await _readJsonFile();

    final existingIds = users.map<int>((u) => _parseId(u['id'])).toSet();

    int assignedId = nimUserId;
    if (existingIds.contains(nimUserId)) {
      int candidate = nimUserId + 1;
      while (existingIds.contains(candidate)) {
        candidate++;
      }
      assignedId = candidate;
    }

    final newUser = {
      'id': assignedId,
      'name': name,
      'email': email,
      'address': {'city': city},
    };

    users.add(newUser);
    await _writeJsonFile(users);

    return newUser;
  }

  // PUT: Memperbarui nama dan email User
  static Future<Map<String, dynamic>> updateUser(
      int id,
      String name,
      String email,
      ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final users = await _readJsonFile();

    final index = users.indexWhere((element) => _parseId(element['id']) == id);
    if (index == -1) {
      throw Exception('Gagal memperbarui pengguna: ID $id tidak ditemukan');
    }

    final existing = Map<String, dynamic>.from(users[index]);
    existing['name'] = name;
    existing['email'] = email;

    users[index] = existing;
    await _writeJsonFile(users);

    return existing;
  }

  // PATCH: Memperbarui nama User dengan menambahkan teks " - Flutter Developer"
  static Future<Map<String, dynamic>> patchUser(
      int id,
      String name,
      ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final users = await _readJsonFile();

    final index = users.indexWhere((element) => _parseId(element['id']) == id);
    if (index == -1) {
      throw Exception('Gagal mengubah nama pengguna: ID $id tidak ditemukan');
    }

    const suffix = ' - Flutter Developer';
    final cleanName = name.trim();
    final updatedName =
    cleanName.endsWith(suffix) ? cleanName : '$cleanName$suffix';

    final existing = Map<String, dynamic>.from(users[index]);
    existing['name'] = updatedName;

    users[index] = existing;
    await _writeJsonFile(users);

    return existing;
  }

  // DELETE: Menghapus User berdasarkan ID
  static Future<bool> deleteUser(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final users = await _readJsonFile();

    final index = users.indexWhere((element) => _parseId(element['id']) == id);
    if (index == -1) {
      return false;
    }

    users.removeAt(index);
    await _writeJsonFile(users);

    return true;
  }

  static Future<void> resetToDefault() async {
    final file = await getLocalFile();
    if (await file.exists()) {
      await file.delete();
    }
    await _ensureFileInitialized();
  }

  static final List<Map<String, dynamic>> _defaultUsers = [
  {
  'id': 1,
  'name': 'Budi',
  'email': 'Budi@gmail.com',
  'address': {'city': 'Solo'},
  },
  {
  'id': 2,
  'name': 'Anton',
  'email': 'Notna@rocket.id',
  'address': {'city': 'Jakarta'},
  },
  {
  'id': nimUserId,
  'name': 'Satria Wijaya',
  'email': 'satria.wijaya@student.esaunggul.ac.id',
  'address': {'city': 'Bekasi'},
  },
  ];
}