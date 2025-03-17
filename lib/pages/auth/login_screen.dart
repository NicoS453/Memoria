import 'package:awokwokwao/pages/main/home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../style/auth_service.dart';
import '../../style/handle.dart';
import 'register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isObscure = true;

  // Fungsi untuk menangani login
  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password tidak boleh kosong')),
      );
      return;
    }

    try {
      final authResponse =
      await AuthService().signInWithEmailPassword(email, password);

      if (authResponse.session != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login berhasil!')),
        );

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login gagal: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 75),
              Center(
                child: CircleAvatar(
                  radius: 70,
                  backgroundImage: AssetImage('assets/logo/logoreal.png'),
                  backgroundColor: Color(0xFFED9455),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Memoria',
                  style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.primary,
                      fontFamily: 'horizon'),
                ),
              ),
              const SizedBox(height: 5),
              Center(
                child: Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 33,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              CustomTextfield(
                textCapitalization: TextCapitalization.none,
                controller: emailController,
                textInputAction: TextInputAction.next,
                textInputType: TextInputType.emailAddress,
                hintText: 'Email',
                icon: Icon(Icons.email, color: colorScheme.primary),
              ),
              const SizedBox(height: 20),
              CustomTextfield(
                textCapitalization: TextCapitalization.none,
                controller: passwordController,
                textInputAction: TextInputAction.done,
                textInputType: TextInputType.visiblePassword,
                hintText: 'Password',
                isObscure: isObscure,
                visible: true,
                onPressed: () {
                  setState(() {
                    isObscure = !isObscure;
                  });
                },
                icon: Icon(Icons.lock, color: colorScheme.primary),
              ),
              const SizedBox(height: 40),
              Center(
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    foregroundColor: colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 100, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    minimumSize: const Size(200, 50),
                  ),
                  child: const Text('Login',style: TextStyle(color: Colors.white),),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Belum punya akun? ",
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                    GestureDetector(
                      onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const RegisterScreen()),
                          );
                      },
                      child: Text(
                        'Daftar',
                        style: TextStyle(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          themeNotifier.toggleTheme();
        },
        backgroundColor: colorScheme.primary,
        child: Icon(
          themeNotifier.themeMode == ThemeMode.dark
              ? Icons.dark_mode // Ikon untuk mode gelap
              : Icons.light_mode, // Ikon untuk mode terang
          color: Colors.white,
        ),
      ),

    );
  }
}
