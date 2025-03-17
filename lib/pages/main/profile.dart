import 'package:awokwokwao/pages/additional/changedesc.dart';
import 'package:awokwokwao/pages/additional/changephotoprofile.dart';
import 'package:awokwokwao/pages/additional/changeusername.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../additional/uploadimage.dart';
import '../additional/userimagedetail.dart';
import 'home.dart';
import 'setting.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final int _currentIndex = 1;
  String _username = "Loading...";
  String _profileImage = "logoreal.png";
  String _desc = "Loading...";
  String _createdAt = ""; // Untuk menyimpan tanggal bergabung
  List<Map<String, dynamic>> _userImages = [];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchUserImages();
  }

  // Fungsi untuk menghitung jumlah hari sejak akun dibuat
  String calculateDaysSince(String createdAt) {
    if (createdAt.isEmpty) return "0 hari";
    DateTime createdDate = DateTime.parse(createdAt);
    DateTime now = DateTime.now();
    int daysDifference = now.difference(createdDate).inDays;
    return "$daysDifference hari";
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _username = "Guest";
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('profile')
          .select('username, avatar_url, bio, created_at')
          .eq('id', user.id)
          .single();

      setState(() {
        _username = response['username'] ?? "Unknown";
        _profileImage = response['avatar_url'] ?? "logoreal.png";
        _desc = response['bio'] ?? "Tidak ada deskrpsi di sini";
        _createdAt = response['created_at'] ?? "";
      });
    } catch (error) {
      print('Error fetching profile: $error');
    }
  }

  Future<void> _fetchUserImages() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('image')
          .select(
              'file_name, email, uuid, id, uploaded_at, description, profile(username)')
          .eq('uuid', user.id)
          .order('uploaded_at', ascending: false);

      if (response.isNotEmpty) {
        List<Map<String, dynamic>> imageData = response.map((img) {
          final String fileName = img['file_name'] ?? '';
          final String description = img['description'] ?? '';
          final String uuid = img['uuid'];
          final String id = img['id'];
          final String username = img['profile']['username'] ?? 'Unknown';
          final String url = Supabase.instance.client.storage
              .from('image')
              .getPublicUrl('uploads/$fileName');
          return {
            'url': url,
            'description': description,
            'uuid': uuid,
            'id': id,
            'username' : username,
          };
        }).toList();

        setState(() {
          _userImages = imageData;
        });
      }
    } catch (error) {
      print('Error fetching images: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    String profileImageUrl = Supabase.instance.client.storage
        .from('profile')
        .getPublicUrl('uploads/$_profileImage');

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profile',
            style:
                TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Horizon')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 30),
            onPressed: () async {
              await _fetchUserProfile();
              if (mounted) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingScreen()));
                _fetchUserProfile();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChangeProfilePicture(profilePic: profileImageUrl),
                  ),
                ).then((_) {
                  _fetchUserProfile(); // Refresh data setelah kembali dari ChangeProfilePicture
                });
              },
              child: Center(
                child: CircleAvatar(
                  radius: 70,
                  backgroundImage: NetworkImage(profileImageUrl),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _username,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Tengahkan row
              children: [
                Column(
                  children: [
                    Text(
                      "${_userImages.length}",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Text("Memori", style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(width: 20),
                Column(
                  children: [
                    Text(
                      calculateDaysSince(_createdAt), // Hitung hari bergabung
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Text("Hari Bergabung",
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeUsername(),
                  ),
                ).then((_) {
                  _fetchUserProfile(); // Refresh data setelah kembali dari ChangeProfilePicture
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                // Warna gelap seperti di gambar
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Edit Username"),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Text(
                    _desc,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeDesc(),
                      ),
                    ).then((_) {
                      _fetchUserProfile(); // Refresh data setelah kembali dari ChangeProfilePicture
                    });
                  },
                  child: Icon(
                    Icons.border_color,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _userImages.isEmpty
                ? Text('Tidak ada memori yang disimpan')
                : SizedBox(
                    width: double.infinity,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8.0),
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _userImages.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserImageDetail(
                                    imageUrl: _userImages[index]['url'],
                                    caption: _userImages[index]['description'],
                                    username: _userImages[index]['username'],
                                    uuid: _userImages[index]['uuid'],
                                    id: _userImages[index]['id']
                                ),
                              ),
                            ).then((result) {
                              if (result == true) {
                                _fetchUserImages(); // Refresh gambar setelah kembali
                              }
                            });
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    _userImages[index]['url'],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4.0, horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _userImages[index]['description'],
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UploadImage()),
          );
          _fetchUserImages(); // Refresh setelah upload gambar
        },
        backgroundColor: const Color(0xFFF4D793),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // Posisi di pojok kanan bawah
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const HomeScreen()));
          } else if (index == 1) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
