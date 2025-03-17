import 'package:awokwokwao/pages/additional/changephotoprofile.dart';
import 'package:awokwokwao/pages/additional/changeusername.dart';
import 'package:awokwokwao/pages/auth/login_screen.dart';
import 'package:awokwokwao/pages/main/home.dart';
import 'package:awokwokwao/style/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../style/handle.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  Map<String, dynamic>? userProfile;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        debugPrint("User belum login");
        return;
      }

      final response = await supabase
          .from('profile')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          userProfile = response;
        });
      } else {
        debugPrint("Profil tidak ditemukan");
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        ),
        title: const Text("Setting"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity, // Lebar penuh sesuai layar
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30), // Padding diperbesar
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    _buildProfileSection(context),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _buildSettingsOptions(context, themeNotifier),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeProfilePicture(
                        profilePic: userProfile?['avatar_url'] != null
                            ? Supabase.instance.client.storage
                                .from('profile')
                                .getPublicUrl(
                                    'uploads/${userProfile!['avatar_url']}')
                            : Supabase.instance.client.storage
                                .from('image')
                                .getPublicUrl('logo.png'),
                      ),
                    ),
                  ).then((_) {
                    fetchUserProfile(); // Refresh data setelah kembali dari ChangeProfilePicture
                  });
                },
                child: CircleAvatar(
                  radius: 75,
                  backgroundColor: const Color(0xFFFBA518),
                  backgroundImage: userProfile?['avatar_url'] != null
                      ? NetworkImage(
                          Supabase.instance.client.storage
                              .from('profile')
                              .getPublicUrl(
                                  'uploads/${userProfile!['avatar_url']}'),
                        )
                      : NetworkImage(
                          Supabase.instance.client.storage
                              .from('image')
                              .getPublicUrl('logo.png'),
                        ),
                ),
              ),
              Positioned(
                bottom: 5,
                right: 10,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeProfilePicture(
                          profilePic: userProfile?['avatar_url'] != null
                              ? Supabase.instance.client.storage
                                  .from('profile')
                                  .getPublicUrl(
                                      'uploads/${userProfile!['avatar_url']}')
                              : Supabase.instance.client.storage
                                  .from('image')
                                  .getPublicUrl('logo.png'),
                        ),
                      ),
                    ).then((_) {
                      fetchUserProfile();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 5,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // **Memusatkan Username**
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min, // Membuat ukuran sekecil kontennya
            children: [
              Text(
                userProfile?['username'] ?? "Username",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(width: 5), // Jarak kecil antara teks dan ikon
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeUsername(),
                    ),
                  ).then((_) {
                    fetchUserProfile(); // Refresh data setelah kembali dari ChangeProfilePicture
                  });
                },
                child: Icon(
                  Icons.border_color,
                  size: 15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        // **Memusatkan Email**
        Center(
          child: Text(
            userProfile?['email'] ?? "Email",
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsOptions(
      BuildContext context, ThemeNotifier themeNotifier) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Tema Gelap',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          value: themeNotifier.themeMode == ThemeMode.dark,
          onChanged: (value) {
            themeNotifier.toggleTheme();
          },
        ),
        ListTile(
          title: const Text("Ganti Foto Profile",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeProfilePicture(
                    profilePic: userProfile?['avatar_url'] != null
                        ? Supabase.instance.client.storage
                            .from('profile')
                            .getPublicUrl(
                                'uploads/${userProfile!['avatar_url']}')
                        : Supabase.instance.client.storage
                            .from('image')
                            .getPublicUrl('logo.png'),
                  ),
                ));
          },
        ),
        ListTile(
          title: const Text("Ganti Username",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ChangeUsername()));
          },
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: () => _showSignOutDialog(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
          ),
          icon: const Icon(Icons.logout, color: Colors.white), // Ikon Logout
          label: const Text(
            'Sign Out',
            style: TextStyle(color: Colors.white),
          ),
        ),

      ],
    );
  }

  Future<void> _showSignOutDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Sign Out'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                await _logout();
              },
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      await AuthService().signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal keluar: ${e.toString()}')),
      );
    }
  }
}
