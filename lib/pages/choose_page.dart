import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:choose/models/history_model.dart';

class ChoosePage extends StatefulWidget {
  final HistoryModel historyModel;

  const ChoosePage({super.key, required this.historyModel});

  @override
  State<ChoosePage> createState() => ChoosePageState();
}

class ChoosePageState extends State<ChoosePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final List<Entry> _entries = [];
  int? _highlightIndex;
  Timer? _animationTimer;

  bool _selectionMode = false;
  final Set<int> _selectedIndices = {};

  void _addEntry() {
    final name = _nameController.text.trim();
    final weightStr = _weightController.text.trim();
    if (name.isEmpty || weightStr.isEmpty) return;
    final weight = int.tryParse(weightStr);
    if (weight == null || weight <= 0) return;
    setState(() {
      _entries.add(Entry(name: name, weight: weight));
      _nameController.clear();
      _weightController.clear();
    });
  }

  void _reset() {
    setState(() {
      _entries.clear();
      _highlightIndex = null;
      _selectionMode = false;
      _selectedIndices.clear();
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      _selectedIndices.clear();
    });
  }

  void _deleteSelected() {
    if (_selectedIndices.isEmpty) return;
    setState(() {
      _entries.removeWhere((e) => _selectedIndices.contains(_entries.indexOf(e)));
      _selectedIndices.clear();
      _selectionMode = false;
      _highlightIndex = null;
    });
  }

  void _draw() {
    if (_entries.isEmpty) return;
    final winnerIndex = _getWeightedRandomIndex();

    const tick = Duration(milliseconds: 120);
    const totalDuration = Duration(seconds: 3);
    int elapsed = 0;

    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(tick, (timer) {
      setState(() {
        _highlightIndex = (_highlightIndex == null)
            ? 0
            : (_highlightIndex! + 1) % _entries.length;
      });

      elapsed += tick.inMilliseconds;
      if (elapsed >= totalDuration.inMilliseconds) {
        timer.cancel();
        setState(() {
          _highlightIndex = winnerIndex;
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          _showResultDialog(_entries[winnerIndex].name);
        });
      }
    });
  }

  int _getWeightedRandomIndex() {
    final totalWeight = _entries.fold<int>(0, (p, e) => p + e.weight);
    final rnd = Random().nextInt(totalWeight);
    int cumulative = 0;
    for (int i = 0; i < _entries.length; i++) {
      cumulative += _entries[i].weight;
      if (rnd < cumulative) return i;
    }
    return 0;
  }

  void _showResultDialog(String winner) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('抽取结果'),
        content: Text('抽中了: $winner'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }

  void _saveCombo() async {
    if (_entries.isEmpty) return;
    final comboNameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('命名组合'),
        content: TextField(
          controller: comboNameController,
          decoration: const InputDecoration(labelText: '组合名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = comboNameController.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(context).pop(text);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await widget.historyModel.addCombo(
        SavedCombo(comboName: name, entries: List<Entry>.from(_entries)),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('组合已保存')),
      );
    }
  }

  void loadCombo(List<Entry> entries) {
    setState(() {
      _entries
        ..clear()
        ..addAll(entries.map((e) => Entry(name: e.name, weight: e.weight)));
      _highlightIndex = null;
      _selectionMode = false;
      _selectedIndices.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: '名字'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _weightController,
                  decoration: const InputDecoration(labelText: '权重'),
                  keyboardType: TextInputType.number,
                ),
              ),
              IconButton(
                color: Colors.teal,
                icon: const Icon(Icons.add_circle),
                onPressed: _addEntry,
              ),
              IconButton(
                icon: Icon(_selectionMode ? Icons.close : Icons.check_box_outline_blank),
                onPressed: _entries.isEmpty ? null : _toggleSelectionMode,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final e = _entries[index];
                final isHighlight = index == _highlightIndex;
                final selected = _selectedIndices.contains(index);
                return Card(
                  color: selected
                      ? Colors.orange.shade100
                      : (isHighlight ? Colors.orange.shade100 : null),
                  child: ListTile(
                    leading: _selectionMode
                        ? Checkbox(
                            value: selected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedIndices.add(index);
                                } else {
                                  _selectedIndices.remove(index);
                                }
                              });
                            },
                          )
                        : const Icon(Icons.person_outline),
                    title: Text(e.name,
                        style: TextStyle(
                            color: isHighlight ? Colors.deepOrange : null,
                            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal)),
                    trailing: _selectionMode
                        ? null
                        : Text('${e.weight}',
                            style: TextStyle(
                                color: isHighlight ? Colors.deepOrange : null,
                                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal)),
                    onTap: () {
                      if (_selectionMode) {
                        setState(() {
                          selected ? _selectedIndices.remove(index) : _selectedIndices.add(index);
                        });
                      }
                    },
                    onLongPress: () {
                      if (!_selectionMode) {
                        _toggleSelectionMode();
                        setState(() {
                          _selectedIndices.add(index);
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          _selectionMode
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _toggleSelectionMode,
                      icon: const Icon(Icons.close),
                      label: const Text('取消'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed:
                          _selectedIndices.isEmpty ? null : _deleteSelected,
                      icon: const Icon(Icons.delete),
                      label: Text('删除已选(${_selectedIndices.length})'),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      onPressed: _draw,
                      icon: const Icon(Icons.casino),
                      label: const Text('抽取'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重置'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _saveCombo,
                      icon: const Icon(Icons.save),
                      label: const Text('保存组合'),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _nameController.dispose();
    _weightController.dispose();
    super.dispose();
  }
} 