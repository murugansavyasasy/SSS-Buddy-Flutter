import 'package:flutter/material.dart';
import '../Values/Colors/app_colors.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final String label;
  final String? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final String Function(T) itemValue;
  final ValueChanged<String?> onChanged;
  final String? hint;

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.itemValue,
    required this.onChanged,
    this.hint,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  List<T> _filtered = [];
  String? _displayValue;

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _syncDisplay();
  }

  @override
  void didUpdateWidget(covariant SearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items || oldWidget.value != widget.value) {
      _filtered = widget.items;
      _syncDisplay();
    }
  }

  void _syncDisplay() {
    if (widget.value == null) {
      _displayValue = null;
      return;
    }
    try {
      final match = widget.items.firstWhere(
            (e) => widget.itemValue(e) == widget.value,
      );
      _displayValue = widget.itemLabel(match);
    } catch (_) {
      _displayValue = widget.value;
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _searchController.clear();
    _filtered = widget.items;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: _DropdownOverlay<T>(
            items: _filtered,
            itemLabel: widget.itemLabel,
            itemValue: widget.itemValue,
            searchController: _searchController,
            allItems: widget.items,
            onFilterChanged: (filtered) {
              _filtered = filtered;
              _overlayEntry?.markNeedsBuild();
            },
            onSelect: (val) {
              widget.onChanged(val);
              _removeOverlay();
              setState(() => _syncDisplay());
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isOpen ? AppColors.primary : Colors.grey.shade300,
              width: _isOpen ? 1.5 : 1.0,
            ),
            boxShadow: _isOpen
                ? [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ]
                : [],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: _isOpen
                            ? AppColors.primary
                            : Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _displayValue ?? widget.hint ?? "Select an option",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _displayValue != null
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _displayValue != null
                            ? const Color(0xFF111827)
                            : Colors.grey.shade400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AnimatedRotation(
                turns: _isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _isOpen ? AppColors.primary : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Overlay Panel ─────────────────────────────────────────────────────────────
class _DropdownOverlay<T> extends StatefulWidget {
  final List<T> items;
  final List<T> allItems;
  final String Function(T) itemLabel;
  final String Function(T) itemValue;
  final TextEditingController searchController;
  final ValueChanged<List<T>> onFilterChanged;
  final ValueChanged<String> onSelect;

  const _DropdownOverlay({
    required this.items,
    required this.allItems,
    required this.itemLabel,
    required this.itemValue,
    required this.searchController,
    required this.onFilterChanged,
    required this.onSelect,
  });

  @override
  State<_DropdownOverlay<T>> createState() => _DropdownOverlayState<T>();
}

class _DropdownOverlayState<T> extends State<_DropdownOverlay<T>> {
  late List<T> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.allItems;
    widget.searchController.addListener(_onSearch);
  }

  void _onSearch() {
    final q = widget.searchController.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.allItems
          : widget.allItems
          .where((e) => widget.itemLabel(e).toLowerCase().contains(q))
          .toList();
    });
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearch);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(14),
      shadowColor: Colors.black.withOpacity(0.12),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 280),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Search Box ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: TextField(
                controller: widget.searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Search...",
                  hintStyle:
                  TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 18, color: Colors.grey.shade400),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 8),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            // ── List ────────────────────────────────
            Flexible(
              child: _filtered.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "No results found",
                  style:
                  TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
              )
                  : ListView.builder(
                // ✅ Only renders visible items — no freeze
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final item = _filtered[index];
                  final label = widget.itemLabel(item);
                  final value = widget.itemValue(item);
                  return InkWell(
                    onTap: () => widget.onSelect(value),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 11),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1F2937),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}