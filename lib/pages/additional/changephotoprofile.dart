import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangeProfilePicture extends StatefulWidget {
  final String profilePic;

  const ChangeProfilePicture({super.key, required this.profilePic});

  @override
  State<ChangeProfilePicture> createState() => _ChangeProfilePictureState();
}

class _ChangeProfilePictureState extends State<ChangeProfilePicture> {
  File? _imageFile;
  String? imageUrl;
  String? previousFileName;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    imageUrl = widget.profilePic; // Inisialisasi avatar saat halaman dibuka
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> uploadImage() async {
    if (_imageFile == null) return;

    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        debugPrint("User belum login");
        return;
      }

      final fileName =
          'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'uploads/$fileName';

      // Hapus foto profil lama jika ada
      if (previousFileName != null) {
        await supabase.storage.from('profile').remove(['uploads/$previousFileName']);
      }

      // Upload foto baru
      await supabase.storage.from('profile').upload(filePath, _imageFile!);

      final newImageUrl = supabase.storage.from('profile').getPublicUrl(filePath);

      // Perbarui database dengan nama file baru
      await supabase
          .from('profile')
          .update({'avatar_url': fileName}).eq('id', user.id);

      setState(() {
        imageUrl = newImageUrl;
        previousFileName = fileName;
        _imageFile = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
      );

      // Kembali ke halaman sebelumnya
      Navigator.pop(context, newImageUrl);
    } catch (e) {
      debugPrint("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunggah gambar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Foto Profil")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Center(
              child: CircleAvatar(
                radius: MediaQuery.of(context).size.height / 4,
                backgroundColor: Color(0xFFFBA518),
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : (imageUrl != null && imageUrl!.isNotEmpty
                    ? NetworkImage(imageUrl!)
                    : null) as ImageProvider?,
                child: (_imageFile == null && (imageUrl == null || imageUrl!.isEmpty))
                    ? const Icon(Icons.account_circle,
                    size: 120, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickImage,
              child: const Text("Pilih Gambar"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: uploadImage,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Simpan", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
