import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'student_analytics_screen.dart'; // Ensure path is correct

class StudentSelectionScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const StudentSelectionScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<StudentSelectionScreen> createState() => _StudentSelectionScreenState();
}

class _StudentSelectionScreenState extends State<StudentSelectionScreen> {
  List<dynamic> studentList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      // Students List API
      final response = await http.get(Uri.parse("https://bgnu.space/api/student_data"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          studentList = data['data'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading students: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Select Student for Analytics"),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : studentList.isEmpty
              ? const Center(child: Text("No students found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: studentList.length,
                  itemBuilder: (context, index) {
                    final student = studentList[index];
                    String email = student['user_email'] ?? "No Email";
                    String fullName = student['user_full_name'] ?? email.split('@').first;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                          child: Text(fullName[0].toUpperCase(), 
                              style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                        ),
                        title: Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(email, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        trailing: const Icon(Icons.analytics_outlined, color: Colors.orange),
                        onTap: () {
                          // Navigating to Analytics Screen with proper data
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentAnalyticsScreen(
                                categoryId: widget.categoryId,
                                categoryName: widget.categoryName,
                                studentId: email.trim(), // Send email as ID
                                studentName: fullName,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}