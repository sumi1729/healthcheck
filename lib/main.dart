import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/registration_screen.dart';
import 'screens/results_screen.dart';
import 'viewmodels/registration_viewmodel.dart';
import 'viewmodels/results_viewmodel.dart';

void main() {
  runApp(const HealthCheckApp());
}

class HealthCheckApp extends StatelessWidget {
  const HealthCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '健康管理',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4CAF50),
          secondary: Color(0xFF66BB6A),
          surface: Color(0xFF2A2A2A),
        ),
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        useMaterial3: true,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF2A2A2A),
          selectedItemColor: Color(0xFF4CAF50),
          unselectedItemColor: Colors.white54,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF2A2A2A),
          contentTextStyle: TextStyle(color: Colors.white),
        ),
      ),
      home: const _HomeScreen(),
    );
  }
}

class _HomeScreen extends StatefulWidget {
  const _HomeScreen();

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegistrationViewModel()),
        ChangeNotifierProvider(create: (_) => ResultsViewModel()),
      ],
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              _currentIndex == 0 ? '登録' : '実績',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF2A2A2A),
            elevation: 0,
            actions: [
              if (_currentIndex == 1)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () =>
                      context.read<ResultsViewModel>().loadRecords(),
                ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: const [
              RegistrationScreen(),
              ResultsScreen(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) {
              setState(() => _currentIndex = i);
              if (i == 1) {
                context.read<ResultsViewModel>().loadRecords();
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline),
                label: '登録',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt),
                label: '実績',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
