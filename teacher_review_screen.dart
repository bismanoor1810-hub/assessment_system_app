import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'evaluation_screen.dart'; 
import 'view_records_screen.dart';
import 'add_assessment_screen.dart'; // Naya page for adding course

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  _AssessmentScreenState createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  List assessments = [];
  bool isLoading = true;
  final String studentRollNo = "BSCSF23M22"; // Login Fixed ID

  @override
  void initState() {
    super.initState();
    fetchAssessments();
  }

  // API se data lane ka function
  Future<void> fetchAssessments() async {
    try {
      final response = await http.get(
        Uri.parse("https://savysquad.com/smartassess/api/assessments.php"),
      );

      if (response.statusCode == 200) {
        final List decodedData = json.decode(response.body);
        if (mounted) {
          setState(() {
            assessments = decodedData;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9EEF5),
      appBar: AppBar(
        title: const Text("Smart Assessment System", 
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A56BE),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A56BE)))
          : RefreshIndicator(
              onRefresh: fetchAssessments, // Pull to refresh feature
              child: Column(
                children: [
                  // --- Summary Header ---
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF1A56BE),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Current Student: $studentRollNo",
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 5),
                        Text("Assessments Found: ${assessments.length}",
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  // --- Clickable Top Banner to Add Assessment ---
                  _buildTopBanner(),

                  // --- Vertical Assessment List ---
                  Expanded(
                    child: assessments.isEmpty
                        ? const Center(child: Text("No assessments available online"))
                        : ListView.builder(
                            itemCount: assessments.length,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemBuilder: (context, index) {
                              final item = assessments[index];
                              return _buildVerticalAssessmentCard(item);
                            },
                          ),
                  ),
                ],
              ),
            ),
      // --- Floating Button for Add Course ---
      bottomNavigationBar: _buildBottomAddButton(),
    );
  }

  Widget _buildTopBanner() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddAssessmentScreen()),
      ).then((_) => fetchAssessments()), // Refresh data when coming back
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF1A56BE),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Assessments Found: \$1ssessments", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("Tap + to add Assessment", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalAssessmentCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _buildInfoRow(Icons.school, "Course", item['description'] ?? 'N/A', Colors.blue),
          const Divider(height: 25),
          _buildInfoRow(Icons.bookmark, "Program", item['program_name'] ?? "BS Computer Science", const Color(0xFF1A56BE)),
          const Divider(height: 25),
          _buildStatusRow(item['status'] ?? 'ACTIVE'),
          const Divider(height: 25),
          _buildInfoRow(Icons.calendar_today, "Timeline", item['slot_date'] ?? '30 July 2025 at 12:58', Colors.orange),

          const SizedBox(height: 25),

          Row(
            children: [
              Expanded(
                child: _actionButton("Evaluate Now", const Color(0xFF1A56BE), Icons.edit_note, () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => EvaluationScreen(
                      adId: item['id'].toString(),
                      courseName: item['description'] ?? "Assessment",
                    ),
                  ));
                }),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton("View Results", const Color(0xFF2E7D32), Icons.bar_chart, () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const ViewRecordsScreen(),
                  ));
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String title, Color color, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(title, style: const TextStyle(color: Colors.white, fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildBottomAddButton() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddAssessmentScreen()),
        ).then((_) => fetchAssessments()),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Course", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A56BE),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusRow(String status) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.play_circle_fill, color: Colors.green, size: 20),
        ),
        const SizedBox(width: 15),
        const Text("Status", style: TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(15)),
          child: Text(status.toUpperCase(), 
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}