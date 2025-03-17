import 'package:flutter/material.dart';

class FavoriteImagesScreen extends StatelessWidget {
  final List<String> favoriteImages; // Daftar URL atau path gambar favorit

  const FavoriteImagesScreen({super.key, required this.favoriteImages});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gambar Favorit")),
      body: favoriteImages.isEmpty
          ? const Center(
              child: Text(
                "Tidak ada gambar favorit",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Jumlah kolom dalam grid
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: favoriteImages.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Tambahkan aksi jika gambar diklik
                  },
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        favoriteImages[
                            index], // Gambar dari URL atau path lokal
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
