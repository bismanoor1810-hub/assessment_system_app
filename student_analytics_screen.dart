import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'db_helper.dart'; 

class StudentAnalyticsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final String studentId;
  final String studentName;

  const StudentAnalyticsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentAnalyticsScreen> createState() => _StudentAnalyticsScreenState();
}

class _StudentAnalyticsScreenState extends State<StudentAnalyticsScreen> {
  bool isLoading = true;
  List<dynamic> historyData = [];
  Map<String, List<dynamic>> groupedData = {}; 
  double overallPercentage = 0.0;
  final DBHelper dbHelper = DBHelper(); 

  @override
  void initState() {
    super.initState();
    _fetchLiveAnalytics(); 
  }

  void _processData(List data) {
    if (data.isEmpty) {
      if (mounted) {
        setState(() {
          historyData = [];
          groupedData = {};
          overallPercentage = 0.0;
          isLoading = false;
        });
      }
      return;
    }

    double grandTotalObtained = 0;
    double grandTotalPossible = 0;
    Map<String, List<dynamic>> tempGrouped = {};

    for (var item in data) {
      grandTotalObtained += double.tryParse(item['obtained'].toString()) ?? 0.0;
      grandTotalPossible += double.tryParse(item['total'].toString()) ?? 0.0;

      // Evaluator name clean karein
      String evaluator = (item['by'] ?? "Unknown Evaluator").toString().trim();
      
      if (!tempGrouped.containsKey(evaluator)) {
        tempGrouped[evaluator] = [];
      }
      tempGrouped[evaluator]!.add(item);
    }

    if (mounted) {
      setState(() {
        historyData = data;
        groupedData = tempGrouped; 
        overallPercentage = grandTotalPossible > 0 
            ? (grandTotalObtained / grandTotalPossible) * 100 
            : 0.0;
        isLoading = false; 
      });
    }
  }

  Future<void> _fetchLiveAnalytics() async {
    try {
      final String url = "https://savysquad.com/assessment_system/get_student_graph_data.php?evaluated_student_id=${widget.studentId.trim()}&category_id=${widget.categoryId}";
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == true) {
          List data = result['data'] ?? [];
          await dbHelper.saveStudentAnalytics(widget.studentId, widget.categoryId, data);
          _processData(data);
          return;
        }
      }
      _loadFromCache();
    } catch (e) {
      _loadFromCache();
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadFromCache() async {
    final cachedData = await dbHelper.getStudentAnalytics(widget.studentId, widget.categoryId);
    if (cachedData != null) {
      _processData(cachedData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text("${widget.studentName}'s Analytics", 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF1E3A8A),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading && historyData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchLiveAnalytics,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildOverallProgress(),
                  const SizedBox(height: 25),
                  
                  const Text("Evaluation History", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 15),

                  if (groupedData.isEmpty)
                    _buildEmptyState()
                  else
                    ...groupedData.entries.map((entry) {
                      return _buildExpandableEvaluatorCard(entry.key, entry.value);
                    }).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildExpandableEvaluatorCard(String email, List<dynamic> records) {
    double teacherObtained = 0;
    double teacherTotal = 0;
    for (var r in records) {
      teacherObtained += double.tryParse(r['obtained'].toString()) ?? 0.0;
      teacherTotal += double.tryParse(r['total'].toString()) ?? 0.0;
    }
    double teacherPercentage = teacherTotal > 0 ? (teacherObtained / teacherTotal) * 100 : 0.0;
    
    // Evaluator wise colors
    Color themeColor = email.toLowerCase().contains('shanza') ? Colors.purple : 
                       email.toLowerCase().contains('sami') ? Colors.orange : Colors.teal;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: themeColor.withOpacity(0.1),
          child: Icon(Icons.person, color: themeColor),
        ),
        title: Text(email, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text("Records: ${records.length} | Score: ${teacherObtained.toStringAsFixed(0)}/${teacherTotal.toStringAsFixed(0)}"),
        trailing: Text("${teacherPercentage.toStringAsFixed(1)}%",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)),
        children: records.map((record) => _buildDetailListItem(record)).toList(),
      ),
    );
  }

  Widget _buildDetailListItem(dynamic record) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(record['date'] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text("Score: ${record['obtained']}/${record['total']}", 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
            ],
          ),
          if (record['comments'].toString().isNotEmpty && record['comments'] != 'null') ...[
            const SizedBox(height: 5),
            Text("Feedback: ${record['comments']}", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Text("No records found for ${widget.studentName}"),
      ),
    );
  }

  Widget _buildOverallProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text("${widget.categoryName} Average", style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          CircularProgressIndicator(
            value: overallPercentage / 100,
            strokeWidth: 8,
            color: Colors.green,
            backgroundColor: Colors.grey.shade100,
          ),
          const SizedBox(height: 10),
          Text("${overallPercentage.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}