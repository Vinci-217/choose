import 'package:flutter/material.dart';
import 'package:choose/pages/choose_page.dart';
import 'package:choose/pages/history_page.dart';
import 'package:choose/models/history_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final historyModel = HistoryModel();
  await historyModel.load();
  runApp(MyApp(historyModel: historyModel));
}

class MyApp extends StatelessWidget {
  final HistoryModel historyModel;

  const MyApp({super.key, required this.historyModel});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '抽选器',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: HomePage(historyModel: historyModel),
    );
  }
}

class HomePage extends StatefulWidget {
  final HistoryModel historyModel;

  const HomePage({super.key, required this.historyModel});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final GlobalKey<ChoosePageState> _chooseKey = GlobalKey<ChoosePageState>();
  List<Entry>? _pendingEntries;

  @override
  Widget build(BuildContext context) {
    final pages = [
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: ChoosePage(key: _chooseKey, historyModel: widget.historyModel),
        ),
      ),
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: HistoryPage(
            historyModel: widget.historyModel,
            onUse: (combo) {
              setState(() {
                _pendingEntries = combo.entries;
                _currentIndex = 0;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_pendingEntries != null) {
                  _chooseKey.currentState?.loadCombo(_pendingEntries!
                      .map((e) => Entry(name: e.name, weight: e.weight))
                      .toList());
                  _pendingEntries = null;
                }
              });
            },
          ),
        ),
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.casino), label: '抽选'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '记录'),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.teal,
      ),
    );
  }
} 