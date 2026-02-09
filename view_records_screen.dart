import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'db_helper.dart';

class ViewRecordsScreen extends StatefulWidget {
  final String assessmentId;
  final String evaluatorId;

  const ViewRecordsScreen({super.key, required this.assessmentId, required this.evaluatorId});

  @override
  State<ViewRecordsScreen> createState() => _ViewRecordsScreenState();
}

class _ViewRecordsScreenState extends State<ViewRecordsScreen> {
  final dbHelper = DBHelper();
  List<Map<String, dynamic>> localRecords = [];
  Map<String, String> studentMap = {};
  bool isLoading = true;
  bool isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    
    final cachedStudents = await dbHelper.getFromCache('students_list');
    if (cachedStudents != null && cachedStudents is List) {
      for (var s in cachedStudents) {
        studentMap[s["user_email"].toString()] = s["user_full_name"] ?? "Unknown Student";
      }
    }

    final allData = await dbHelper.getOfflineRecords(widget.assessmentId, widget.evaluatorId);
    if (mounted) {
      setState(() {
        localRecords = List<Map<String, dynamic>>.from(allData);
        isLoading = false;
      });
    }
  }

  Future<void> _syncHistoryFromServer() async {
    setState(() => isSyncing = true);
    try {
      final String encodedEvalId = Uri.encodeComponent(widget.evaluatorId);
      final String encodedAsmtId = Uri.encodeComponent(widget.assessmentId);
      final String url = "https://savysquad.com/assessment_system/fetch_history.php?evaluator_id=$encodedEvalId&assessment_id=$encodedAsmtId";
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        var rawData = jsonDecode(response.body);
        if (rawData is List) {
          for (var item in rawData) {
            Map<String, dynamic> evaluationData = jsonDecode(item['data'].toString());
            await dbHelper.saveEvaluationLocally(
              studentId: item['evaluated_student_id'].toString(), 
              assessmentId: item['assessment_id'].toString(),
              evaluatorId: item['evaluated_by'].toString(),
              data: evaluationData, 
              isSynced: 1, 
            );
          }
          _showSnackBar("Records Fetched Successfully!", Colors.green);
          _loadData(); 
        }
      }
    } catch (e) {
      _showSnackBar("Connection Error. Please try again.", Colors.red);
    } finally {
      if (mounted) setState(() => isSyncing = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A7CFF),
        title: const Text("Evaluation History", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildEvaluatorHeader(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : localRecords.isEmpty 
                    ? _buildCenterFetchButton()
                    : _buildRecordList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluatorHeader() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
      decoration: const BoxDecoration(color: Color(0xFF4A7CFF), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
      child: Column(
        children: [
          const Icon(Icons.account_circle, color: Colors.white, size: 40),
          const SizedBox(height: 10),
          Text(widget.evaluatorId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text("${localRecords.length} Records Found", style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCenterFetchButton() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_download_outlined, size: 60, color: Color(0xFF4A7CFF)),
          const SizedBox(height: 15),
          const Text("No Local Records Found", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: isSyncing ? null : _syncHistoryFromServer, child: Text(isSyncing ? "Syncing..." : "Sync From Server")),
        ],
      ),
    );
  }

  Widget _buildRecordList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: localRecords.length,
      itemBuilder: (context, index) {
        final record = localRecords[index];
        final Map<String, dynamic> data = record['decoded_data'] ?? jsonDecode(record['data'].toString());
        String sEmail = (record['student_id'] ?? record['evaluated_student_id']).toString();
        return _buildRecordCard(studentMap[sEmail] ?? sEmail, data);
      },
    );
  }

  Widget _buildRecordCard(String displayName, Map<String, dynamic> data) {
    List evals = data['evaluations'] ?? [];
    double totalObtained = 0;
    double totalMax = 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
            const Divider(height: 20),
            ...evals.map((e) {
              String desc = e['assessment_description'] ?? e['criteria_name'] ?? "Criteria";
              String obtained = e['obtained_marks']?.toString() ?? "0";
              String max = e['max_marks']?.toString() ?? "0"; // Correct key read
              
              totalObtained += double.tryParse(obtained) ?? 0;
              totalMax += double.tryParse(max) ?? 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(desc, style: const TextStyle(fontSize: 13))),
                    Text("$obtained / $max", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }).toList(),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryLabel("MAX", totalMax.toInt().toString()),
                _summaryLabel("SCORE", totalObtained.toInt().toString()),
                _summaryLabel("PERC", totalMax > 0 ? "${((totalObtained/totalMax)*100).toStringAsFixed(1)}%" : "0%"),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _summaryLabel(String label, String val) {
    return Column(children: [Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)), Text(val, style: const TextStyle(fontWeight: FontWeight.bold))]);
  }
}