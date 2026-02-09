import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'db_helper.dart';

class StudentEvaluationListScreen extends StatefulWidget {
  final String presentationId;
  final String presentationName;
  final String adminId;

  const StudentEvaluationListScreen({
    super.key,
    required this.presentationId,
    required this.presentationName,
    required this.adminId,
  });

  @override
  State<StudentEvaluationListScreen> createState() => _StudentEvaluationListScreenState();
}

class _StudentEvaluationListScreenState extends State<StudentEvaluationListScreen> {
  List allStudents = [];
  List filteredStudents = [];
  List criteriaList = []; 
  Map<String, double> marks = {}; 
  
  bool isLoading = true;
  bool isCriteriaLoading = false;
  
  String? selectedStudentId;
  String? selectedStudentName;
  String? selectedStudentEmail;

  final dbHelper = DBHelper();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final local = await dbHelper.getFromCache('students_list');
    if (local != null) {
      setState(() { 
        allStudents = List.from(local); 
        filteredStudents = allStudents; 
        isLoading = false; 
      });
    }
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    try {
      final res = await http.get(Uri.parse("https://bgnu.space/api/student_data")).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final data = decoded["data"];
        if (mounted && data != null) {
          await dbHelper.saveToCache('students_list', data);
          setState(() { 
            allStudents = List.from(data); 
            filteredStudents = allStudents; 
            isLoading = false; 
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _fetchCriteria() async {
    setState(() {
      isCriteriaLoading = true;
      criteriaList = []; 
      marks = {};
    });
    try {
      // ✅ Fetching from your get_criteria.php
      final res = await http.get(Uri.parse("https://savysquad.com/assessment_system/get_criteria.php?presentation_id=${widget.presentationId}"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == "true") {
          setState(() {
            criteriaList = data['data'];
            for (var c in criteriaList) { 
              // marks key is 'id' from subcategories table
              marks[c['id'].toString()] = 0.0; 
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Criteria Error: $e");
    }
    setState(() => isCriteriaLoading = false);
  }

  Future<void> _submitEvaluation() async {
    if (selectedStudentId == null) return;

    final submissionData = {
      "presentation_id": widget.presentationId,
      "evaluator_id": widget.adminId,
      "student_id": selectedStudentId,
      "marks": marks, 
    };

    // Yahan aap apni submission API call kar sakte hain
    debugPrint("Final Submission: ${jsonEncode(submissionData)}");
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Evaluation Saved Successfully!"), backgroundColor: Colors.green),
    );
    Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text("Evaluating: ${widget.presentationName}"),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Step 1: Select Student", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A))),
            const SizedBox(height: 12),
            _buildStudentPicker(),
            
            if (selectedStudentId != null) ...[
              const SizedBox(height: 30),
              const Text("Step 2: Marking Criteria", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 15),
              
              if (isCriteriaLoading) 
                const Center(child: CircularProgressIndicator())
              else if (criteriaList.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("No criteria (Layout/PPT) found for this presentation."),
                  ),
                )
              else
                _buildMarkingSection(),
            ]
          ],
        ),
      ),
      // Submit button only appears after student selection and criteria load
      bottomNavigationBar: selectedStudentId != null && criteriaList.isNotEmpty
          ? _buildSubmitButton()
          : null,
    );
  }

  Widget _buildMarkingSection() {
    return Column(
      children: criteriaList.map((c) {
        String id = c['id'].toString();
        // Dynamic Max Marks from PHP/DB
        double maxAllowed = double.tryParse(c['max_marks'].toString()) ?? 10.0;
        if(maxAllowed <= 0) maxAllowed = 10.0; 

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ✅ Using 'title' from your PHP response
                    Text(c['title'] ?? "Criteria", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), 
                    Text("${marks[id]!.toInt()}/${maxAllowed.toInt()}", 
                         style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: marks[id]!,
                  min: 0,
                  max: maxAllowed,
                  divisions: maxAllowed.toInt(),
                  activeColor: const Color(0xFF1E3A8A),
                  onChanged: (val) => setState(() => marks[id] = val),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStudentPicker() {
    return InkWell(
      onTap: _showSearchSheet,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
        ),
        child: Row(
          children: [
            const Icon(Icons.person, color: Color(0xFF1E3A8A)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selectedStudentName ?? "Choose Student", style: const TextStyle(fontWeight: FontWeight.bold)),
                  if(selectedStudentEmail != null)
                    Text(selectedStudentEmail!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              )
            ),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A8A),
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
        ),
        onPressed: _submitEvaluation,
        child: const Text("SAVE EVALUATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text("Select Student", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search name or email...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) {
                    setModalState(() {
                      filteredStudents = allStudents.where((s) => 
                        s["user_full_name"].toString().toLowerCase().contains(val.toLowerCase()) ||
                        s["user_email"].toString().toLowerCase().contains(val.toLowerCase())
                      ).toList();
                    });
                  },
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final s = filteredStudents[index];
                      return ListTile(
                        title: Text(s["user_full_name"]),
                        subtitle: Text(s["user_email"]), // ✅ Showing Email
                        onTap: () {
                          setState(() {
                            selectedStudentId = s["user_id"].toString();
                            selectedStudentName = s["user_full_name"];
                            selectedStudentEmail = s["user_email"];
                          });
                          Navigator.pop(context);
                          _fetchCriteria(); 
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }
}