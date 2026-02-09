import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddAssessmentScreen extends StatefulWidget {
  const AddAssessmentScreen({super.key});

  @override
  _AddAssessmentScreenState createState() => _AddAssessmentScreenState();
}

class _AddAssessmentScreenState extends State<AddAssessmentScreen> {
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _programController = TextEditingController();
  bool isSaving = false;

  Future<void> saveToDatabase() async {
    if (_courseController.text.isEmpty || _programController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fields cannot be empty")));
      return;
    }

    setState(() => isSaving = true);
    try {
      final response = await http.post(
        Uri.parse("https://savysquad.com/smartassess/api/add_new_assessment.php"),
        body: {
          "description": _courseController.text,
          "program_name": _programController.text,
        },
      );

      if (response.statusCode == 200) {
        Navigator.pop(context); // Wapas dashboard par bhej dega
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Assessment"), backgroundColor: const Color(0xFF1A56BE)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _courseController, decoration: const InputDecoration(labelText: "Course Name (e.g. Numerical Analysis)")),
            const SizedBox(height: 15),
            TextField(controller: _programController, decoration: const InputDecoration(labelText: "Program Name (e.g. BSCS)")),
            const SizedBox(height: 30),
            isSaving 
              ? const CircularProgressIndicator() 
              : ElevatedButton(
                  onPressed: saveToDatabase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56BE),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("Save Assessment", style: TextStyle(color: Colors.white)),
                ),
          ],
        ),
      ),
    );
  }
}