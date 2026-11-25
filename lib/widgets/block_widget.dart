import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../utils/theme.dart';

class BlockWidget extends StatefulWidget {
  final Block block;
  final int index;
  final bool isDark;
  final Function(Block) onUpdate;
  final VoidCallback onDelete;
  final Function(Block, int) onAddAfter;
  final VoidCallback? onFocus;

  const BlockWidget({
    super.key,
    required this.block,
    required this.index,
    required this.isDark,
    required this.onUpdate,
    required this.onDelete,
    required this.onAddAfter,
    this.onFocus,
  });

  @override
  State<BlockWidget> createState() => _BlockWidgetState();
}

class _BlockWidgetState extends State<BlockWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.block.content);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) widget.onFocus?.call();
    });
  }

  @override
  void didUpdateWidget(BlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.content != widget.block.content &&
        _controller.text != widget.block.content) {
      _controller.text = widget.block.content;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Color get _textColor =>
      widget.isDark ? const Color(0xFFCFCFCF) : const Color(0xFF37352F);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle & actions
          SizedBox(
            width: 48,
            child: _isHovered
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _blockAction(Icons.add, () => _showAddMenu(context)),
                      _blockAction(Icons.drag_indicator, null),
                    ],
                  )
                : null,
          ),
          // Block content
          Expanded(child: _buildBlock(context)),
        ],
      ),
    );
  }

  Widget _blockAction(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Icon(icon, size: 16, color: AppTheme.notionGray),
      ),
    );
  }

  Widget _buildBlock(BuildContext context) {
    switch (widget.block.type) {
      case BlockType.heading1:
        return _buildHeading(context, 28, FontWeight.w700);
      case BlockType.heading2:
        return _buildHeading(context, 22, FontWeight.w700);
      case BlockType.heading3:
        return _buildHeading(context, 18, FontWeight.w600);
      case BlockType.bulletList:
        return _buildBullet(context);
      case BlockType.numberedList:
        return _buildNumbered(context);
      case BlockType.todoList:
        return _buildTodo(context);
      case BlockType.toggle:
        return _buildToggle(context);
      case BlockType.quote:
        return _buildQuote(context);
      case BlockType.callout:
        return _buildCallout(context);
      case BlockType.divider:
        return _buildDivider();
      case BlockType.code:
        return _buildCode(context);
      default:
        return _buildText(context);
    }
  }

  Widget _buildText(BuildContext context) {
    return _editableText(
      context,
      style: TextStyle(color: _textColor, fontSize: 15, height: 1.6),
    );
  }

  Widget _buildHeading(BuildContext context, double size, FontWeight weight) {
    return _editableText(
      context,
      style: TextStyle(
        color: _textColor,
        fontSize: size,
        fontWeight: weight,
        height: 1.3,
      ),
    );
  }

  Widget _buildBullet(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, right: 8),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: _textColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: _editableText(
            context,
            style: TextStyle(color: _textColor, fontSize: 15, height: 1.6),
          ),
        ),
      ],
    );
  }

  Widget _buildNumbered(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 8),
          child: Text(
            '${widget.index + 1}.',
            style: TextStyle(color: _textColor, fontSize: 15),
          ),
        ),
        Expanded(
          child: _editableText(
            context,
            style: TextStyle(color: _textColor, fontSize: 15, height: 1.6),
          ),
        ),
      ],
    );
  }

  Widget _buildTodo(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 8),
          child: Checkbox(
            value: widget.block.checked ?? false,
            onChanged: (v) {
              widget.onUpdate(widget.block.copyWith(checked: v));
            },
            activeColor: AppTheme.notionBlue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        Expanded(
          child: _editableText(
            context,
            style: TextStyle(
              color: (widget.block.checked ?? false)
                  ? AppTheme.notionGray
                  : _textColor,
              fontSize: 15,
              height: 1.6,
              decoration: (widget.block.checked ?? false)
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => widget.onUpdate(
                  widget.block.copyWith(isExpanded: !widget.block.isExpanded)),
              child: Icon(
                widget.block.isExpanded
                    ? Icons.expand_more
                    : Icons.chevron_right,
                size: 20,
                color: _textColor,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _editableText(
                context,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
        if (widget.block.isExpanded && widget.block.children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              children: widget.block.children
                  .map((child) => Text(
                        child.content,
                        style: TextStyle(color: _textColor, fontSize: 14),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildQuote(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: widget.isDark ? Colors.white54 : Colors.black54,
            width: 3,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: _editableText(
        context,
        style: TextStyle(
          color: _textColor,
          fontSize: 15,
          height: 1.6,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildCallout(BuildContext context) {
    final bg = widget.block.backgroundColor ??
        (widget.isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF1F1EF));
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.block.icon ?? '💡', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: _editableText(
              context,
              style: TextStyle(color: _textColor, fontSize: 15, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        color:
            widget.isDark ? const Color(0xFF444444) : const Color(0xFFE9E9E7),
        height: 1,
      ),
    );
  }

  Widget _buildCode(BuildContext context) {
    final bg =
        widget.isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F6F3);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color:
              widget.isDark ? const Color(0xFF444444) : const Color(0xFFE9E9E7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Language bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                color: widget.isDark
                    ? const Color(0xFF444444)
                    : const Color(0xFFE9E9E7),
              )),
            ),
            child: Row(
              children: [
                Text(
                  widget.block.language ?? 'plain text',
                  style: const TextStyle(
                    color: AppTheme.notionGray,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Clipboard.setData(
                      ClipboardData(text: widget.block.content)),
                  child: const Icon(Icons.copy,
                      size: 14, color: AppTheme.notionGray),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: widget.isDark
                    ? const Color(0xFFD4D4D4)
                    : const Color(0xFF1E1E1E),
                height: 1.6,
              ),
              maxLines: null,
              decoration: const InputDecoration.collapsed(
                  hintText: 'Write some code...'),
              onChanged: (v) =>
                  widget.onUpdate(widget.block.copyWith(content: v)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editableText(BuildContext context, {required TextStyle style}) {
    if (widget.block.type == BlockType.divider) return const SizedBox();

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.backspace &&
              _controller.text.isEmpty) {
            widget.onDelete();
          } else if (event.logicalKey == LogicalKeyboardKey.enter) {
            // Enter key handled by onSubmitted
          }
        }
      },
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: style,
        maxLines: null,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration.collapsed(
          hintText: _getHintText(),
          hintStyle: style.copyWith(
            color: AppTheme.notionGray.withValues(alpha: 0.6),
          ),
        ),
        onChanged: (value) {
          // Handle slash command
          if (value.endsWith('/')) {
            _showSlashMenu(context);
          }
          widget.onUpdate(widget.block.copyWith(content: value));
        },
        onSubmitted: (_) {
          widget.onAddAfter(
            Block(type: _nextBlockType()),
            widget.index + 1,
          );
        },
      ),
    );
  }

  String _getHintText() {
    switch (widget.block.type) {
      case BlockType.heading1:
        return 'Heading 1';
      case BlockType.heading2:
        return 'Heading 2';
      case BlockType.heading3:
        return 'Heading 3';
      case BlockType.quote:
        return 'Empty quote';
      case BlockType.callout:
        return 'Write something...';
      case BlockType.todoList:
        return 'To-do';
      case BlockType.bulletList:
        return 'List item';
      case BlockType.numberedList:
        return 'List item';
      default:
        return "Type '/' for commands";
    }
  }

  BlockType _nextBlockType() {
    switch (widget.block.type) {
      case BlockType.bulletList:
        return BlockType.bulletList;
      case BlockType.numberedList:
        return BlockType.numberedList;
      case BlockType.todoList:
        return BlockType.todoList;
      default:
        return BlockType.text;
    }
  }

  void _showAddMenu(BuildContext context) {
    _showBlockTypeMenu(context);
  }

  void _showSlashMenu(BuildContext context) {
    _showBlockTypeMenu(context);
  }

  void _showBlockTypeMenu(BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx + 48,
        position.dy,
        position.dx + 300,
        position.dy + 200,
      ),
      items: _blockTypeMenuItems(),
    ).then((value) {
      if (value != null) {
        final type = BlockType.values.firstWhere(
          (e) => e.name == value,
          orElse: () => BlockType.text,
        );
        // If current block is empty, convert it. Otherwise add after.
        if (widget.block.content.isEmpty || widget.block.content == '/') {
          widget.onUpdate(widget.block.copyWith(type: type, content: ''));
        } else {
          widget.onAddAfter(Block(type: type), widget.index + 1);
        }
      }
    });
  }

  List<PopupMenuEntry<String>> _blockTypeMenuItems() {
    final items = [
      _menuSection('BASIC BLOCKS'),
      _menuItem('text', '📝', 'Text', 'Just start writing with plain text'),
      _menuItem('heading1', 'H1', 'Heading 1', 'Big section heading'),
      _menuItem('heading2', 'H2', 'Heading 2', 'Medium section heading'),
      _menuItem('heading3', 'H3', 'Heading 3', 'Small section heading'),
      _menuSection('LISTS'),
      _menuItem(
          'bulletList', '•', 'Bullet List', 'Create a simple bullet list'),
      _menuItem(
          'numberedList', '1.', 'Numbered List', 'Create a numbered list'),
      _menuItem('todoList', '☑', 'To-do List', 'Track tasks with checkboxes'),
      _menuSection('SPECIAL'),
      _menuItem('toggle', '▶', 'Toggle List', 'Toggles can hide content'),
      _menuItem('quote', '"', 'Quote', 'Capture a quote'),
      _menuItem('callout', '💡', 'Callout', 'Make writing stand out'),
      _menuItem('divider', '—', 'Divider', 'Visually divide content'),
      _menuItem('code', '</>', 'Code', 'Capture a code snippet'),
    ];
    return items;
  }

  PopupMenuEntry<String> _menuSection(String title) {
    return PopupMenuItem<String>(
      enabled: false,
      height: 28,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  PopupMenuEntry<String> _menuItem(
      String value, String emoji, String title, String description) {
    return PopupMenuItem<String>(
      value: value,
      height: 48,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              Text(description,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }
}
