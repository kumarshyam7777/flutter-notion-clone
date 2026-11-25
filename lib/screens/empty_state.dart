import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workspace_provider.dart';
import '../utils/theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();
    final isDark = provider.isDarkMode;
    final textColor =
        isDark ? const Color(0xFFCFCFCF) : const Color(0xFF37352F);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 80,
            color: AppTheme.notionGray.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No page selected',
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a page from the sidebar\nor create a new one',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.notionGray, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => provider.createPage(),
            icon: const Icon(Icons.add),
            label: const Text('New Page'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.notionBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
