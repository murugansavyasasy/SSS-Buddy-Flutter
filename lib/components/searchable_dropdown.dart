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
  final ValueChanged<String>? onSearch;
  final bool isLoading;
  final bool showSearchButtonOnEmpty;
  final VoidCallback? onOpen;

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.itemValue,
    required this.onChanged,
    this.hint,
    this.onSearch,
    this.isLoading = false,
    this.showSearchButtonOnEmpty = false,
    this.onOpen,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();

  final LayerLink _layerLink = LayerLink();

  /// Keeps overlay list updated even when API result arrives.
  final ValueNotifier<List<T>> _itemsNotifier = ValueNotifier<List<T>>([]);

  /// Keeps loading state updated inside overlay.
  final ValueNotifier<bool> _loadingNotifier = ValueNotifier<bool>(false);

  OverlayEntry? _overlayEntry;

  bool _isOpen = false;

  String? _displayValue;

  @override
  void initState() {
    super.initState();
    _itemsNotifier.value = widget.items;
    _loadingNotifier.value = widget.isLoading;
    _syncDisplay();
  }

  @override
  void didUpdateWidget(covariant SearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      _syncDisplay();
    }

    final itemsChanged = !identical(oldWidget.items, widget.items);
    final loadingChanged = oldWidget.isLoading != widget.isLoading;

    if (!itemsChanged && !loadingChanged) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (itemsChanged) {
        _itemsNotifier.value = widget.items;
      }

      if (loadingChanged) {
        _loadingNotifier.value = widget.isLoading;
      }

      _overlayEntry?.markNeedsBuild();
    });
  }

  // ============================================================
  // SELECTED VALUE
  // ============================================================

  void _syncDisplay() {
    if (widget.value == null) {
      _displayValue = null;
      return;
    }

    try {
      final match = widget.items.firstWhere(
            (item) => widget.itemValue(item) == widget.value,
      );
      _displayValue = widget.itemLabel(match);
    } catch (_) {
      _displayValue = widget.value;
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _removeOverlay(fromDispose: true);
    _searchController.dispose();
    _itemsNotifier.dispose();
    _loadingNotifier.dispose();
    super.dispose();
  }

  // ============================================================
  // TOGGLE DROPDOWN
  // ============================================================

  void _toggleDropdown() {
    if (!mounted) return;

    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  // ============================================================
  // SHOW OVERLAY
  // ============================================================

  void _showOverlay() {
    if (!mounted) return;

    // Defensive: never stack a second OverlayEntry on an existing one.
    if (_overlayEntry != null) {
      _removeOverlay();
    }

    final renderObject = context.findRenderObject();

    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return;
    }

    final size = renderObject.size;

    _searchController.clear();
    _itemsNotifier.value = widget.items;
    _loadingNotifier.value = false;
    widget.onOpen?.call();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 4),
            child: _DropdownOverlay<T>(
              itemsListenable: _itemsNotifier,
              loadingListenable: _loadingNotifier,
              itemLabel: widget.itemLabel,
              itemValue: widget.itemValue,
              searchController: _searchController,
              onSearch: widget.onSearch,
              showSearchButton: widget.showSearchButtonOnEmpty,
              onSelect: (value) {
                widget.onChanged(value);
                _removeOverlay();
                if (mounted) {
                  setState(() {
                    _syncDisplay();
                  });
                }
              },
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);

    setState(() {
      _isOpen = true;
    });
  }

  // ============================================================
  // REMOVE OVERLAY
  // ============================================================

  void _removeOverlay({bool fromDispose = false}) {
    _overlayEntry?.remove();
    _overlayEntry = null;

    if (!fromDispose && mounted) {
      setState(() {
        _isOpen = false;
      });
    } else {
      _isOpen = false;
    }
  }

  // ============================================================
  // MAIN UI
  // ============================================================

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
              ),
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

// ============================================================================
// DROPDOWN OVERLAY
// ============================================================================

class _DropdownOverlay<T> extends StatefulWidget {
  final ValueNotifier<List<T>> itemsListenable;
  final ValueNotifier<bool> loadingListenable;
  final String Function(T) itemLabel;
  final String Function(T) itemValue;
  final TextEditingController searchController;
  final ValueChanged<String>? onSearch;
  final bool showSearchButton;
  final ValueChanged<String> onSelect;

