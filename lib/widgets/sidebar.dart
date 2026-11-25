import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/workspace_provider.dart';
import '../utils/theme.dart';

class NotionSidebar extends StatefulWidget {
  const NotionSidebar({super.key});

  @override
  State<NotionSidebar> createState() => _NotionSidebarState();
}

class _NotionSidebarState extends State<NotionSidebar> {
  bool _showSearch = false;
  final _searchController = TextEditingController();
  final Set<String> _expandedPages = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();
    final isDark = provider.isDarkMode;
    final sidebarBg = isDark ? AppTheme.sidebarDark : AppTheme.sidebarLight;
    final textColor = isDark ? const Color(0xFFCFCFCF) : const Color(0xFF37352F);

    return Container(
      width: 260,
      color: sidebarBg,
      child: Column(
        children: [
          // Workspace Header
          _buildWorkspaceHeader(context, provider, textColor, isDark),
          // Search & Actions
          _buildQuickActions(context, provider, textColor, isDark),
          if (_showSearch) _buildSearchBar(provider, isDark),
          const SizedBox(height: 4),
          // Pages List
          Expanded(
            child: _showSearch && provider.searchQuery.isNotEmpty
                ? _buildSearchResults(provider, textColor)
                : _buildPageTree(provider, textColor, isDark),
          ),
          // Bottom Actions
          _buildBottomActions(context, provider, textColor, isDark),
        ],
      ),
    );
  }

  Widget _buildWorkspaceHeader(BuildContext context, WorkspaceProvider provider,
      Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.notionBlue,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Text('N', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'My Workspace',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.notionGray),
            onPressed: () => provider.createPage(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: 'New Page',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WorkspaceProvider provider,
      Color textColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          _sidebarItem(
            icon: Icons.search,
            label: 'Search',
            textColor: textColor,
            isDark: isDark,
            onTap: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  provider.setSearchQuery('');
                }
              });
            },
          ),
          _sidebarItem(
            icon: Icons.home_outlined,
            label: 'Home',
            textColor: textColor,
            isDark: isDark,
            onTap: () {},
          ),
          _sidebarItem(
            icon: Icons.inbox_outlined,
            label: 'Inbox',
            textColor: textColor,
            isDark: isDark,
            onTap: () {},
          ),
          _sidebarItem(
            icon: provider.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            label: provider.isDarkMode ? 'Light Mode' : 'Dark Mode',
            textColor: textColor,
            isDark: isDark,
            onTap: provider.toggleDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(WorkspaceProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Search pages...',
          hintStyle: const TextStyle(color: AppTheme.notionGray, fontSize: 13),
          prefixIcon: const Icon(Icons.search, size: 16, color: AppTheme.notionGray),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFEEEEEE),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          isDense: true,
        ),
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF37352F),
          fontSize: 13,
        ),
        onChanged: provider.setSearchQuery,
      ),
    );
  }

  Widget _buildSearchResults(WorkspaceProvider provider, Color textColor) {
    final results = provider.searchResults;
    if (results.isEmpty) {
      return const Center(
        child: Text('No results', style: TextStyle(color: AppTheme.notionGray, fontSize: 13)),
      );
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, i) {
        final page = results[i];
        return _pageItem(context, page, provider, textColor, 0);
      },
    );
  }

  Widget _buildPageTree(WorkspaceProvider provider, Color textColor, bool isDark) {
    return ListView(
      children: [
        // Favorites
        if (provider.favoritePages.isNotEmpty) ...[
          _sectionHeader('FAVORITES', textColor),
          ...provider.favoritePages.map(
            (p) => _pageTreeItem(context, p, provider, textColor, isDark, 0),
          ),
          const SizedBox(height: 8),
        ],
        // Private Pages
        _sectionHeader('PRIVATE', textColor),
        ...provider.rootPages.map(
          (p) => _pageTreeItem(context, p, provider, textColor, isDark, 0),
        ),
        // Add new page button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: _addPageButton(context, provider, textColor),
        ),
        const SizedBox(height: 8),
        // Trash
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _sidebarItem(
            icon: Icons.delete_outline,
            label: 'Trash',
            textColor: AppTheme.notionGray,
            isDark: isDark,
            onTap: () => _showTrash(context, provider),
          ),
        ),
      ],
    );
  }

  Widget _pageTreeItem(BuildContext context, NotionPage page,
      WorkspaceProvider provider, Color textColor, bool isDark, int depth) {
    final isExpanded = _expandedPages.contains(page.id);
    final hasChildren = page.childIds.isNotEmpty;
    final isCurrent = provider.currentPageId == page.id;
    final children = provider.getChildPages(page.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pageItem(context, page, provider, textColor, depth,
            isExpanded: isExpanded,
            hasChildren: hasChildren,
            isCurrent: isCurrent,
            onToggle: hasChildren
                ? () => setState(() {
                      if (isExpanded) {
                        _expandedPages.remove(page.id);
                      } else {
                        _expandedPages.add(page.id);
                      }
                    })
                : null),
        if (isExpanded && children.isNotEmpty)
          ...children.map((child) => _pageTreeItem(
              context, child, provider, textColor, isDark, depth + 1)),
      ],
    );
  }

  Widget _pageItem(
    BuildContext context,
    NotionPage page,
    WorkspaceProvider provider,
    Color textColor,
    int depth, {
    bool isExpanded = false,
    bool hasChildren = false,
    bool isCurrent = false,
    VoidCallback? onToggle,
  }) {
    final isDark = provider.isDarkMode;
    return InkWell(
      onTap: () => provider.navigateTo(page.id),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        margin: EdgeInsets.only(left: depth * 12.0 + 8, right: 8, top: 1, bottom: 1),
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
        decoration: BoxDecoration(
          color: isCurrent
              ? (isDark ? const Color(0xFF37352F) : const Color(0xFFEEEEEE))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            if (hasChildren)
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  isExpanded ? Icons.expand_more : Icons.chevron_right,
                  size: 16,
                  color: AppTheme.notionGray,
                ),
              )
            else
              const SizedBox(width: 16),
            const SizedBox(width: 4),
            Text(page.icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                page.title.isEmpty ? 'Untitled' : page.title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13.5,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Page actions on hover - simplified
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, size: 14, color: AppTheme.notionGray),
              padding: EdgeInsets.zero,
              iconSize: 14,
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'add_child', child: Row(children: [Icon(Icons.add, size: 14), SizedBox(width: 8), Text('Add sub-page')])),
                PopupMenuItem(value: 'favorite', child: Row(children: [Icon(provider.isFavorite(page.id) ? Icons.star : Icons.star_border, size: 14), const SizedBox(width: 8), Text(provider.isFavorite(page.id) ? 'Remove from favorites' : 'Add to favorites')])),
                const PopupMenuItem(value: 'duplicate', child: Row(children: [Icon(Icons.copy_outlined, size: 14), SizedBox(width: 8), Text('Duplicate')])),
                const PopupMenuItem(value: 'trash', child: Row(children: [Icon(Icons.delete_outline, size: 14), SizedBox(width: 8), Text('Move to Trash')])),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'add_child':
                    provider.createPage(parentId: page.id);
                    setState(() => _expandedPages.add(page.id));
                    break;
                  case 'favorite':
                    provider.toggleFavorite(page.id);
                    break;
                  case 'trash':
                    provider.moveToTrash(page.id);
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _addPageButton(BuildContext context, WorkspaceProvider provider, Color textColor) {
    return InkWell(
      onTap: () => provider.createPage(),
      borderRadius: BorderRadius.circular(4),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            SizedBox(width: 16),
            SizedBox(width: 4),
            Icon(Icons.add, size: 16, color: AppTheme.notionGray),
            SizedBox(width: 6),
            Text('Add a page', style: TextStyle(color: AppTheme.notionGray, fontSize: 13.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, WorkspaceProvider provider,
      Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: _sidebarItem(
        icon: Icons.settings_outlined,
        label: 'Settings',
        textColor: textColor,
        isDark: isDark,
        onTap: () => _showSettings(context, provider),
      ),
    );
  }

  Widget _sidebarItem({
    required IconData icon,
    required String label,
    required Color textColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.notionGray),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: textColor, fontSize: 13.5)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4, right: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.notionGray,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  void _showTrash(BuildContext context, WorkspaceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trash'),
        content: SizedBox(
          width: 400,
          child: provider.trashPages.isEmpty
              ? const Text('Trash is empty')
              : ListView(
                  shrinkWrap: true,
                  children: provider.trashPages.map((p) {
                    return ListTile(
                      leading: Text(p.icon),
                      title: Text(p.title.isEmpty ? 'Untitled' : p.title),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () {
                              provider.restorePage(p.id);
                              Navigator.pop(ctx);
                            },
                            child: const Text('Restore'),
                          ),
                          TextButton(
                            onPressed: () {
                              provider.deletePage(p.id);
                              Navigator.pop(ctx);
                            },
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  void _showSettings(BuildContext context, WorkspaceProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settings'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: provider.isDarkMode,
                onChanged: (_) => provider.toggleDarkMode(),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }
}
