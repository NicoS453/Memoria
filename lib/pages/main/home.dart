import 'package:awokwokwao/pages/main/profile.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../additional/imagedetail.dart';
import 'setting.dart';
import '../additional/uploadimage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _imageData = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchFilesInUploads(); // Fetch pertama kali
  }

  Future<void> fetchFilesInUploads() async {
    try {
      // Menggunakan JOIN untuk mendapatkan username dari tabel profiles
      final response = await Supabase.instance.client
          .from('image')
          .select('file_name, email, uuid, id, uploaded_at, description, profile(username)')
          .order('uploaded_at', ascending: false);

      final List<dynamic> data = response;

      if (data.isNotEmpty) {
        List<Map<String, dynamic>> imageData = [];

        for (var file in data) {
          final String fileName = file['file_name'];
          final String email = file['email'];
          final String id = file['id'];
          final DateTime uploadedAt = DateTime.parse(file['uploaded_at']);
          final String description = file['description'];
          final String uuid = file['uuid'];
          final String username = file['profile']['username'] ?? 'Unknown'; // Username dari tabel profiles

          final String url = Supabase.instance.client.storage
              .from('image')
              .getPublicUrl('uploads/$fileName');

          imageData.add({
            'url': url,
            'username': username, // Username sudah ada di sini
            'id': id,
            'uuid': uuid,
            'description': description,
            'uploadedAt': uploadedAt,
          });
        }

        setState(() {
          _imageData = imageData;
        });
      } else {
        print('Tidak ada file di tabel metadata.');
      }
    } catch (error) {
      print('Terjadi kesalahan: $error');
    }
  }


  void _changeIndex(int index) {
    setState(() {
      _currentIndex = 0;
    });

    switch (index) {
      case 0:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => HomeScreen()));
        break;
      case 1:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => ProfileScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Memoria',
            style:
                TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Horizon')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 30),
            onPressed: () async {
              await fetchFilesInUploads();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _imageData.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(), // Loading spinner
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _imageData.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageDetail(
                              imageUrl: _imageData[index]['url'],
                              caption: _imageData[index]['description'],
                              username: _imageData[index]['username'],
                              uuid: _imageData[index]['uuid'],
                              id: _imageData[index]['id']
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                color: Colors.grey[200],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  _imageData[index]['url'],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.error),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _imageData[index]['description'] ??
                                "No Description",
                            // Tampilkan deskripsi
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UploadImage()),
                ).then((result) {
                  if (result == true) {
                    fetchFilesInUploads(); // Refresh gambar setelah kembali
                  }
                });
              },
              backgroundColor: const Color(0xFFF4D793),
              child: const Icon(
                Icons.add,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _changeIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
