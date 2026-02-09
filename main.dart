import 'package:flutter/material.dart';
// Check karein ke login_screen.dart isi path par hai
import 'screens/login_screen.dart'; 

// Agar DBHelper main mein use karna ho to import karein, warna zaroorat nahi
// import 'screens/db_helper.dart'; 

Future<void> main() async {
  // 1. Zaroori line: SQLite aur Flutter Engine ko connect karne ke liye
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Agar app start hote hi koi database initialize karna ho to yahan await kar sakte hain
    runApp(const AssessmentApp());
  } catch (e) {
    debugPrint("App Startup Error: $e");
  }
}

class AssessmentApp extends StatelessWidget {
  const AssessmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Assessment System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A7CFF)),
        useMaterial3: true,
      ),
      // Aapka login screen home set hai, ye theek hai
      home: const LoginScreen(),
    );
  }
}