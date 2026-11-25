import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/workspace_provider.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NotionCloneApp());
}

class NotionCloneApp extends StatelessWidget {
  const NotionCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WorkspaceProvider(),
      child: Consumer<WorkspaceProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            title: 'Notion Clone',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
