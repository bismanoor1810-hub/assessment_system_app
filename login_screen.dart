import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_helper.dart'; 
import 'assessment_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;
  final dbHelper = DBHelper();

  // Custom Color Palette
  final Color primaryBlue = const Color(0xFF1E3A8A); // Deep Navy Blue
  final Color secondaryBlue = const Color(0xFF3B82F6); // Bright Blue
  final Color lightBg = const Color(0xFFF8FAFC); // Soft Grey/White

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  // --- Functions (Logic same as before) ---
  Future<void> _checkAutoLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedId = prefs.getString('evaluatorId');
    if (savedId != null && mounted) {
      _goToDashboard(savedId);
    }
  }

  Future<void> _handleLogin() async {
    final String emailValue = _emailController.text.trim();
    final String passValue = _passController.text.trim();

    if (emailValue.isEmpty || passValue.isEmpty) {
      _showSnackBar("Fields cannot be empty", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final studentRes = await http.post(
        Uri.parse("https://bgnu.space/api/submit_login"),
        body: {'login': emailValue, 'password': passValue},
      ).timeout(const Duration(seconds: 10));

      final studentData = jsonDecode(studentRes.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (studentData['status'] == true || studentData['status'].toString() == "true") {
        String evaluatorId = (studentData['user_name'] ?? emailValue).toString();
        await prefs.setString('evaluatorId', evaluatorId);
        await prefs.setString('userRole', 'student'); 
        await dbHelper.saveUser(emailValue, passValue);
        _showSnackBar("Student Login Successful!", Colors.green);
        _goToDashboard(evaluatorId);
      } 
      else {
        final teacherRes = await http.post(
          Uri.parse("https://savysquad.com/assessment_system/teacher_login.php"),
          body: {'email': emailValue, 'password': passValue},
        ).timeout(const Duration(seconds: 10));

        final teacherData = jsonDecode(teacherRes.body);

        if (teacherData['status'] == true || teacherData['status'].toString() == "true") {
          String teacherId = (teacherData['name'] ?? emailValue).toString();
          await prefs.setString('evaluatorId', teacherId);
          await prefs.setString('userRole', 'teacher'); 
          _showSnackBar("Teacher Login Successful!", Colors.indigo);
          _goToDashboard(teacherId);
        } else {
          _showSnackBar("Invalid Credentials", Colors.red);
        }
      }
    } catch (e) {
      bool offlineValid = await dbHelper.checkOfflineLogin(emailValue, passValue);
      if (offlineValid) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('evaluatorId', emailValue);
        await prefs.setString('userRole', 'student'); 
        _showSnackBar("Offline Mode: Login Successful", Colors.blue);
        _goToDashboard(emailValue);
      } else {
        _showSnackBar("Connection failed and no local account found.", Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToDashboard(String id) {
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => AssessmentScreen(evaluatorId: id))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- STYLISH UNIVERSITY SECTION ---
              _buildStylishHeader(),
              
              const SizedBox(height: 40),
              
              _buildLogo(),
              const SizedBox(height: 25),
              
              Text(
                "Assessment Portal", 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryBlue, letterSpacing: 0.5)
              ),
              Container(
                margin: const EdgeInsets.only(top: 5),
                height: 2, width: 40, color: secondaryBlue,
              ),
              const SizedBox(height: 40),
              
              _buildInput(_emailController, "Email / Username", Icons.person_outline),
              _buildInput(_passController, "Password", Icons.lock_outline, isPass: true),
              const SizedBox(height: 30),
              
              _buildLoginButton(),
              const SizedBox(height: 20),
              const Text(" Assessment System ", style: TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  // New Stylish Header Widget
  Widget _buildStylishHeader() {
    return Column(
      children: [
        Text(
          "BABA GURU NANAK UNIVERSITY",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22, 
            fontWeight: FontWeight.w900, 
            color: primaryBlue, 
            letterSpacing: 0.8,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(height: 1, width: 30, color: Colors.grey.shade400),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                "NANKANA SAHIB",
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w600, 
                  color: secondaryBlue, 
                  letterSpacing: 4,
                ),
              ),
            ),
            Container(height: 1, width: 30, color: Colors.grey.shade400),
          ],
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white, 
        shape: BoxShape.circle, 
        boxShadow: [
          BoxShadow(color: primaryBlue.withOpacity(0.1), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 10))
        ],
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/bgnu_logo.jpg', 
          fit: BoxFit.contain, 
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.school_rounded, size: 60, color: primaryBlue);
          },
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, IconData icon, {bool isPass = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(15), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))]
      ),
      child: TextField(
        controller: controller,
        obscureText: isPass,
        style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: secondaryBlue, size: 22),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity, 
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(colors: [primaryBlue, const Color(0xFF152C6B)]),
        boxShadow: [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, 
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: _isLoading 
          ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
          : const Text("LOGIN TO PORTAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1)),
      ),
    );
  }

  void _showSnackBar(String m, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m, style: const TextStyle(fontWeight: FontWeight.w500)), 
        backgroundColor: c, 
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(15),
      )
    );
  }
}