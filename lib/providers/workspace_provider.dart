import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class WorkspaceProvider extends ChangeNotifier {
  Map<String, NotionPage> _pages = {};
  String? _currentPageId;
  bool _isSidebarOpen = true;
  bool _isDarkMode = false;
  String _searchQuery = '';
  List<String> _rootPageIds = [];
  List<String> _favoritePageIds = [];
  List<String> _recentPageIds = [];
  bool _isLoading = true;

  // ─── Getters ────────────────────────────────────────────────────────────────
  Map<String, NotionPage> get pages => _pages;
  String? get currentPageId => _currentPageId;
  NotionPage? get currentPage =>
      _currentPageId != null ? _pages[_currentPageId] : null;
  bool get isSidebarOpen => _isSidebarOpen;
  bool get isDarkMode => _isDarkMode;
  String get searchQuery => _searchQuery;
  List<String> get rootPageIds => _rootPageIds;
  bool get isLoading => _isLoading;

  List<NotionPage> get favoritePages => _favoritePageIds
      .where((id) => _pages.containsKey(id))
      .map((id) => _pages[id]!)
      .toList();

  List<NotionPage> get recentPages => _recentPageIds
      .where((id) => _pages.containsKey(id))
      .map((id) => _pages[id]!)
      .take(5)
      .toList();

  List<NotionPage> get trashPages =>
      _pages.values.where((p) => p.isInTrash).toList();

  List<NotionPage> get searchResults {
    if (_searchQuery.isEmpty) return [];
    final q = _searchQuery.toLowerCase();
    return _pages.values
        .where((p) =>
            !p.isInTrash &&
            (p.title.toLowerCase().contains(q) ||
                p.blocks.any((b) => b.content.toLowerCase().contains(q))))
        .toList();
  }

  // ─── Init ───────────────────────────────────────────────────────────────────
  WorkspaceProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final pagesJson = prefs.getString('pages');
    final rootIds = prefs.getStringList('rootPageIds');
    final favIds = prefs.getStringList('favoritePageIds');
    final recentIds = prefs.getStringList('recentPageIds');
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;

    if (pagesJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(pagesJson);
      _pages = decoded.map((k, v) => MapEntry(k, NotionPage.fromJson(v)));
    }
    _rootPageIds = rootIds ?? [];
    _favoritePageIds = favIds ?? [];
    _recentPageIds = recentIds ?? [];

    if (_pages.isEmpty) {
      _createDefaultContent();
    }

    _isLoading = false;
    notifyListeners();
  }

  void _createDefaultContent() {
    // Welcome page
    final welcomePage = NotionPage(
      title: 'Getting Started',
      icon: '👋',
      blocks: [
        Block(
          type: BlockType.heading1,
          content: 'Welcome to Notion Clone!',
        ),
        Block(
          type: BlockType.text,
          content:
              'This is your personal workspace. You can create pages, take notes, and organize your thoughts.',
        ),
        Block(
          type: BlockType.heading2,
          content: 'Quick Tips',
        ),
        Block(
          type: BlockType.bulletList,
          content: 'Press + to add a new block',
        ),
        Block(
          type: BlockType.bulletList,
          content: 'Type / to see all block types',
        ),
        Block(
          type: BlockType.bulletList,
          content: 'Click the sidebar to navigate pages',
        ),
        Block(
          type: BlockType.todoList,
          content: 'Create your first page',
          checked: false,
        ),
        Block(
          type: BlockType.todoList,
          content: 'Explore block types',
          checked: false,
        ),
        Block(
          type: BlockType.callout,
          content: '💡 Tip: You can drag and drop blocks to rearrange them.',
          icon: '💡',
          backgroundColor: const Color(0xFFFFF9C4),
        ),
      ],
    );

    // My Notes page
    final notesPage = NotionPage(
      title: 'My Notes',
      icon: '📝',
      blocks: [
        Block(type: BlockType.heading1, content: 'My Notes'),
        Block(type: BlockType.text, content: 'Start writing here...'),
      ],
    );

    // Tasks page
    final tasksPage = NotionPage(
      title: 'Tasks',
      icon: '✅',
      blocks: [
        Block(type: BlockType.heading1, content: 'Tasks'),
        Block(
          type: BlockType.todoList,
          content: 'Buy groceries',
          checked: true,
        ),
        Block(
          type: BlockType.todoList,
          content: 'Read a book',
          checked: false,
        ),
        Block(
          type: BlockType.todoList,
          content: 'Exercise',
          checked: false,
        ),
      ],
    );

    _pages[welcomePage.id] = welcomePage;
    _pages[notesPage.id] = notesPage;
    _pages[tasksPage.id] = tasksPage;
    _rootPageIds = [welcomePage.id, notesPage.id, tasksPage.id];
    _currentPageId = welcomePage.id;
    _saveData();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final pagesJson = jsonEncode(_pages.map((k, v) => MapEntry(k, v.toJson())));
    await prefs.setString('pages', pagesJson);
    await prefs.setStringList('rootPageIds', _rootPageIds);
    await prefs.setStringList('favoritePageIds', _favoritePageIds);
    await prefs.setStringList('recentPageIds', _recentPageIds);
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  // ─── Page Operations ────────────────────────────────────────────────────────
  String createPage(
      {String? parentId, String title = 'Untitled', String icon = '📄'}) {
    final page = NotionPage(
      title: title,
      icon: icon,
      blocks: [Block(type: BlockType.text, content: '')],
      parentId: parentId,
    );
    _pages[page.id] = page;

    if (parentId != null && _pages.containsKey(parentId)) {
      _pages[parentId]!.childIds.add(page.id);
    } else {
      _rootPageIds.add(page.id);
    }

    _currentPageId = page.id;
    _addToRecent(page.id);
    _saveData();
    notifyListeners();
    return page.id;
  }

  void deletePage(String pageId) {
    final page = _pages[pageId];
    if (page == null) return;

    // Recursively delete children
    for (final childId in List.from(page.childIds)) {
      deletePage(childId);
    }

    // Remove from parent
    if (page.parentId != null && _pages.containsKey(page.parentId)) {
      _pages[page.parentId]!.childIds.remove(pageId);
    } else {
      _rootPageIds.remove(pageId);
    }

    _pages.remove(pageId);
    _favoritePageIds.remove(pageId);
    _recentPageIds.remove(pageId);

    if (_currentPageId == pageId) {
      _currentPageId = _rootPageIds.isNotEmpty ? _rootPageIds.first : null;
    }

    _saveData();
    notifyListeners();
  }

  void moveToTrash(String pageId) {
    if (_pages.containsKey(pageId)) {
      _pages[pageId] = _pages[pageId]!.copyWith(isInTrash: true);
      _rootPageIds.remove(pageId);
      if (_currentPageId == pageId) {
        _currentPageId = _rootPageIds.isNotEmpty ? _rootPageIds.first : null;
      }
      _saveData();
      notifyListeners();
    }
  }

  void restorePage(String pageId) {
    if (_pages.containsKey(pageId)) {
      _pages[pageId] = _pages[pageId]!.copyWith(isInTrash: false);
      if (_pages[pageId]!.parentId == null) {
        _rootPageIds.add(pageId);
      }
      _saveData();
      notifyListeners();
    }
  }

  void updatePage(NotionPage page) {
    _pages[page.id] = page.copyWith(updatedAt: DateTime.now());
    _saveData();
    notifyListeners();
  }

  void updatePageTitle(String pageId, String title) {
    if (_pages.containsKey(pageId)) {
      _pages[pageId] = _pages[pageId]!.copyWith(
        title: title,
        updatedAt: DateTime.now(),
      );
      _saveData();
      notifyListeners();
    }
  }

  void updatePageIcon(String pageId, String icon) {
    if (_pages.containsKey(pageId)) {
      _pages[pageId] = _pages[pageId]!.copyWith(icon: icon);
      _saveData();
      notifyListeners();
    }
  }

  // ─── Block Operations ────────────────────────────────────────────────────────
  void addBlock(String pageId, Block block, {int? atIndex}) {
    if (!_pages.containsKey(pageId)) return;
    final page = _pages[pageId]!;
    final blocks = List<Block>.from(page.blocks);
    if (atIndex != null) {
      blocks.insert(atIndex, block);
    } else {
      blocks.add(block);
    }
    _pages[pageId] = page.copyWith(blocks: blocks, updatedAt: DateTime.now());
    _saveData();
    notifyListeners();
  }

  void updateBlock(String pageId, Block block) {
    if (!_pages.containsKey(pageId)) return;
    final page = _pages[pageId]!;
    final blocks =
        page.blocks.map((b) => b.id == block.id ? block : b).toList();
    _pages[pageId] = page.copyWith(blocks: blocks, updatedAt: DateTime.now());
    _saveData();
    notifyListeners();
  }

  void deleteBlock(String pageId, String blockId) {
    if (!_pages.containsKey(pageId)) return;
    final page = _pages[pageId]!;
    final blocks = page.blocks.where((b) => b.id != blockId).toList();
    _pages[pageId] = page.copyWith(blocks: blocks, updatedAt: DateTime.now());
    _saveData();
    notifyListeners();
  }

  void reorderBlocks(String pageId, int oldIndex, int newIndex) {
    if (!_pages.containsKey(pageId)) return;
    final page = _pages[pageId]!;
    final blocks = List<Block>.from(page.blocks);
    final item = blocks.removeAt(oldIndex);
    blocks.insert(newIndex, item);
    _pages[pageId] = page.copyWith(blocks: blocks, updatedAt: DateTime.now());
    _saveData();
    notifyListeners();
  }

  // ─── Navigation ──────────────────────────────────────────────────────────────
  void navigateTo(String pageId) {
    _currentPageId = pageId;
    _addToRecent(pageId);
    notifyListeners();
  }

  void _addToRecent(String pageId) {
    _recentPageIds.remove(pageId);
    _recentPageIds.insert(0, pageId);
    if (_recentPageIds.length > 10) {
      _recentPageIds = _recentPageIds.take(10).toList();
    }
  }

  // ─── UI State ────────────────────────────────────────────────────────────────
  void toggleSidebar() {
    _isSidebarOpen = !_isSidebarOpen;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _saveData();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleFavorite(String pageId) {
    if (_favoritePageIds.contains(pageId)) {
      _favoritePageIds.remove(pageId);
    } else {
      _favoritePageIds.add(pageId);
    }
    if (_pages.containsKey(pageId)) {
      _pages[pageId] = _pages[pageId]!.copyWith(
        isFavorite: _favoritePageIds.contains(pageId),
      );
    }
    _saveData();
    notifyListeners();
  }

  bool isFavorite(String pageId) => _favoritePageIds.contains(pageId);

  List<NotionPage> getChildPages(String pageId) {
    if (!_pages.containsKey(pageId)) return [];
    return _pages[pageId]!
        .childIds
        .where((id) => _pages.containsKey(id))
        .map((id) => _pages[id]!)
        .where((p) => !p.isInTrash)
        .toList();
  }

  List<NotionPage> get rootPages => _rootPageIds
      .where((id) => _pages.containsKey(id))
      .map((id) => _pages[id]!)
      .where((p) => !p.isInTrash)
      .toList();
}
