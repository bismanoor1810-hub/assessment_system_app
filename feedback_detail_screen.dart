import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'db_helper.dart';

class FeedbackDetailScreen extends StatefulWidget {
  final String categoryName;
  final String categoryId;
  final String studentId;

  const FeedbackDetailScreen({
    super.key,
    required this.categoryName,
    required this.categoryId,
    required this.studentId,
  });

  @override
  State<FeedbackDetailScreen> createState() => _FeedbackDetailScreenState();
}

class _FeedbackDetailScreenState extends State<FeedbackDetailScreen> {
  final dbHelper = DBHelper();
  List<Map<String, dynamic>> feedbackItems = [];
  bool isLoading = true;
  bool isSyncing = false;

  // Groq Configuration
  final String _groqApiKey = "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";
  String aiSummary = "";
  bool isAiLoading = false;
  bool showAiCard = false;

  @override
  void initState() {
    super.initState();
    _loadFromLocal();
  }

  // --- 1. SYNC DATA FROM SERVER ---
  Future<void> _syncAndLoadData() async {
    if (mounted) setState(() => isSyncing = true);
    try {
      final String url = "https://savysquad.com/assessment_system/fetch_student_feedback.php?student_id=${Uri.encodeComponent(widget.studentId)}&assessment_id=${Uri.encodeComponent(widget.categoryId)}";
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        var rawData = jsonDecode(response.body);
        if (rawData is List && rawData.isNotEmpty) {
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
        }
        await _loadFromLocal();
        _showSnack("Data synced successfully", Colors.green);
      }
    } catch (e) {
      _showSnack("Network error. Using offline data.", Colors.orange);
    } finally {
      if (mounted) setState(() => isSyncing = false);
    }
  }

  // --- 2. LOAD FROM LOCAL DB ---
  Future<void> _loadFromLocal() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final allData = await dbHelper.getOfflineRecords(widget.categoryId, null);
      List<Map<String, dynamic>> myReviews = [];

      for (var record in allData) {
        if (record['student_id'].toString().trim() == widget.studentId.trim()) {
          final Map<String, dynamic> jsonData = record['decoded_data'] ?? jsonDecode(record['data'].toString());
          if (jsonData['evaluations'] != null) {
            for (var e in jsonData['evaluations']) {
              String commentText = e['comments']?.toString() ?? "";
              if (commentText.isNotEmpty && commentText != "null") {
                myReviews.add({
                  "evaluator": record['evaluator_id'] ?? "Teacher",
                  "comment": commentText,
                });
              }
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          feedbackItems = myReviews;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- 3. GROQ AI GENERATION (Temporary View) ---
  Future<void> _generateGroqAnalysis() async {
    if (feedbackItems.isEmpty) {
      _showSnack("No comments to analyze!", Colors.orange);
      return;
    }

    setState(() {
      isAiLoading = true;
      showAiCard = true;
      aiSummary = "Generating insights...";
    });

    String combinedComments = feedbackItems.map((item) => "- ${item['comment']}").join("\n");

    try {
      final response = await http.post(
        Uri.parse("https://api.groq.com/openai/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $_groqApiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content": "You are a professional mentor. Analyze student's peer feedback. Give a 2-sentence summary and one improvement tip. Friendly tone."
            },
            {
              "role": "user",
              "content": "Analyze these comments:\n$combinedComments"
            }
          ],
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          aiSummary = data['choices'][0]['message']['content'];
          isAiLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        aiSummary = "AI analysis failed. Please check internet.";
        isAiLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4A7CFF),
        centerTitle: true,
        title: Text(widget.categoryName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isSyncing)
            const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          else
            IconButton(icon: const Icon(Icons.sync), onPressed: _syncAndLoadData),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isAiLoading ? null : _generateGroqAnalysis,
        backgroundColor: const Color(0xFF4A7CFF),
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: Text(aiSummary.isEmpty ? "Generate AI Response" : "Regenerate Insight",
            style: const TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          _buildSummaryHeader(),
          if (showAiCard) _buildAISmartCard(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : feedbackItems.isEmpty
                    ? _buildCenterFetchButton()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 85),
                        itemCount: feedbackItems.length,
                        itemBuilder: (context, index) => _buildCommentCard(feedbackItems[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAISmartCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.indigo.shade800, Colors.blue.shade700]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text("AI Mentor Summary", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(onPressed: () => setState(() => showAiCard = false), icon: const Icon(Icons.close, color: Colors.white54, size: 18))
            ],
          ),
          const SizedBox(height: 8),
          if (isAiLoading)
            const LinearProgressIndicator(backgroundColor: Colors.white24, color: Colors.amber)
          else
            Text(aiSummary, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  // --- MODIFIED CARD: No Marks Shown ---
  Widget _buildCommentCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.person_pin, color: Color(0xFF4A7CFF), size: 20),
          const SizedBox(width: 8),
          Text(item['evaluator'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
        const Divider(height: 24),
        Text("\"${item['comment']}\"",
            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black87)),
      ]),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
      decoration: const BoxDecoration(color: Color(0xFF4A7CFF), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30))),
      child: Column(children: [
        const Text("Student ID", style: TextStyle(color: Colors.white70, fontSize: 11)),
        Text(widget.studentId, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
            child: Text("${feedbackItems.length} Comments Received", style: const TextStyle(color: Colors.white, fontSize: 12))),
      ]),
    );
  }

  Widget _buildCenterFetchButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 50, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text("No comments found locally."),
          TextButton(onPressed: _syncAndLoadData, child: const Text("Sync Now")),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }
}