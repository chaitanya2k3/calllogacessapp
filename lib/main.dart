import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:call_log/call_log.dart';
import 'package:intl/intl.dart';

Future<void> requestPermissions() async {
  var status = await Permission.phone.status;
  if (!status.isGranted) {
    await Permission.phone.request();
  }
}

void main() {
  runApp(MyApp());
  requestPermissions(); // Call this function early in your app's lifecycle
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CallLogScreen(),
    );
  }
}

class CallLogScreen extends StatefulWidget {
  @override
  _CallLogScreenState createState() => _CallLogScreenState();
}

class _CallLogScreenState extends State<CallLogScreen> {
  List<CallLogEntry>? _allCallLogEntries;
  List<CallLogEntry>? _filteredCallLogEntries;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCallLogs);
    _fetchCallLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCallLogs() async {
    Iterable<CallLogEntry> entries = await CallLog.get();
    setState(() {
      _allCallLogEntries = entries.toList();
      _filteredCallLogEntries = _allCallLogEntries;
    });
  }

  void _filterCallLogs() {
    String query = _searchController.text;
    setState(() {
      _filteredCallLogEntries = _allCallLogEntries?.where((entry) {
        return (entry.name?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
            (entry.number?.contains(query) ?? false);
      }).toList();
    });
  }

  String formatDuration(int? duration) {
    if (duration == null) return 'Unknown Duration';
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: TextStyle(color: Colors.black),
            border: InputBorder.none,
          ),
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.cancel),
            onPressed: () {
              _searchController.clear();
            },
          ),
        ],
      ),
      body: _allCallLogEntries == null ? Center(child: CircularProgressIndicator()) : ListView.builder(
        itemCount: _filteredCallLogEntries?.length ?? 0,
        itemBuilder: (context, index) {
          final entry = _filteredCallLogEntries![index];
          String formattedTime = DateFormat('yyyy-MM-dd – kk:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(entry.timestamp!));
          return ListTile(
            title: Text(entry.name ?? 'Unknown'),
            subtitle: Text('${entry.number ?? 'No number'}\n$formattedTime'),
            isThreeLine: true,
            trailing: Text(formatDuration(entry.duration)),
            leading: Icon(Icons.call),
          );
        },
      ),
    );
  }
}
