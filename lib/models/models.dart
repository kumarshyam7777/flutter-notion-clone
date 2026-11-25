import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ─── Block Types ──────────────────────────────────────────────────────────────
enum BlockType {
  text,
  heading1,
  heading2,
  heading3,
  bulletList,
  numberedList,
  todoList,
  toggle,
  quote,
  callout,
  divider,
  code,
  image,
  table,
  database,
}

// ─── Block Model ──────────────────────────────────────────────────────────────
class Block {
  String id;
  BlockType type;
  String content;
  bool? checked; // for todo
  bool isExpanded; // for toggle
  List<Block> children;
  Map<String, dynamic> properties;
  String? language; // for code blocks
  Color? backgroundColor;
  Color? textColor;
  String? icon; // for callout

  Block({
    String? id,
    this.type = BlockType.text,
    this.content = '',
    this.checked,
    this.isExpanded = true,
    List<Block>? children,
    Map<String, dynamic>? properties,
    this.language,
    this.backgroundColor,
    this.textColor,
    this.icon,
  })  : id = id ?? _uuid.v4(),
        children = children ?? [],
        properties = properties ?? {};

  Block copyWith({
    String? id,
    BlockType? type,
    String? content,
    bool? checked,
    bool? isExpanded,
    List<Block>? children,
    Map<String, dynamic>? properties,
    String? language,
    Color? backgroundColor,
    Color? textColor,
    String? icon,
  }) {
    return Block(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      checked: checked ?? this.checked,
      isExpanded: isExpanded ?? this.isExpanded,
      children: children ?? List.from(this.children),
      properties: properties ?? Map.from(this.properties),
      language: language ?? this.language,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      icon: icon ?? this.icon,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'content': content,
        'checked': checked,
        'isExpanded': isExpanded,
        'children': children.map((b) => b.toJson()).toList(),
        'properties': properties,
        'language': language,
        'backgroundColor': backgroundColor?.toARGB32(),
        'textColor': textColor?.toARGB32(),
        'icon': icon,
      };

  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      id: json['id'],
      type: BlockType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BlockType.text,
      ),
      content: json['content'] ?? '',
      checked: json['checked'],
      isExpanded: json['isExpanded'] ?? true,
      children: (json['children'] as List<dynamic>? ?? [])
          .map((b) => Block.fromJson(b))
          .toList(),
      properties: json['properties'] ?? {},
      language: json['language'],
      backgroundColor: json['backgroundColor'] != null
          ? Color(json['backgroundColor'])
          : null,
      textColor: json['textColor'] != null ? Color(json['textColor']) : null,
      icon: json['icon'],
    );
  }
}

// ─── Page Model ───────────────────────────────────────────────────────────────
class NotionPage {
  String id;
  String title;
  String icon;
  String? coverImage;
  List<Block> blocks;
  DateTime createdAt;
  DateTime updatedAt;
  String? parentId;
  List<String> childIds;
  bool isFavorite;
  bool isInTrash;
  Color? iconColor;

  NotionPage({
    String? id,
    this.title = 'Untitled',
    this.icon = '📄',
    this.coverImage,
    List<Block>? blocks,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.parentId,
    List<String>? childIds,
    this.isFavorite = false,
    this.isInTrash = false,
    this.iconColor,
  })  : id = id ?? _uuid.v4(),
        blocks = blocks ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        childIds = childIds ?? [];

  NotionPage copyWith({
    String? id,
    String? title,
    String? icon,
    String? coverImage,
    List<Block>? blocks,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? parentId,
    List<String>? childIds,
    bool? isFavorite,
    bool? isInTrash,
    Color? iconColor,
  }) {
    return NotionPage(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      coverImage: coverImage ?? this.coverImage,
      blocks: blocks ?? List.from(this.blocks),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentId: parentId ?? this.parentId,
      childIds: childIds ?? List.from(this.childIds),
      isFavorite: isFavorite ?? this.isFavorite,
      isInTrash: isInTrash ?? this.isInTrash,
      iconColor: iconColor ?? this.iconColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'icon': icon,
        'coverImage': coverImage,
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'parentId': parentId,
        'childIds': childIds,
        'isFavorite': isFavorite,
        'isInTrash': isInTrash,
        'iconColor': iconColor?.toARGB32(),
      };

  factory NotionPage.fromJson(Map<String, dynamic> json) {
    return NotionPage(
      id: json['id'],
      title: json['title'] ?? 'Untitled',
      icon: json['icon'] ?? '📄',
      coverImage: json['coverImage'],
      blocks: (json['blocks'] as List<dynamic>? ?? [])
          .map((b) => Block.fromJson(b))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      parentId: json['parentId'],
      childIds: List<String>.from(json['childIds'] ?? []),
      isFavorite: json['isFavorite'] ?? false,
      isInTrash: json['isInTrash'] ?? false,
      iconColor: json['iconColor'] != null ? Color(json['iconColor']) : null,
    );
  }
}

// ─── Workspace Model ──────────────────────────────────────────────────────────
class Workspace {
  String id;
  String name;
  String icon;
  List<String> pageIds;

  Workspace({
    String? id,
    this.name = 'My Workspace',
    this.icon = '🏠',
    List<String>? pageIds,
  })  : id = id ?? _uuid.v4(),
        pageIds = pageIds ?? [];
}
