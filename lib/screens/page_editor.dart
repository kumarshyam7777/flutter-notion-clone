import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/workspace_provider.dart';
import '../utils/theme.dart';
import '../widgets/block_widget.dart';

class PageEditor extends StatefulWidget {
  final String pageId;

  const PageEditor({super.key, required this.pageId});

  @override
  State<PageEditor> createState() => _PageEditorState();
}

class _PageEditorState extends State<PageEditor> {
  late TextEditingController _titleController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<WorkspaceProvider>();
    final page = provider.pages[widget.pageId];
    _titleController = TextEditingController(text: page?.title ?? '');
  }

  @override
  void didUpdateWidget(PageEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageId != widget.pageId) {
      final provider = context.read<WorkspaceProvider>();
      final page = provider.pages[widget.pageId];
      _titleController.text = page?.title ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkspaceProvider>();
    final page = provider.pages[widget.pageId];
    final isDark = provider.isDarkMode;

    if (page == null) {
      return const Center(
        child: Text('Page not found',
            style: TextStyle(color: AppTheme.notionGray)),
      );
    }

    return Column(
      children: [
        _buildTopBar(context, provider, page, isDark),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 96, vertical: 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover image placeholder
                      if (page.coverImage != null)
                        Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image,
                              size: 48, color: Colors.grey),
                        ),
                      // Icon
                      _buildPageIcon(context, provider, page),
                      const SizedBox(height: 12),
                      // Title
                      _buildTitle(context, provider, page, isDark),
                      const SizedBox(height: 8),
                      // Blocks
                      ..._buildBlocks(context, provider, page, isDark),
                      // Empty area tap to add block
                      GestureDetector(
                        onTap: () {
                          if (page.blocks.isEmpty ||
                              page.blocks.last.content.isNotEmpty) {
                            provider.addBlock(
                                page.id, Block(type: BlockType.text));
                          }
                        },
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, WorkspaceProvider provider,
      NotionPage page, bool isDark) {
    final textColor =
        isDark ? const Color(0xFFCFCFCF) : const Color(0xFF37352F);
    // Breadcrumb path
    final breadcrumbs = _getBreadcrumbs(provider, page);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191919) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFE9E9E7),
          ),
        ),
      ),
      child: Row(
        children: [
          // Sidebar toggle
          IconButton(
            icon: const Icon(Icons.menu, size: 18),
            onPressed: provider.toggleSidebar,
            color: AppTheme.notionGray,
          ),
          // Breadcrumbs
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < breadcrumbs.length; i++) ...[
                    if (i > 0)
                      const Icon(Icons.chevron_right,
                          size: 14, color: AppTheme.notionGray),
                    GestureDetector(
                      onTap: () {
                        if (i < breadcrumbs.length - 1) {
                          provider.navigateTo(breadcrumbs[i].id);
                        }
                      },
                      child: Row(
                        children: [
                          Text(breadcrumbs[i].icon,
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            breadcrumbs[i].title.isEmpty
                                ? 'Untitled'
                                : breadcrumbs[i].title,
                            style: TextStyle(
                              color: i == breadcrumbs.length - 1
                                  ? textColor
                                  : AppTheme.notionGray,
                              fontSize: 13,
                              fontWeight: i == breadcrumbs.length - 1
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Actions
          IconButton(
            icon: Icon(
              provider.isFavorite(page.id) ? Icons.star : Icons.star_border,
              size: 18,
              color: provider.isFavorite(page.id)
                  ? Colors.amber
                  : AppTheme.notionGray,
            ),
            onPressed: () => provider.toggleFavorite(page.id),
            tooltip: 'Favorite',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz,
                size: 18, color: AppTheme.notionGray),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                  value: 'subpage',
                  child: Row(children: [
                    Icon(Icons.add, size: 14),
                    SizedBox(width: 8),
                    Text('Add sub-page')
                  ])),
              const PopupMenuItem(
                  value: 'cover',
                  child: Row(children: [
                    Icon(Icons.image_outlined, size: 14),
                    SizedBox(width: 8),
                    Text('Add cover')
                  ])),
              const PopupMenuItem(
                  value: 'trash',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 14),
                    SizedBox(width: 8),
                    Text('Move to Trash')
                  ])),
              const PopupMenuItem(
                  value: 'export',
                  child: Row(children: [
                    Icon(Icons.download_outlined, size: 14),
                    SizedBox(width: 8),
                    Text('Export')
                  ])),
            ],
            onSelected: (v) {
              if (v == 'subpage') {
                provider.createPage(parentId: page.id);
              } else if (v == 'trash') {
                provider.moveToTrash(page.id);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  List<NotionPage> _getBreadcrumbs(
      WorkspaceProvider provider, NotionPage page) {
    final crumbs = <NotionPage>[];
    NotionPage? current = page;
    while (current != null) {
      crumbs.insert(0, current);
      final parentId = current.parentId;
      current = parentId != null ? provider.pages[parentId] : null;
    }
    return crumbs;
  }

  Widget _buildPageIcon(
      BuildContext context, WorkspaceProvider provider, NotionPage page) {
    return GestureDetector(
      onTap: () => _showIconPicker(context, provider, page),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(page.icon, style: const TextStyle(fontSize: 56)),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, WorkspaceProvider provider,
      NotionPage page, bool isDark) {
    return TextField(
      controller: _titleController,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF37352F),
        fontSize: 38,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      decoration: InputDecoration.collapsed(
        hintText: 'Untitled',
        hintStyle: TextStyle(
          color: AppTheme.notionGray.withValues(alpha: 0.5),
          fontSize: 38,
          fontWeight: FontWeight.w700,
        ),
      ),
      maxLines: null,
      textInputAction: TextInputAction.next,
      onChanged: (value) {
        provider.updatePageTitle(page.id, value);
      },
      onSubmitted: (_) {
        // Focus first block
        if (page.blocks.isEmpty) {
          provider.addBlock(page.id, Block(type: BlockType.text));
        }
      },
    );
  }

  List<Widget> _buildBlocks(BuildContext context, WorkspaceProvider provider,
      NotionPage page, bool isDark) {
    if (page.blocks.isEmpty) {
      return [
        GestureDetector(
          onTap: () => provider.addBlock(page.id, Block(type: BlockType.text)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              "Press Enter to continue with an empty page, or pick a template",
              style: TextStyle(
                color: AppTheme.notionGray.withValues(alpha: 0.6),
                fontSize: 15,
              ),
            ),
          ),
        ),
      ];
    }

    return page.blocks.asMap().entries.map((entry) {
      final i = entry.key;
      final block = entry.value;
      return ReorderableDragStartListener(
        key: ValueKey(block.id),
        index: i,
        child: BlockWidget(
          block: block,
          index: i,
          isDark: isDark,
          onUpdate: (updated) => provider.updateBlock(page.id, updated),
          onDelete: () {
            if (page.blocks.length > 1) {
              provider.deleteBlock(page.id, block.id);
            }
          },
          onAddAfter: (newBlock, atIndex) {
            provider.addBlock(page.id, newBlock, atIndex: atIndex);
          },
        ),
      );
    }).toList();
  }

  void _showIconPicker(
      BuildContext context, WorkspaceProvider provider, NotionPage page) {
    final emojis = [
      '📄',
      '📝',
      '📋',
      '📌',
      '📍',
      '🗒',
      '🗓',
      '📅',
      '📆',
      '📊',
      '📈',
      '📉',
      '🗂',
      '📁',
      '📂',
      '🗃',
      '🗄',
      '📦',
      '🏠',
      '🏡',
      '🌟',
      '⭐',
      '✨',
      '💫',
      '🎯',
      '🎨',
      '🎭',
      '🎬',
      '🎮',
      '🎲',
      '💡',
      '🔍',
      '🔎',
      '💼',
      '👋',
      '✅',
      '❌',
      '⚡',
      '🔥',
      '💧',
      '🌱',
      '🌲',
      '🌍',
      '🚀',
      '💻',
      '📱',
      '🎵',
      '🎶',
      '🍎',
      '🍕',
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Icon'),
        content: SizedBox(
          width: 300,
          height: 250,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: emojis.length,
            itemBuilder: (ctx, i) => GestureDetector(
              onTap: () {
                provider.updatePageIcon(page.id, emojis[i]);
                Navigator.pop(ctx);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: page.icon == emojis[i]
                      ? Colors.blue.withValues(alpha: 0.2)
                      : Colors.transparent,
                ),
                child: Center(
                  child: Text(emojis[i], style: const TextStyle(fontSize: 20)),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))
        ],
      ),
    );
  }
}
