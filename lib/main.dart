import 'package:flutter/material.dart';
import 'package:profin1/services/supabase_service.dart';
import 'package:profin1/screens/landing_page.dart';
import 'package:provider/provider.dart';
import 'package:profin1/providers/user_provider.dart';
import 'package:profin1/providers/team_provider.dart';
import 'package:profin1/providers/task_provider.dart';
import 'package:profin1/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:profin1/screens/auth/login_screen.dart';
import 'package:profin1/screens/auth/signup_screen.dart';
import 'package:profin1/screens/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with direct values since we're in development
  await Supabase.initialize(
    url: 'https://bjtijiyjqmfphyibkpma.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJqdGlqaXlqcW1mcGh5aWJrcG1hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA2NDU5NzAsImV4cCI6MjA1NjIyMTk3MH0.BrPFmPy39lkXQbFWjrMMbcc-AEabWTEgppaK1ddqU8k',
  );

  // Create an instance of SupabaseService with Supabase client
  final supabaseService = SupabaseService(Supabase.instance.client);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(supabaseService)),
        ChangeNotifierProvider(create: (_) => UserProvider(supabaseService)),
        ChangeNotifierProvider(create: (_) => TeamProvider(supabaseService)),
        ChangeNotifierProvider(create: (_) => TaskProvider(supabaseService)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Management System',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}
