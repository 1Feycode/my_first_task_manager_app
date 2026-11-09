import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

class StorageService {
	static const String _tasksKey = 'saved_tasks';

	Future<List<Task>> loadTasks() async {
		try {
			final prefs = await SharedPreferences.getInstance();
			final savedData = prefs.getString(_tasksKey);

			if (savedData == null || savedData.isEmpty) {
				return [];
			}

			final decoded = jsonDecode(savedData);
			if (decoded is! List) {
				return [];
			}

			return decoded
					.whereType<Map>()
					.map((item) => Task.fromJson(Map<String, dynamic>.from(item)))
					.toList();
		} catch (_) {
			return [];
		}
	}

	Future<void> saveTasks(List<Task> tasks) async {
		try {
			final prefs = await SharedPreferences.getInstance();
			final encodedTasks = tasks.map((task) => task.toJson()).toList();
			await prefs.setString(_tasksKey, jsonEncode(encodedTasks));
		} catch (_) {
			// Ignore storage errors and keep the app running safely.
		}
	}

	Future<void> deleteAllTasks() async {
		try {
			final prefs = await SharedPreferences.getInstance();
			await prefs.remove(_tasksKey);
		} catch (_) {
			// Ignore storage errors and keep the app running safely.
		}
	}
}
