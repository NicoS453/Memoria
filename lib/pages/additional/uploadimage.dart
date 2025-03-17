import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadImage extends StatefulWidget {
  const UploadImage({super.key});

  @override
  State<UploadImage> createState() => _UploadImageState();
}

class _UploadImageState extends State<UploadImage> {
  File? _imageFile;
  final TextEditingController textController = TextEditingController();
  bool isUploading = false;

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<File> compressImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return imageFile;

    final compressedBytes = img.encodeJpg(image, quality: 50);
    final compressedFile = File(imageFile.path)
      ..writeAsBytesSync(compressedBytes);

    return compressedFile;
  }

  Future<Size> _getImageSize(File imageFile) async {
    final image = await decodeImageFromList(imageFile.readAsBytesSync());
    return Size(image.width.toDouble(), image.height.toDouble());
  }

  Future<void> uploadImage() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih gambar terlebih dahulu.')),
      );
      return;
    }

    if (textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan deskripsi gambar.')),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final path = 'uploads/$fileName';

    try {
      // Kompres gambar sebelum diunggah
      _imageFile = await compressImage(_imageFile!);

      // Unggah file ke Supabase Storage
      await Supabase.instance.client.storage
          .from('image')
          .upload(path, _imageFile!);

      // Dapatkan email dan user ID pengguna
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final userEmail =
          Supabase.instance.client.auth.currentUser?.email ?? 'Unknown';

      if (userId == null) {
        throw Exception("Pengguna tidak terautentikasi.");
      }

      // Ambil username dari tabel profile
      final response = await Supabase.instance.client
          .from('profile')
          .select('username')
          .eq('id', userId)
          .limit(1)
          .maybeSingle();

      final username = response != null ? response['username'] : 'Unknown';

      // Simpan metadata ke tabel image
      await Supabase.instance.client.from('image').insert({
        'file_name': fileName,
        'email': userEmail,
        'uploaded_at': DateTime.now().toIso8601String(),
        'description': textController.text,
        'username': username,
        'uuid': userId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gambar berhasil diunggah!")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunggah: $e')),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Gambar")),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                if (_imageFile != null)
                  FutureBuilder<Size>(
                    future: _getImageSize(_imageFile!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData) {
                        final originalSize = snapshot.data!;
                        double width = originalSize.width * 0.5;
                        double height = originalSize.height * 0.5;

                        if (width > 400) width = 400;
                        if (height > 550) height = 550;

                        return Column(
                          children: [
                            GestureDetector(
                              onDoubleTap: pickImage,
                              child: Image.file(
                                _imageFile!,
                                width: width,
                                height: height,
                                fit: BoxFit.fitWidth,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text('klik dua kali untuk mengganti gambar'),
                            const SizedBox(height: 20),
                            TextField(
                              controller: textController,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                labelText: "Deskripsi Gambar",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return const CircularProgressIndicator();
                      }
                    },
                  )
                else
                  Column(
                    children: [
                      const SizedBox(height: 50),
                      const Text("Pilih gambar yang akan diunggah"),
                      const SizedBox(height: 50),
                      ElevatedButton.icon(
                        onPressed: pickImage,
                        icon: const Icon(CupertinoIcons.plus),
                        label: const Text("Pilih Gambar"),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                isUploading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: uploadImage,
                        child: const Text('Upload'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