  const _DropdownOverlay({
    required this.itemsListenable,
    required this.loadingListenable,
    required this.itemLabel,
    required this.itemValue,
    required this.searchController,
    required this.onSearch,
    required this.showSearchButton,
    required this.onSelect,
  });

  @override
  State<_DropdownOverlay<T>> createState() => _DropdownOverlayState<T>();
}

// ============================================================================
// DROPDOWN OVERLAY STATE
// ============================================================================

class _DropdownOverlayState<T> extends State<_DropdownOverlay<T>> {
  String _query = '';
  bool _localHasNoResults = false;

  // ============================================================
  // BASE DATASET (fix)
  // ============================================================
  late List<T> _baseItems;

  @override
  void initState() {
    super.initState();
    _baseItems = List<T>.from(widget.itemsListenable.value);
    widget.searchController.addListener(_onSearchChanged);
    widget.itemsListenable.addListener(_onItemsListenableChanged);
  }

  // ============================================================
  // TRACK THE "TRUE" BASE DATASET
  // ============================================================

  void _onItemsListenableChanged() {
    final incoming = widget.itemsListenable.value;

    if (_query.isEmpty) {
      _baseItems = List<T>.from(incoming);
    } else {
      final existingValues = _baseItems.map(widget.itemValue).toSet();
      final newOnes = incoming.where(
            (item) => !existingValues.contains(widget.itemValue(item)),
      );
      if (newOnes.isNotEmpty) {
        _baseItems = [..._baseItems, ...newOnes];
      }
    }
  }

  // ============================================================
  // SEARCH TEXT CHANGED (LOCAL — every keystroke, no API call)
  // ============================================================

  void _onSearchChanged() {
    final query = widget.searchController.text.trim().toLowerCase();

    if (!mounted) return;
    final localResults = query.isEmpty
        ? _baseItems
        : _baseItems.where((item) {
      final label = widget.itemLabel(item).toLowerCase();
      return label.contains(query);
    }).toList();

    setState(() {
      _query = query;
      _localHasNoResults = query.isNotEmpty && localResults.isEmpty;
    });

    widget.itemsListenable.value = localResults;
  }

  // ============================================================
  // SEARCH BUTTON — only place the API/onSearch gets called
  // ============================================================

  void _searchOnline() {
    final query = widget.searchController.text.trim();

    if (query.isEmpty) {
      return;
    }

    if (widget.onSearch == null) {
      return;
    }

    // Show loading.
    widget.loadingListenable.value = true;

    // Call ViewModel/API.
    widget.onSearch!(query);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    widget.itemsListenable.removeListener(_onItemsListenableChanged);
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

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
            // ==================================================
            // SEARCH BAR
            // ==================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: TextField(
                controller: widget.searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: "Search...",
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),

                  // LEFT SEARCH ICON
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                  suffixIcon: widget.showSearchButton
                      ? Padding(
                    padding: const EdgeInsets.only(
                      right: 4,
                      top: 4,
                      bottom: 4,
                    ),
                    child: SizedBox(
                      width: 70,
                      child: ElevatedButton(
                        onPressed: _localHasNoResults
                            ? _searchOnline
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor:
                          Colors.grey.shade300,
                          foregroundColor: Colors.white,
                          disabledForegroundColor:
                          Colors.grey.shade500,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Search",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                      : null,

                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),

            const Divider(height: 1),

            // ==================================================
            // LIST
            // ==================================================
            Flexible(
              child: ValueListenableBuilder<bool>(
                valueListenable: widget.loadingListenable,
                builder: (context, isLoading, _) {
                  return ValueListenableBuilder<List<T>>(
                    valueListenable: widget.itemsListenable,
                    builder: (context, items, __) {
                      // ------------------------------------------------
                      // LOADING
                      // ------------------------------------------------
                      if (isLoading) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        );
                      }

                      // ------------------------------------------------
                      // EMPTY
                      // ------------------------------------------------
                      if (items.isEmpty) {
                        final canSearchOnline =
                            widget.showSearchButton && _localHasNoResults;

                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: canSearchOnline
                              ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          )
                              : const Text(
                            "No results found",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        );
                      }

                      // ------------------------------------------------
                      // LIST
                      // ------------------------------------------------
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final label = widget.itemLabel(item);
                          final value = widget.itemValue(item);

                          return InkWell(
                            onTap: () {
                              widget.onSelect(value);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 11,
                              ),
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
                      );
                    },
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