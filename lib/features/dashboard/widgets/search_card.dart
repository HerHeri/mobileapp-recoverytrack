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
    this.textSize = 18,
  });

  @override
  State<SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<SearchCard> {
  static const double _barHeight = 60.0;
  static const double _barRadius = 32.0;

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Container(
        height: _barHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_barRadius),
          border: Border.all(color: const Color(0xFF333333), width: 2.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Search icon - large, prominent
            const Padding(
              padding: EdgeInsets.only(left: 18, right: 12),
              child: Icon(Icons.search, size: 28, color: Color(0xFF444444)),
            ),
            // Text input
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                readOnly: widget.readOnly,
                showCursor: true,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: (value) {
                  widget.onSearch(value, widget.filter);
                },
                decoration: const InputDecoration(
                  hintText: "Pencarian",
                  hintStyle: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            // Clear button
            if (hasText)
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  widget.controller.clear();
                  widget.onSearch('', widget.filter);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 20,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            // Vertical divider
            Container(
              width: 1.5,
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: const Color(0xFFCCCCCC),
            ),
            // Dropdown filter
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: PopupMenuButton<String>(
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                color: Colors.white,
                elevation: 8,
                onSelected: (v) {
                  widget.onFilterChanged(v);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: "no_polisi",
                    child: _dropdownItem("No Plat", "no_polisi"),
                  ),
                  PopupMenuItem(
                    value: "no_mesin",
                    child: _dropdownItem("No Mesin", "no_mesin"),
                  ),
                  PopupMenuItem(
                    value: "no_rangka",
                    child: _dropdownItem("No Rangka", "no_rangka"),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _filterLabel(widget.filter),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 22,
                        color: Color(0xFF555555),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _filterLabel(String filter) {
    switch (filter) {
      case "no_polisi":
        return "No Plat";
      case "no_mesin":
        return "No Mesin";
      case "no_rangka":
        return "No Rangka";
      default:
        return "No Plat";
    }
  }

  Widget _dropdownItem(String label, String value) {
    final isSelected = widget.filter == value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.purple.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          color: isSelected ? Colors.purple : const Color(0xFF333333),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
