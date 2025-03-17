import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../style/handle.dart';

class ChangeDesc extends StatefulWidget {
  const ChangeDesc({super.key});

  @override
  State<ChangeDesc> createState() => _ChangeDescState();
}

class _ChangeDescState extends State<ChangeDesc> {
  final TextEditingController _descController = TextEditingController();
  String _hintText = "Loading..."; // Default hint text

  @override
  void initState() {
    super.initState();
    _fetchCurrentBio();
  }

  Future<void> _fetchCurrentBio() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        setState(() {
          _hintText = "Tambahkan deskripsi";
        });
        return;
      }

      final response = await supabase
          .from('profile')
          .select('bio')
          .eq('id', user.id)
          .single();

      setState(() {
        _hintText = "Ganti Bio" ?? "Tambahkan Bio";
      });
    } catch (e) {
      debugPrint("Gagal mengambil bio: $e");
      setState(() {
        _hintText = "Tambahkan deskripsi";
      });
    }
  }

  Future<void> _updateBio(String bio) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('User belum terautentikasi');
      }

      await supabase.from('profile').upsert(
        {'id': user.id, 'bio': bio},
        onConflict: 'id',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deskripsi berhasil diperbarui')),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Gagal memperbarui deskripsi: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengupdate data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Deskripsi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deskripsi baru',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextfield(
              textCapitalization: TextCapitalization.sentences,
              controller: _descController,
              textInputAction: TextInputAction.done,
              textInputType: TextInputType.text,
              hintText: _hintText,
            ),
            const SizedBox(height: 8),
            const Text(
              'Deskripsi bersifat publik dan dapat dilihat oleh orang lain. '
                  'Dilarang mengandung SARA, ujaran kebencian, kata-kata tidak pantas, dan sebagainya.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  final bio = _descController.text.trim();
                  if (bio.isNotEmpty) {
                    _updateBio(bio);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Deskripsi tidak boleh kosong')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child:
                const Text("Simpan", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
