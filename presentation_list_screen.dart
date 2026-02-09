import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'db_helper.dart';
// Ensure this filename is exactly correct
import 'student_evaluation_list_screen.dart'; 

class PresentationListScreen extends StatefulWidget {
  final String adminId;
  const PresentationListScreen({super.key, required this.adminId});

  @override
  State<PresentationListScreen> createState() => _PresentationListScreenState();
}

class _PresentationListScreenState extends State<PresentationListScreen> {
  List presentations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocalPresentations();
  }

  Future<void> _loadLocalPresentations() async {
    final localData = await DBHelper().getFromCache('presentations_list_${widget.adminId}');
    if (localData != null && localData.isNotEmpty) {
      setState(() {
        presentations = localData;
        isLoading = false;
      });
    }
    _fetchPresentations();
  }

  Future<void> _fetchPresentations() async {
    try {
      final response = await http.get(
        Uri.parse("https://savysquad.com/assessment_system/get_presentations.php?admin_id=${widget.adminId}"),
      );
      
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        if (res['status'] == "true") {
          final List fetchedData = res['data'];
          if (mounted) {
            setState(() {
              presentations = fetchedData;
              isLoading = false;
            });
            await DBHelper().saveToCache('presentations_list_${widget.adminId}', fetchedData);
          }
        } else {
          if (mounted) setState(() => isLoading = false);
        }
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("My Presentations", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() => isLoading = true);
              _fetchPresentations();
            }, 
            icon: const Icon(Icons.refresh)
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPresentations,
        child: isLoading && presentations.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
            : presentations.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: presentations.length,
                    itemBuilder: (context, index) {
                      final item = presentations[index];
                      bool isActive = item['is_active'].toString() == "1";
                      return _buildPresentationCard(item, isActive);
                    },
                  ),
      ),
    );
  }

  Widget _buildPresentationCard(dynamic item, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: isActive ? Colors.green : Colors.red),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Code: ${item['code']}", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12)),
                          _statusChip(isActive),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(item['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                      const SizedBox(height: 12),
                      _infoRow(Icons.calendar_today, "Ends: ${item['end_date']} | ${item['end_time']}"),
                      _infoRow(Icons.rule, "Criteria: ${item['criteria_count']} types added"),
                      const Divider(height: 25),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // ✅ FIXED: Parameter names now match StudentEvaluationListScreen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentEvaluationListScreen(
                                  presentationId: item['id'].toString(), 
                                  presentationName: item['name'], 
                                  adminId: widget.adminId,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.assessment, size: 18, color: Colors.white),
                          label: const Text("Evaluate Now", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(bool active) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: active ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Text(active ? "Active" : "Expired", style: TextStyle(color: active ? Colors.green[700] : Colors.red[700], fontSize: 10, fontWeight: FontWeight.bold)),
      );

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          ],
        ),
      );

  Widget _buildEmptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]), const Text("No Presentations Found")]));
}