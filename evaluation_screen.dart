import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'db_helper.dart';

class EvaluationScreen extends StatefulWidget {
  final String adId, courseName, evaluatorId;
  const EvaluationScreen({super.key, required this.adId, required this.courseName, required this.evaluatorId});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  bool loading = true, saving = false;
  final dbHelper = DBHelper();
  List<dynamic> allStudents = [], filteredStudents = [], assessmentDetails = [];
  
  // Controllers for comments coming from API
  Map<String, TextEditingController> commentsCtrl = {};
  // Values for Sliders
  Map<String, double> sliderValues = {};

  String? selectedStudentEmail, selectedStudentName;

  @override
  void initState() {
    super.initState();
    fetchStudents();
    fetchAssessmentDetails();
  }

  Future<void> fetchStudents() async {
    try {
      final res = await http.get(Uri.parse("https://bgnu.space/api/student_data"));
      if (res.statusCode == 200) {
        setState(() { 
          allStudents = jsonDecode(res.body)["data"]; 
          filteredStudents = allStudents; 
        });
      }
    } catch (e) { debugPrint(e.toString()); }
  }

  Future<void> fetchAssessmentDetails() async {
    try {
      final url = "https://savysquad.com/assessment_system/get_subcategories.php?presentation_id=${widget.adId}";
      final res = await http.get(Uri.parse(url));
      final decoded = jsonDecode(res.body);
      if (decoded["status"].toString() == "true") {
        setState(() {
          assessmentDetails = decoded["data"];
          for (var item in assessmentDetails) {
            String id = item["id"].toString();
            if (item["type"] == "Marks") {
              sliderValues[id] = 0.0; // Initial slider value
            } else {
              commentsCtrl[id] = TextEditingController(); // Controller for comment type
            }
          }
          loading = false;
        });
      } else { setState(() => loading = false); }
    } catch (e) { setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.courseName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
      ),
      body: loading ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          _buildStudentHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...assessmentDetails.map((item) => _buildCriteriaCard(item)),
                const SizedBox(height: 30),
                _saveButton(),
                const SizedBox(height: 20),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStudentHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A8A),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.person, color: Color(0xFF1E3A8A))),
          title: Text(selectedStudentName ?? "Select Student", style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(selectedStudentEmail ?? "Tap to search student"),
          trailing: const Icon(Icons.search, color: Color(0xFF1E3A8A)),
          onTap: _showSearchSheet,
        ),
      ),
    );
  }

  Widget _buildCriteriaCard(dynamic item) {
    String id = item["id"].toString();
    bool isMarks = item["type"] == "Marks";
    double maxM = double.tryParse(item["max_marks"].toString()) ?? 10.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(item["title"], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF334155)))),
              if (isMarks)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                  child: Text("${sliderValues[id]!.toInt()} / ${maxM.toInt()}", style: const TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 15),
          if (isMarks) 
            Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF3B82F6),
                    thumbColor: const Color(0xFF1E3A8A),
                    overlayColor: const Color(0xFF1E3A8A).withAlpha(32),
                    valueIndicatorColor: const Color(0xFF1E3A8A),
                  ),
                  child: Slider(
                    value: sliderValues[id]!,
                    min: 0,
                    max: maxM,
                    divisions: maxM.toInt() > 0 ? maxM.toInt() : 1,
                    label: sliderValues[id]!.toInt().toString(),
                    onChanged: (val) => setState(() => sliderValues[id] = val),
                  ),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("0", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text("Move slider to grade", style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                )
              ],
            )
          else 
            TextField(
              controller: commentsCtrl[id],
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Enter comments for ${item["title"]}",
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: saving ? null : _saveData,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A8A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2,
        ),
        child: saving 
          ? const CircularProgressIndicator(color: Colors.white) 
          : const Text("SUBMIT EVALUATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  void _showSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(hintText: "Search Student...", prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                  onChanged: (val) => setSheetState(() => filteredStudents = allStudents.where((s) => s["user_full_name"].toString().toLowerCase().contains(val.toLowerCase())).toList()),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: filteredStudents.length, 
                    itemBuilder: (context, i) => ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(filteredStudents[i]["user_full_name"]),
                      subtitle: Text(filteredStudents[i]["user_email"]),
                      onTap: () { 
                        setState(() { 
                          selectedStudentName = filteredStudents[i]["user_full_name"]; 
                          selectedStudentEmail = filteredStudents[i]["user_email"]; 
                        }); 
                        Navigator.pop(context); 
                      },
                    )
                  )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveData() async {
    if (selectedStudentEmail == null) {
      _showMsg("Please select a student first!", Colors.red);
      return;
    }
    
    setState(() => saving = true);

    // ✅ Map values to your payload structure here
    // Marks are in: sliderValues[id]
    // Comments are in: commentsCtrl[id].text

    await Future.delayed(const Duration(seconds: 1)); // Simulating API
    _showMsg("Evaluation Saved Successfully!", Colors.green);
    setState(() => saving = false);
  }

  void _showMsg(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c, behavior: SnackBarBehavior.floating));
}