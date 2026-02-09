import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'evaluation_screen.dart';
import 'view_records_screen.dart';
import 'feedback_detail_screen.dart'; 
import 'login_screen.dart'; 

class AssessmentScreen extends StatefulWidget {
  final String evaluatorId;
  const AssessmentScreen({super.key, required this.evaluatorId});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  bool isLoading = false;
  List<dynamic> allCategories = []; 
  Map<String, dynamic>? matchedCategory; 
  List<dynamic> presentations = []; 

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // ✅ 1. Load Data & Refresh Logic
  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse("https://savysquad.com/assessment_system/assessment_categories.php"));
      final decoded = jsonDecode(res.body);
      if (decoded["status"].toString() == "true") {
        setState(() => allCategories = decoded["data"]);
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ✅ 2. Search Logic
  void _onSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        matchedCategory = null;
        presentations = [];
      });
      return;
    }

    var found = allCategories.firstWhere(
      (item) => item["id"].toString() == query.trim(),
      orElse: () => null,
    );

    if (found != null) {
      setState(() => matchedCategory = found);
      _fetchPresentations(query.trim());
    } else {
      setState(() {
        matchedCategory = null;
        presentations = [];
      });
    }
  }

  Future<void> _fetchPresentations(String catId) async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse("https://savysquad.com/assessment_system/get_presentations_by_category.php?category_id=$catId"));
      final decoded = jsonDecode(res.body);
      if (decoded["status"].toString() == "true") {
        setState(() => presentations = decoded["data"]);
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(), // Logo, Welcome & Logout
              
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(20),
                child: Material(
                  elevation: 5,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(15),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Enter Category ID (e.g. 4)",
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF4A7CFF)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ),

              if (matchedCategory == null)
                _buildWelcomeState()
              else
                _buildResultsArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 60, 25, 30),
      decoration: const BoxDecoration(
        color: Color(0xFF4A7CFF),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                height: 55, width: 55,
                decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  image: DecorationImage(image: AssetImage("assets/images/bgnu_logo.jpg"), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Welcome!", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text("BGNU Portal", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            icon: const Icon(Icons.logout, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeState() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(Icons.manage_search, size: 100, color: Colors.grey.shade200),
          const SizedBox(height: 10),
          Text("Search ID to view presentations", style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildResultsArea() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue.shade100, width: 2),
          ),
          child: Text(
            "Course: ${matchedCategory!['assessment_category']}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
          ),
        ),
        isLoading 
        ? const CircularProgressIndicator()
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: presentations.length,
            itemBuilder: (context, index) => _buildPresentationCard(presentations[index]),
          ),
      ],
    );
  }

  Widget _buildPresentationCard(dynamic p) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _actionBtn("Others Evaluation", Colors.indigo, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ViewRecordsScreen(assessmentId: p['id'].toString(), evaluatorId: widget.evaluatorId)));
                })),
                const SizedBox(width: 8),
                Expanded(child: _actionBtn("START", const Color(0xFF4A7CFF), () {
                  _showCodeDialog(p['id'].toString(), p['name'], p['code'].toString());
                })),
              ],
            ),
            const SizedBox(height: 8),
            _actionBtn("My Evaluation", const Color(0xFF009688), () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => FeedbackDetailScreen(categoryName: p['name'], categoryId: p['id'].toString(), studentId: widget.evaluatorId)));
            }),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback tap) {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        onPressed: tap,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ✅ Secure Code Matching (Error message hidden)
  void _showCodeDialog(String id, String name, String dbCode) {
    final tc = TextEditingController();
    
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Verify Code"),
      content: TextField(
        controller: tc, 
        keyboardType: TextInputType.number,
        decoration: InputDecoration(hintText: "Enter code for $name"),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            if(tc.text.trim() == dbCode.trim()) {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => EvaluationScreen(
                adId: id, courseName: name, evaluatorId: widget.evaluatorId
              )));
            } else {
              // ✅ Sirf Invalid Code ka message show hoga
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Invalid Code! Please try again."), 
                  backgroundColor: Colors.red
                ),
              );
            }
          }, 
          child: const Text("Start")
        ),
      ],
    ));
  }
}