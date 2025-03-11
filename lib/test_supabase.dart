import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bjtijiyjqmfphyibkpma.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJqdGlqaXlqcW1mcGh5aWJrcG1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA2NDU5NzAsImV4cCI6MjA1NjIyMTk3MH0.BrPFmPy39lkXQbFWjrMMbcc-AEabWTEgppaK1ddqU8k',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TestPage(),
    );
  }
}

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  String _status = 'Testing Supabase connection...';

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    try {
      final client = Supabase.instance.client;

      // Try to get the current user
      final user = client.auth.currentUser;

      setState(() {
        _status =
            'Connection successful!\nCurrent user: ${user?.email ?? 'Not logged in'}';
      });
    } catch (e) {
      setState(() {
        _status = 'Connection error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supabase Test')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _status,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _testConnection,
                child: const Text('Test Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
