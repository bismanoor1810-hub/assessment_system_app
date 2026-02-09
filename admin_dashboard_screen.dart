import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'evaluation_screen.dart'; 
import 'view_records_screen.dart'; 
import 'student_analytics_screen.dart'; 
import 'db_helper.dart'; 
import 'create_presentation_screen.dart'; 
import 'presentation_list_screen.dart'; 

class AdminDashboardScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final String adminId;

  const AdminDashboardScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.adminId,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<dynamic> syncedStudents = [];
  bool isLoadingSync = true;

  @override
  void initState() {
    super.initState();
    _loadLocalSyncData(); 
    _sendMySyncStatus();  
    _fetchSyncStatus();   
  }

  Future<void> _loadLocalSyncData() async {
    final localData = await DBHelper().getFromCache('synced_students_list');
    if (localData != null && localData.isNotEmpty) {
      if (mounted) {
        setState(() {
          syncedStudents = localData;
          isLoadingSync = false;
        });
      }
    }
  }

  Future<void> _sendMySyncStatus() async {
    try {
      await http.post(
        Uri.parse("https://savysquad.com/assessment_system/update_sync.php"),
        body: {
          'student_id': widget.adminId.trim(), 
          'device_status': 'Admin Online',
        },
      );
    } catch (e) {
      debugPrint("Update Sync Error: $e");
    }
  }

  Future<void> _fetchSyncStatus() async {
    if (!mounted) return;
    setState(() => isLoadingSync = true);
    try {
      final res = await http.get(Uri.parse(
          "https://savysquad.com/assessment_system/get_synced_students.php"));
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted && data['status'] == "true") {
          final List fetchedList = data['data'] ?? [];
          
          setState(() {
            syncedStudents = fetchedList;
            isLoadingSync = false;
          });

          await DBHelper().saveToCache('synced_students_list', fetchedList);
        }
      } else {
        if (mounted) setState(() => isLoadingSync = false);
      }
    } catch (e) {
      debugPrint("Fetch Exception: $e");
      if (mounted) setState(() => isLoadingSync = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(widget.categoryName),
        elevation: 0,
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _fetchSyncStatus, 
            icon: const Icon(Icons.refresh_rounded)
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSyncStatus,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInstallationMonitor(),
              const SizedBox(height: 25),
              const Text(
                "Management Actions", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))
              ),
              const SizedBox(height: 15),

              // ✅ 1. CREATE PRESENTATION
              _buildAdminCard(
                context, 
                title: "Create Presentation", 
                subtitle: "Setup new presentation criteria", 
                icon: Icons.add_to_photos_rounded, 
                color: Colors.purple.shade700, 
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (c) => CreatePresentationScreen(adminId: widget.adminId)
                  ));
                }
              ),

              const SizedBox(height: 16),

              // ✅ 2. VIEW PRESENTATIONS
              _buildAdminCard(
                context, 
                title: "View Presentations", 
                subtitle: "Manage and evaluate from your list", 
                icon: Icons.list_alt_rounded, 
                color: Colors.teal.shade700, 
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (c) => PresentationListScreen(adminId: widget.adminId)
                  ));
                }
              ),

              const SizedBox(height: 16),

              // ✅ 3. START EVALUATION (Back to Original Working)
              _buildAdminCard(
                context, 
                title: "Start Evaluation", 
                subtitle: "Mark assessment for students", 
                icon: Icons.play_circle_fill, 
                color: const Color(0xFF1E3A8A), 
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => EvaluationScreen(
                    adId: widget.categoryId, 
                    courseName: widget.categoryName, 
                    evaluatorId: widget.adminId
                  )));
                }
              ),

              const SizedBox(height: 16),

              // 4. MY EVALUATIONS
              _buildAdminCard(
                context, 
                title: "My Evaluations", 
                subtitle: "Records marked by you", 
                icon: Icons.person_pin_rounded, 
                color: Colors.green.shade700, 
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => ViewRecordsScreen(
                    assessmentId: widget.categoryId, 
                    evaluatorId: widget.adminId
                  )));
                }
              ),

              const SizedBox(height: 16),

              // 5. ALL EVALUATIONS
              _buildAdminCard(
                context, 
                title: "All Evaluations", 
                subtitle: "Student analytics and history", 
                icon: Icons.analytics_rounded, 
                color: Colors.orange.shade800, 
                onTap: () => _handleAllEvaluations(context)
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _buildAdminCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20), 
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ])
            ),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallationMonitor() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: const Icon(Icons.phonelink_setup, color: Colors.blue),
        title: Text("Live Sync Status (${syncedStudents.length})", 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: const Text("Student connectivity status", style: TextStyle(fontSize: 12)),
        children: [
          isLoadingSync && syncedStudents.isEmpty
            ? const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())
            : Container(
                constraints: const BoxConstraints(maxHeight: 250),
                child: syncedStudents.isEmpty 
                  ? const Padding(padding: EdgeInsets.all(20), child: Text("No records found."))
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 10),
                      itemCount: syncedStudents.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, indent: 50),
                      itemBuilder: (context, index) {
                        final s = syncedStudents[index];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.blue.shade50,
                            child: const Icon(Icons.person, size: 18, color: Color(0xFF1E3A8A)),
                          ),
                          title: Text(s['student_id'].toString(), 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text("Status: ${s['status']}", style: const TextStyle(fontSize: 11)),
                          trailing: Text(s['sync_time'] ?? "", 
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                        );
                      },
                    ),
              ),
        ],
      ),
    );
  }

  void _handleAllEvaluations(BuildContext context) async {
    List? students = await DBHelper().getFromCache('students_list');
    if (students == null || students.isEmpty) {
      try {
        final response = await http.get(Uri.parse("https://bgnu.space/api/student_data"));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          students = data['data'];
          await DBHelper().saveToCache('students_list', students);
        }
      } catch (e) { debugPrint("API Error: $e"); }
    }
    if (students == null || students.isEmpty) return;
    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _AdminStudentPicker(
          students: students!, 
          categoryId: widget.categoryId, 
          categoryName: widget.categoryName
        ),
      );
    }
  }
}

// _AdminStudentPicker code remains the same as before...
class _AdminStudentPicker extends StatefulWidget {
  final List students;
  final String categoryId;
  final String categoryName;
  const _AdminStudentPicker({required this.students, required this.categoryId, required this.categoryName});
  @override
  State<_AdminStudentPicker> createState() => _AdminStudentPickerState();
}

class _AdminStudentPickerState extends State<_AdminStudentPicker> {
  List filtered = [];
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    filtered = widget.students;
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      padding: const EdgeInsets.all(20),
      child: Column(children: [
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                filtered = widget.students.where((s) => s["user_full_name"].toString().toLowerCase().contains(val.toLowerCase())).toList();
              });
            },
            decoration: InputDecoration(
              hintText: "Search student...", prefixIcon: const Icon(Icons.search), 
              filled: true, fillColor: Colors.grey[100], 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final s = filtered[i];
                return ListTile(
                  title: Text(s["user_full_name"] ?? ""),
                  subtitle: Text(s["user_email"] ?? ""),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (c) => StudentAnalyticsScreen(
                      categoryName: widget.categoryName, categoryId: widget.categoryId, 
                      studentId: s["user_email"].toString().trim(), studentName: s["user_full_name"].toString(),
                    )));
                  },
                );
              },
            ),
          ),
      ]),
    );
  }
}