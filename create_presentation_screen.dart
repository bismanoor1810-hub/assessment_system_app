import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreatePresentationScreen extends StatefulWidget {
  final String adminId;
  const CreatePresentationScreen({super.key, required this.adminId});

  @override
  State<CreatePresentationScreen> createState() => _CreatePresentationScreenState();
}

class _CreatePresentationScreenState extends State<CreatePresentationScreen> {
  final nameCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  final tWeightCtrl = TextEditingController();
  final sWeightCtrl = TextEditingController();

  DateTime? startDate, endDate;
  TimeOfDay? startTime, endTime;
  bool isSaving = false;

  // Is list mein multiple criteria save ho sakte hain
  List<Map<String, dynamic>> subCategories = [];
  String? selectedType;

  // --- Date & Time Pickers ---
  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => isStart ? startDate = picked : endDate = picked);
  }

  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => isStart ? startTime = picked : endTime = picked);
  }

  // --- Criteria Logic ---
  
  // Jab teacher Marks select karega to ye dialog aayega
  void _showMarksDialog() {
    final marksCtrl = TextEditingController();
    final titleCtrl = TextEditingController(text: "PPT & Layout");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Set Marking Criteria", style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: "Criteria Title (e.g. PPT Marks)"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: marksCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Max Marks (e.g. 10)", hintText: "Slider range limit"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
            onPressed: () {
              if (marksCtrl.text.isNotEmpty) {
                setState(() {
                  subCategories.add({
                    "type": "Marks",
                    "title": titleCtrl.text,
                    "max_marks": marksCtrl.text
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add Slider Criteria", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _addSubCategory() {
    if (selectedType == null) {
      _showMsg("Please select a criteria type first", Colors.orange);
      return;
    }

    if (selectedType == "Marks") {
      _showMarksDialog();
    } else {
      // Jab teacher Comments select karega
      setState(() {
        subCategories.add({
          "type": "Comments",
          "title": "General Feedback",
          "max_marks": "0" // Comments ke liye marks zaruri nahi
        });
      });
      _showMsg("Feedback Textbox added!", Colors.blue);
    }
  }

  // --- Submission Logic ---
  Future<void> _submitPresentation() async {
    if (nameCtrl.text.isEmpty || startDate == null || startTime == null || subCategories.isEmpty) {
      _showMsg("Please fill all details and add at least one criteria!", Colors.red);
      return;
    }

    setState(() => isSaving = true);
    try {
      final response = await http.post(
        Uri.parse("https://savysquad.com/assessment_system/create_presentation.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": nameCtrl.text.trim(),
          "code": codeCtrl.text.trim(),
          "start_date": startDate.toString().split(' ')[0],
          "start_time": startTime!.format(context),
          "end_date": endDate?.toString().split(' ')[0] ?? startDate.toString().split(' ')[0],
          "end_time": endTime?.format(context) ?? startTime!.format(context),
          "teacher_weightage": tWeightCtrl.text.isEmpty ? "100" : tWeightCtrl.text,
          "student_weightage": sWeightCtrl.text.isEmpty ? "0" : sWeightCtrl.text,
          "created_by": widget.adminId,
          "sub_categories": subCategories
        }),
      );

      final result = jsonDecode(response.body);
      if (result['status'] == "true") {
        _showMsg("Presentation Published Successfully!", Colors.green);
        Navigator.pop(context);
      } else {
        _showMsg(result['message'] ?? "Error occurred", Colors.red);
      }
    } catch (e) {
      _showMsg("Connection Error", Colors.red);
    } finally {
      setState(() => isSaving = false);
    }
  }

  void _showMsg(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Setup Presentation"),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. Basic Details Card
            _buildCard(
              title: "Presentation Info",
              child: Column(
                children: [
                  _customField("Presentation Name", nameCtrl, Icons.title),
                  _customField("Unique Code", codeCtrl, Icons.qr_code),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // 2. Timing Card
            _buildCard(
              title: "Timing & Schedule",
              child: Column(
                children: [
                  Row(children: [
                    Expanded(child: _dateTimeTile("Start Date", startDate?.toString().split(' ')[0] ?? "Set Date", Icons.calendar_month, () => _pickDate(context, true))),
                    const SizedBox(width: 10),
                    Expanded(child: _dateTimeTile("Start Time", startTime?.format(context) ?? "Set Time", Icons.access_time, () => _pickTime(context, true))),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _dateTimeTile("End Date", endDate?.toString().split(' ')[0] ?? "Set Date", Icons.calendar_month, () => _pickDate(context, false))),
                    const SizedBox(width: 10),
                    Expanded(child: _dateTimeTile("End Time", endTime?.format(context) ?? "Set Time", Icons.access_time, () => _pickTime(context, false))),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // 3. Criteria Selection Card
            _buildCard(
              title: "Evaluation Criteria (Teacher can add both)",
              child: Column(
                children: [
                  Row(children: [
                    Expanded(child: _customField("Teacher Weight %", tWeightCtrl, Icons.school, isNum: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _customField("Student Weight %", sWeightCtrl, Icons.person, isNum: true)),
                  ]),
                  const Divider(),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedType,
                          hint: const Text("Select Type to Add"),
                          items: ["Marks", "Comments"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setState(() => selectedType = v),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _addSubCategory,
                      icon: const Icon(Icons.add_circle, color: Color(0xFF1E3A8A), size: 35),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  
                  // Added Criteria List
                  ...subCategories.map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: s['type'] == "Marks" ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: Icon(s['type'] == "Marks" ? Icons.linear_scale : Icons.text_fields, color: Colors.blueGrey),
                      title: Text(s['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(s['type'] == "Marks" ? "Evaluation: SLIDE BAR (${s['max_marks']} Marks)" : "Evaluation: TEXT FIELD"),
                      trailing: IconButton(icon: const Icon(Icons.delete_sweep, color: Colors.red), onPressed: () => setState(() => subCategories.remove(s))),
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Publish Button
            ElevatedButton(
              onPressed: isSaving ? null : _submitPresentation,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
                backgroundColor: const Color(0xFF1E3A8A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: isSaving 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text("Publish Presentation", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  // --- UI Reusable Widgets ---
  Widget _buildCard({required String title, required Widget child}) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 15)),
      const Divider(height: 25),
      child,
    ]),
  );

  Widget _customField(String label, TextEditingController ctrl, IconData icon, {bool isNum = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: ctrl, 
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon, size: 20, color: const Color(0xFF1E3A8A)), 
        filled: true, fillColor: Colors.grey[50], 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
      ),
    ),
  );

  Widget _dateTimeTile(String label, String value, IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.blue),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
        ])
      ]),
    ),
  );
}