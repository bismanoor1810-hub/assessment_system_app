import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    // Database version v18: Added ai_analysis column
    String path = join(await getDatabasesPath(), 'assessment_system_v21.db'); 
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE cache (key TEXT PRIMARY KEY, value TEXT)');
        await db.execute('CREATE TABLE users (email TEXT PRIMARY KEY, password TEXT)');
        await db.execute('CREATE TABLE students_table (id TEXT PRIMARY KEY, name TEXT, roll_no TEXT)');
        await db.execute('CREATE TABLE criteria_table (category_id TEXT PRIMARY KEY, data TEXT)');

        // ✅ Updated Table with ai_analysis
        await db.execute('''
          CREATE TABLE offline_evaluations (
            student_id TEXT,
            assessment_id TEXT,
            evaluator_id TEXT,
            data TEXT,
            student_reply TEXT,
            ai_analysis TEXT, 
            is_synced INTEGER DEFAULT 0,
            PRIMARY KEY (student_id, assessment_id, evaluator_id)
          )
        ''');

        await db.execute('''
          CREATE TABLE student_analytics (
            student_id TEXT,
            category_id TEXT,
            analytics_data TEXT,
            PRIMARY KEY (student_id, category_id)
          )
        ''');
      },
    );
  }

  // --- 1. LOGIN & USER METHODS ---
  Future<void> saveUser(String email, String password) async {
    final db = await database;
    await db.insert('users', {'email': email, 'password': password}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> checkOfflineLogin(String email, String password) async {
    final db = await database;
    final res = await db.query('users', where: 'email = ? AND password = ?', whereArgs: [email, password]);
    return res.isNotEmpty;
  }

  // --- 2. STUDENT & CRITERIA METHODS ---
  Future<void> saveStudents(List<dynamic> students) async {
    final db = await database;
    Batch batch = db.batch();
    for (var student in students) {
      batch.insert('students_table', {
        'id': student['id'].toString(),
        'name': student['name'] ?? student['username'] ?? "Unknown",
        'roll_no': student['roll_no'] ?? student['student_id'] ?? "",
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveCriteria(String categoryId, dynamic criteriaData) async {
    final db = await database;
    await db.insert('criteria_table', {
      'category_id': categoryId,
      'data': jsonEncode(criteriaData),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- 3. STUDENT ANALYTICS ---
  Future<void> saveStudentAnalytics(String studentId, String categoryId, List data) async {
    try {
      final db = await database;
      await db.delete('student_analytics', 
          where: 'student_id = ? AND category_id = ?', 
          whereArgs: [studentId, categoryId]);

      await db.insert('student_analytics', {
        'student_id': studentId,
        'category_id': categoryId,
        'analytics_data': jsonEncode(data) 
      });
    } catch (e) {
      debugPrint("Error saving analytics: $e");
    }
  }

  Future<List?> getStudentAnalytics(String studentId, String categoryId) async {
    try {
      final db = await database;
      final res = await db.query('student_analytics', 
        where: 'student_id = ? AND category_id = ?', 
        whereArgs: [studentId, categoryId]);
      
      if (res.isNotEmpty) {
        final data = jsonDecode(res.first['analytics_data'] as String);
        return data is List ? data : [data]; 
      }
    } catch (e) {
      debugPrint("Error getting analytics: $e");
    }
    return null;
  }

  // --- 4. OFFLINE EVALUATION & AI ANALYSIS ---
  
  // AI Analysis ko locally save/update karne ka naya function
  Future<void> updateLocalAiAnalysis(String studentId, String assessmentId, String analysis) async {
    final db = await database;
    await db.update(
      'offline_evaluations', 
      {'ai_analysis': analysis},
      where: 'student_id = ? AND assessment_id = ?',
      whereArgs: [studentId, assessmentId],
    );
  }

  Future<void> saveEvaluationLocally({
    required String studentId,
    required String assessmentId,
    required String evaluatorId,
    required Map<String, dynamic> data,
    String? studentReply, 
    String? aiAnalysis, // Added for AI
    int isSynced = 0, 
  }) async {
    final db = await database;
    await db.insert('offline_evaluations', {
      'student_id': studentId,
      'assessment_id': assessmentId,
      'evaluator_id': evaluatorId,
      'data': jsonEncode(data),
      'student_reply': studentReply,
      'ai_analysis': aiAnalysis, // Added for AI
      'is_synced': isSynced,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> markAsSynced(String studentId, String assessmentId, String evaluatorId) async {
    final db = await database;
    await db.update('offline_evaluations', {'is_synced': 1}, 
      where: 'student_id = ? AND assessment_id = ? AND evaluator_id = ?', 
      whereArgs: [studentId, assessmentId, evaluatorId]);
  }

  Future<List<Map<String, dynamic>>> getOfflineRecords(String assessmentId, String? evaluatorId) async {
    final db = await database;
    List<Map<String, dynamic>> res;
    if (evaluatorId == null || evaluatorId.isEmpty) {
      res = await db.query('offline_evaluations', where: 'assessment_id = ?', whereArgs: [assessmentId]);
    } else {
      res = await db.query('offline_evaluations', where: 'assessment_id = ? AND evaluator_id = ?', whereArgs: [assessmentId, evaluatorId]);
    }
    return res.map((item) {
      var mutableItem = Map<String, dynamic>.from(item);
      if (mutableItem['data'] is String) {
        mutableItem['decoded_data'] = jsonDecode(mutableItem['data']);
      }
      return mutableItem;
    }).toList();
  }

  // --- 5. CACHE SYSTEM ---
  Future<void> saveToCache(String key, dynamic data) async {
    try {
      final db = await database;
      await db.insert('cache', {'key': key, 'value': jsonEncode(data)}, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint("Cache Save Error: $e");
    }
  }

  Future<dynamic> getFromCache(String key) async {
    try {
      final db = await database;
      final res = await db.query('cache', where: 'key = ?', whereArgs: [key]);
      if (res.isNotEmpty) {
        return jsonDecode(res.first['value'] as String);
      }
    } catch (e) {
      debugPrint("Cache Get Error: $e");
    }
    return null;
  }

  // --- 6. CLEANUP ---
  Future<void> clearCache() async {
    final db = await database;
    await db.delete('cache');
    await db.delete('offline_evaluations');
    await db.delete('users');
    await db.delete('student_analytics');
    await db.delete('students_table');
    await db.delete('criteria_table');
  }
}