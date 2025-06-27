import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Entry {
  final String name;
  final int weight;

  Entry({required this.name, required this.weight});

  Map<String, dynamic> toJson() => {
        'name': name,
        'weight': weight,
      };

  factory Entry.fromJson(Map<String, dynamic> json) => Entry(
        name: json['name'] as String,
        weight: json['weight'] as int,
      );
}

class SavedCombo {
  final String comboName;
  final List<Entry> entries;

  SavedCombo({required this.comboName, required this.entries});

  Map<String, dynamic> toJson() => {
        'comboName': comboName,
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  factory SavedCombo.fromJson(Map<String, dynamic> json) => SavedCombo(
        comboName: json['comboName'] as String,
        entries: (json['entries'] as List)
            .map((e) => Entry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  String toString() {
    return '$comboName: ${entries.map((e) => '${e.name}(${e.weight})').join(', ')}';
  }
}

class HistoryModel extends ChangeNotifier {
  static const _storageKey = 'saved_combos';

  final List<SavedCombo> _combos = [];

  List<SavedCombo> get combos => List.unmodifiable(_combos);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    _combos
      ..clear()
      ..addAll(raw.map((e) => SavedCombo.fromJson(jsonDecode(e))));
    notifyListeners();
  }

  Future<void> addCombo(SavedCombo combo) async {
    _combos.add(combo);
    await _save();
    notifyListeners();
  }

  Future<void> removeCombos(Iterable<SavedCombo> toRemove) async {
    _combos.removeWhere((c) => toRemove.contains(c));
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _combos.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }
} 