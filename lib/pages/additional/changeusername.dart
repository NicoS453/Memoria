import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangeUsername extends StatefulWidget {
  const ChangeUsername({super.key});

  @override
  State<ChangeUsername> createState() => _ChangeUsernameState();
}

class _ChangeUsernameState extends State<ChangeUsername> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isValid = true;
  String? _errorMessage;

  void _validateUsername(String value) {
    final trimmedValue = value.trim(); // Hilangkan spasi di awal dan akhir
    final regex = RegExp(r'^[a-zA-Z0-9_.]+$'); // Hanya huruf, angka, titik, _

    setState(() {
      if (trimmedValue.isEmpty) {
        _isValid = false;
        _errorMessage = "Username tidak boleh kosong";
      } else if (trimmedValue.length < 5) {
        _isValid = false;
        _errorMessage = "Username harus minimal 5 karakter";
      } else if (value.contains(' ')) { // Cek jika ada spasi
        _isValid = false;
        _errorMessage = "Username tidak boleh mengandung spasi";
      } else if (!regex.hasMatch(trimmedValue)) {
        _isValid = false;
        _errorMessage = "Username hanya boleh A-Z, 0-9, . dan _";
      }else if(trimmedValue.length >10){
        _isValid= false;
        _errorMessage = "maksimal 10 karakter";
      }
      else {
        _isValid = true;
        _errorMessage = null;
      }
    });
  }

  Future<void> _updateDisplayName(String username) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null || user.id.isEmpty) {
        throw Exception('User belum terautentikasi atau ID tidak valid');
      }

      debugPrint("User ID: ${user.id}");
      debugPrint("Username Baru: $username");

      // Perbarui username di database
      await supabase.from('profile').upsert(
        {
          'id': user.id,
          'username': username,
        },
        onConflict: 'id',
      );

      // Ambil data terbaru setelah perubahan
      final updatedProfile = await supabase
          .from('profile')
          .select('username')
          .eq('id', user.id)
          .single();

      debugPrint("Username setelah update: ${updatedProfile['username']}");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username berhasil diperbarui')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Gagal memperbarui nama pengguna: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengupdate data: $e')),
      );
    }
  }

  void _validateAndSaveUsername() {
    final username = _usernameController.text.trim();
    _validateUsername(username); // Validasi username

    if (_isValid) {
      _updateDisplayName(username);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Username',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nama pengguna',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameController,
              textCapitalization: TextCapitalization.none,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.text,
              onChanged: _validateUsername,
              decoration: InputDecoration(
                hintText: 'username',
                errorText: _isValid ? null : _errorMessage,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person)
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Username hanya boleh berisi huruf (A-Z, a-z), angka (0-9), titik (.), dan garis bawah (_). Minimal 5 karakter.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Center(
              child: ElevatedButton(
                onPressed: _validateAndSaveUsername,
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
