import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/admin.dart';

class AdminService {
  static const int nimN = 48; // 3 digit terakhir NIM 20240801048
  static const int nimAdminId = 2000 + nimN; // 2048

  static const String fileName = 'admins.json';

  static Future<File> getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$fileName');
  }

  static Future<String> getJsonFilePath() async {
    final file = await getLocalFile();
    return file.path;
  }

  static int _parseId(dynamic rawId) {
    if (rawId is int) return rawId;
    return int.tryParse(rawId?.toString() ?? '') ?? 0;
  }

  static Future<File> _ensureFileInitialized() async {
    final file = await getLocalFile();
    if (!await file.exists()) {
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(_defaultAdmins),
      );
    }
    return file;
  }

  static Future<List<dynamic>> _readJsonFile() async {
    final file = await _ensureFileInitialized();
    final contents = await file.readAsString();
    return jsonDecode(contents) as List<dynamic>;
  }

  static Future<void> _writeJsonFile(List<dynamic> admins) async {
    final file = await getLocalFile();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(admins),
    );
  }

  // Mengambil seluruh data Admin
  static Future<List<Admin>> getAdmins() async {
    await Future.delayed(const Duration(milliseconds: 250));
    final rawList = await _readJsonFile();
    return rawList
        .map((item) => Admin.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // Mengambil satu data Admin berdasarkan ID
  static Future<Admin> getAdmin(int id) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final admins = await _readJsonFile();

    final found = admins.firstWhere(
          (element) => _parseId(element['id']) == id,
      orElse: () => null,
    );

    if (found != null) {
      return Admin.fromJson(Map<String, dynamic>.from(found));
    }

    throw Exception('Data admin dengan ID $id tidak ditemukan');
  }

  // Menghapus data Admin berdasarkan ID
  static Future<bool> deleteAdmin(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final admins = await _readJsonFile();

    final index = admins.indexWhere((element) => _parseId(element['id']) == id);
    if (index == -1) {
      return false;
    }

    admins.removeAt(index);
    await _writeJsonFile(admins);
    return true;
  }

  static Future<void> resetToDefault() async {
    final file = await getLocalFile();
    if (await file.exists()) {
      await file.delete();
    }
    await _ensureFileInitialized();
  }

  static final List<Map<String, dynamic>> _defaultAdmins = [
  {
  'id': nimAdminId,
  'name': 'Admin Satria (2048)',
  'email': 'admin.2048@esaunggul.ac.id',
  'department': 'Data Engineering & IT Support',
  },
  {
  'id': 2001,
  'name': 'Anton',
  'email': 'Notna@esaunggul.ac.id',
  'department': 'Academic Information System',
  },
  {
  'id': 2002,
  'name': 'Raka Pratama',
  'email': 'raka.pratama@esaunggul.ac.id',
  'department': 'Network & Infrastructure',
  },
  ];
}