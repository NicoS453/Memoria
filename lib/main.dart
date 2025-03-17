import 'package:awokwokwao/style/appcolor.dart';
import 'package:awokwokwao/style/auth_gate.dart';
import 'package:awokwokwao/style/handle.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://whhrgqgleoclsabgmgna.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndoaHJncWdsZW9jbHNhYmdtZ25hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkyMzc0OTcsImV4cCI6MjA1NDgxMzQ5N30.qJpNBAfTxCSSRJuJ6yf-7rjuzHancuSJTD5civI2zDE',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>(
          create: (_) => ThemeNotifier(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil ThemeNotifier dari Provider
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.light,
      darkTheme: AppThemes.dark,
      themeMode: themeNotifier.themeMode, // Mode tema sesuai dengan ThemeNotifier
      home: const AuthGate(), // Halaman utama aplikasi
    );
  }
}
