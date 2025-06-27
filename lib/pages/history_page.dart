import 'package:flutter/material.dart';
import 'package:choose/models/history_model.dart';

class HistoryPage extends StatefulWidget {
  final HistoryModel historyModel;
  final void Function(SavedCombo combo)? onUse;

  const HistoryPage({super.key, required this.historyModel, this.onUse});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _selectionMode = false;
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    widget.historyModel.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.historyModel.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final combos = widget.historyModel.combos;

    Widget buildTopBar() {
      return Row(
        children: [
          IconButton(
            icon: Icon(_selectionMode ? Icons.close : Icons.check_box_outline_blank),
            onPressed: () {
              setState(() {
                _selectionMode = !_selectionMode;
                _selectedIndices.clear();
              });
            },
          ),
          const SizedBox(width: 4),
          Text(_selectionMode ? '选择组合' : '记录', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      );
    }

    Widget buildList() {
      return Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final combo = combos[index];
            final selected = _selectedIndices.contains(index);
            return Card(
              color: selected ? Colors.orange.shade100 : null,
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
                    : const Icon(Icons.list_alt),
                title: Text(combo.comboName),
                subtitle: Text(combo.entries.map((e) => '${e.name}(${e.weight})').join(', ')),
                trailing: _selectionMode
                    ? null
                    : ElevatedButton.icon(
                        onPressed: widget.onUse == null ? null : () => widget.onUse!(combo),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('使用'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      ),
                onTap: () {
                  if (_selectionMode) {
                    setState(() {
                      selected ? _selectedIndices.remove(index) : _selectedIndices.add(index);
                    });
                  }
                },
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: combos.length,
        ),
      );
    }

    Widget buildDeleteButton() {
      if (!_selectionMode || _selectedIndices.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            final toDelete = _selectedIndices.map((i) => combos[i]).toList();
            await widget.historyModel.removeCombos(toDelete);
            setState(() {
              _selectedIndices.clear();
              _selectionMode = false;
            });
          },
          icon: const Icon(Icons.delete),
          label: Text('删除已选（${_selectedIndices.length}）'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTopBar(),
        buildList(),
        buildDeleteButton(),
      ],
    );
  }
} 