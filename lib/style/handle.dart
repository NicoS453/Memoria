import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomTextfield extends StatelessWidget {
  const CustomTextfield({
    required this.controller,
    required this.textInputType,
    required this.textInputAction,
    required this.textCapitalization,
    required this.hintText,
    this.icon = const Icon(Icons.person),
    this.isObscure = false,
    this.visible = false,
    this.onPressed,
    super.key,
  });

  final TextEditingController controller;
  final TextInputType textInputType;
  final TextInputAction textInputAction;
  final String hintText;
  final Icon icon;
  final bool isObscure;
  final bool visible;
  final VoidCallback? onPressed;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    // Mengambil warna dari tema aktif
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final hintColor = Theme.of(context).textTheme.bodyMedium?.color;

    return TextField(
      style: TextStyle(color: textColor),
      // Warna teks input
      keyboardType: textInputType,
      controller: controller,
      textInputAction: textInputAction,
      obscureText: isObscure,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        suffixIcon: visible
            ? IconButton(
                onPressed: onPressed,
                icon: Icon(
                  isObscure ? Icons.visibility : Icons.visibility_off,
                  color: primaryColor, // Warna ikon visibility
                ),
              )
            : null,
        hintText: hintText,
        hintStyle: TextStyle(color: hintColor),
        prefixIcon: icon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: primaryColor, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: primaryColor, width: 2.0),
        ),
      ),
    );
  }
}

class CustomText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final String font;

  const CustomText({
    required this.text,
    this.fontSize = 18.0,
    this.fontWeight = FontWeight.normal,
    this.font = '',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: font,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }
}

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  ThemeNotifier() {
    _loadThemeMode();
  }

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveThemeMode();
    notifyListeners();
  }

  void _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void _saveThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
  }
}
