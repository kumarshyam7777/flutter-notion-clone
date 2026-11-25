import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workspace_provider.dart';
import '../widgets/sidebar.dart';
import '../screens/page_editor.dart';
import '../screens/empty_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();
    final isDark = provider.isDarkMode;

    if (provider.isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF191919) : Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF191919) : Colors.white,
      body: Row(
        children: [
          // Sidebar with animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: provider.isSidebarOpen ? 260 : 0,
            child: provider.isSidebarOpen
                ? const NotionSidebar()
                : const SizedBox.shrink(),
          ),
          // Vertical divider
          if (provider.isSidebarOpen)
            VerticalDivider(
              width: 1,
              color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE9E9E7),
            ),
          // Main content
          Expanded(
            child: provider.currentPageId != null
                ? PageEditor(key: ValueKey(provider.currentPageId), pageId: provider.currentPageId!)
                : const EmptyState(),
          ),
        ],
      ),
    );
  }
}
