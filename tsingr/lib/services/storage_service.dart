import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_record.dart';

class StorageService {
  static const String _recordsKey = 'study_records';

  // 保存所有学习记录
  static Future<void> saveRecords(Map<int, StudyRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonMap = records.map(
      (key, value) => MapEntry(key.toString(), value.toJson()),
    );
    await prefs.setString(_recordsKey, jsonEncode(jsonMap));
  }

  // 加载所有学习记录
  static Future<Map<int, StudyRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_recordsKey);

    if (jsonString == null) {
      return {};
    }

    final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
    return jsonMap.map(
      (key, value) => MapEntry(
        int.parse(key),
        StudyRecord.fromJson(value),
      ),
    );
  }

  // 保存单个学习记录
  static Future<void> saveRecord(StudyRecord record) async {
    final records = await loadRecords();
    records[record.questionId] = record;
    await saveRecords(records);
  }

  // 获取单个学习记录
  static Future<StudyRecord?> getRecord(int questionId) async {
    final records = await loadRecords();
    return records[questionId];
  }

  // 清除所有记录
  static Future<void> clearAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recordsKey);
  }
}
