import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final TextEditingController namaController = TextEditingController();
  final TextEditingController nimController = TextEditingController();
  final TextEditingController lokasiController = TextEditingController();
  final TextEditingController matkulController = TextEditingController();

  String kehadiran = 'Hadir';

  Future<void> simpanData() async {
    await FirebaseFirestore.instance.collection('praktikum').add({
      'nama': namaController.text.trim(),
      'nim': nimController.text.trim(),
      'lokasi': lokasiController.text.trim(),
      'mata_kuliah': matkulController.text.trim(),
      'keterangan_kehadiran': kehadiran,
      'waktu': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Praktikum Firebase'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            controller: namaController,
            decoration: const InputDecoration(labelText: 'Nama'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: nimController,
            decoration: const InputDecoration(labelText: 'NIM'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: lokasiController,
            decoration: const InputDecoration(labelText: 'Lokasi'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: matkulController,
            decoration: const InputDecoration(labelText: 'Mata Kuliah'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: kehadiran,
            decoration: const InputDecoration(labelText: 'Keterangan Kehadiran'),
            items: const [
              DropdownMenuItem(value: 'Hadir', child: Text('Hadir')),
              DropdownMenuItem(value: 'Izin', child: Text('Izin')),
              DropdownMenuItem(value: 'Sakit', child: Text('Sakit')),
            ],
            onChanged: (val) {
              setState(() {
                kehadiran = val!;
              });
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {

              if (namaController.text.trim().isEmpty ||
                  nimController.text.trim().isEmpty ||
                  lokasiController.text.trim().isEmpty ||
                  matkulController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Field tidak boleh kosong!')),
                );
                return;
              }

              try {
                await simpanData();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data berhasil dikirim!')),
                );

                namaController.clear();
                nimController.clear();
                lokasiController.clear();
                matkulController.clear();
                setState(() {
                  kehadiran = 'Hadir';
                });
              } catch (e) {

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal mengirim data: $e')),
                );
              }
            },
            child: const Text('Simpan ke Firebase'),
          ),
        ],
      ),
    );
  }
}