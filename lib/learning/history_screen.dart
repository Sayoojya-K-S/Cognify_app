import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  void loadHistory() async {
    // Calling the getHistory func from your existing AIService
    var data = await AIService().getHistory();
    if (mounted) {
      setState(() {
        history = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
              ? const Center(child: Text("No history available yet!"))
              : ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    var item = history[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.history, color: Colors.blue),
                        title: Text(item["summary"] ?? "No Summary", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          item["simplified_text"] ?? "",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
