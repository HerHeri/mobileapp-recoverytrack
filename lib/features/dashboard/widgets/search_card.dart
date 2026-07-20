import 'package:flutter/material.dart';

class SearchCard extends StatefulWidget {
  final Function(String query, String filter) onSearch;
  final TextEditingController controller;
  final String filter;
  final ValueChanged<String> onFilterChanged;
  final bool readOnly;
  final FocusNode? focusNode;
  final double textSize;

  const SearchCard({
    super.key,
    required this.onSearch,
    required this.controller,
    required this.filter,
    required this.onFilterChanged,
    this.readOnly = false,
    this.focusNode,
    this.textSize = 24,
  });

  @override
  State<SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<SearchCard> {
  static const double _barHeight = 50;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasText = widget.controller.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(9, 2, 9, 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;

          return Container(
            height: _barHeight,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.16)
                    : const Color(0xFF6D5DFB),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: compact ? 3 : 5,
                    right: compact ? 7 : 12,
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    size: compact ? 30 : 34,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    readOnly: widget.readOnly,
                    showCursor: true,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(
                      fontSize: compact ? 28 : 34,
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    onChanged: (value) {
                      setState(() {});
                      widget.onSearch(value, widget.filter);
                    },
                    decoration: InputDecoration(
                      hintText: "Pencarian",
                      hintStyle: TextStyle(
                        fontSize: compact ? 28 : 34,
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 5),
                    ),
                  ),
                ),
                if (hasText)
                  IconButton(
                    tooltip: 'Hapus pencarian',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      widget.controller.clear();
                      setState(() {});
                      widget.onSearch('', widget.filter);
                    },
                    icon: Icon(
                      Icons.cancel_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                Container(
                  width: 1,
                  height: 20,
                  margin: EdgeInsets.symmetric(horizontal: compact ? 2 : 5),
                  color: theme.dividerColor,
                ),
                Padding(
                  padding: EdgeInsets.only(right: compact ? 5 : 9),
                  child: PopupMenuButton<String>(
                    tooltip: 'Jenis pencarian',
                    offset: const Offset(0, 48),
                    constraints: const BoxConstraints(minWidth: 180),
                    color: theme.colorScheme.surface,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    onSelected: widget.onFilterChanged,
                    itemBuilder: (context) => [
                      _menuItem("No Plat", "no_polisi"),
                      _menuItem("No Mesin", "no_mesin"),
                      _menuItem("No Rangka", "no_rangka"),
                    ],
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 7 : 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.62,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _filterLabel(widget.filter),
                            style: TextStyle(
                              fontSize: compact ? 20 : 24,
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.expand_more_rounded,
                            size: compact ? 18 : 21,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String label, String value) {
    final theme = Theme.of(context);
    final isSelected = widget.filter == value;

    return PopupMenuItem<String>(
      value: value,
      height: 52,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_rounded,
                size: 19,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  String _filterLabel(String filter) {
    switch (filter) {
      case "no_mesin":
        return "No Mesin";
      case "no_rangka":
        return "No Rangka";
      default:
        return "No Plat";
    }
  }
}
