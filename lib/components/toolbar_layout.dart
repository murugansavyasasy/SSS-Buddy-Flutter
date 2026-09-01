import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Values/Colors/app_colors.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class ToolbarLayout extends ConsumerStatefulWidget {
  final String title;
  final Widget? navigateTo;
  final ValueChanged<String>? onSearch;
  final String searchHint;
  final ValueChanged<String>? onMonthChanged;
  final String? selectedMonth;
  final VoidCallback? onBackPressed;
  final List<String>? dropdownLists;
  final VoidCallback? onRefresh;
  final Widget? trailing;
  final List<Map<String, String>>? financialYearList;
  final String? selectedFinancialYearId;
  final void Function(String id, String name)? onFinancialYearChanged;

  const ToolbarLayout({
    super.key,
    required this.title,
    this.navigateTo,
    this.onSearch,
    this.searchHint = "Search...",
    this.onMonthChanged,
    this.selectedMonth,
    this.onBackPressed,
    this.dropdownLists,
    this.onRefresh,
    this.trailing,
    this.financialYearList,
    this.selectedFinancialYearId,
    this.onFinancialYearChanged,
  });

  @override
  ConsumerState<ToolbarLayout> createState() => _ToolbarLayoutState();
}

class _ToolbarLayoutState extends ConsumerState<ToolbarLayout>
    with SingleTickerProviderStateMixin {
  bool _searchOpen = false;
  bool _isRefreshing = false;
  final TextEditingController _controller = TextEditingController();

  late final AnimationController _animController;
  late final Animation<double> _fade;

  late final ValueNotifier<String?> _selectedMonthNotifier;

  // NEW: holds the selected FY *name* for display in the dropdown button
  late final ValueNotifier<String?> _selectedFyNameNotifier;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fade = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);

    final lists = widget.dropdownLists ?? [];
    _selectedMonthNotifier = ValueNotifier(
      (widget.selectedMonth != null && lists.contains(widget.selectedMonth))
          ? widget.selectedMonth
          : (lists.isNotEmpty ? lists.first : null),
    );

    _selectedFyNameNotifier = ValueNotifier(_resolveFyName());
  }

  // Finds the display name matching widget.selectedFinancialYearId,
  // falling back to the first item in the list.
  String? _resolveFyName() {
    final fyList = widget.financialYearList ?? [];

    if (fyList.isEmpty) {
      return null;
    }

    if (widget.selectedFinancialYearId != null) {
      final match = fyList.where(
            (item) => item['id'] == widget.selectedFinancialYearId,
      );

      if (match.isNotEmpty) {
        return match.first['name'];
      }
    }

    return fyList.first['name'];
  }

  @override
  void didUpdateWidget(covariant ToolbarLayout oldWidget) {
    super.didUpdateWidget(oldWidget);

    final lists = widget.dropdownLists ?? [];
    final newValue = (widget.selectedMonth != null && lists.contains(widget.selectedMonth))
        ? widget.selectedMonth
        : (lists.isNotEmpty ? lists.first : null);

    if (_selectedMonthNotifier.value != newValue) {
      _selectedMonthNotifier.value = newValue;
    }

    final newFyName = _resolveFyName();

    if (_selectedFyNameNotifier.value != newFyName) {
      _selectedFyNameNotifier.value = newFyName;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
    _selectedMonthNotifier.dispose();
    _selectedFyNameNotifier.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    _animController.forward();
  }

  void _closeSearch() {
    _animController.reverse().then((_) {
      setState(() => _searchOpen = false);
      _controller.clear();
      widget.onSearch?.call('');
    });
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final bool hasSearch = widget.onSearch != null;
    final List<String> dropdownLists = widget.dropdownLists ?? [];
    final List<Map<String, String>> fyList = widget.financialYearList ?? [];
    final bool hasFyDropdown = fyList.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Container(
        color: AppColors.primary,
        padding: EdgeInsets.only(
          top: topPadding + 10,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _searchOpen
                      ? _closeSearch
                      : () {
                    if (widget.onBackPressed != null) {
                      widget.onBackPressed!();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(21),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // NEW: Financial Year dropdown (shows name, returns id)
                if (hasFyDropdown && !_searchOpen) ...[
                  _financialYearDropdown(fyList),
                  const SizedBox(width: 8),
                ],

                if (widget.trailing != null && !_searchOpen) ...[
                  widget.trailing!,
                  const SizedBox(width: 8),
                ],

                if (widget.onRefresh != null && !_searchOpen) ...[
                  GestureDetector(
                    onTap: _isRefreshing
                        ? null
                        : () async {
                      setState(() => _isRefreshing = true);
                      widget.onRefresh?.call();
                      await Future.delayed(const Duration(milliseconds: 1000));
                      if (mounted) setState(() => _isRefreshing = false);
                    },
                    child: Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Center(
                        child: _isRefreshing
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                            : const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                if (hasSearch && !_searchOpen)
                  GestureDetector(
                    onTap: _openSearch,
                    child: Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),

            if (hasSearch && _searchOpen)
              FadeTransition(
                opacity: _fade,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: widget.onSearch,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.searchHint,
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        suffixIcon: _controller.text.isNotEmpty
                            ? GestureDetector(
                          onTap: () {
                            _controller.clear();
                            widget.onSearch?.call('');
                            setState(() {});
                          },
                          child: Icon(
                            Icons.close,
                            color: Colors.grey.shade400,
                            size: 18,
                          ),
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            if (widget.onMonthChanged != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton2<String>(
                      isExpanded: true,
                      valueListenable: _selectedMonthNotifier,
                      dropdownStyleData: DropdownStyleData(
                        maxHeight: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        offset: const Offset(0, 8),
                      ),
                      buttonStyleData: const ButtonStyleData(height: 44),
                      iconStyleData: const IconStyleData(
                        icon: Icon(Icons.keyboard_arrow_down),
                      ),
                      items: dropdownLists.map((month) {
                        return DropdownItem<String>(
                          value: month,
                          child: Text(
                            month,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          _selectedMonthNotifier.value = val;
                          widget.onMonthChanged?.call(val);
                        }
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // MARK: - Financial Year Dropdown (compact, sits next to the title)

  Widget _financialYearDropdown(List<Map<String, String>> fyList) {
    return Container(
      height: 36,
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white30),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          isExpanded: true,
          valueListenable: _selectedFyNameNotifier,
          customButton: ValueListenableBuilder<String?>(
            valueListenable: _selectedFyNameNotifier,
            builder: (context, value, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      value ?? "FY",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              );
            },
          ),
          dropdownStyleData: DropdownStyleData(
            width: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            offset: const Offset(-20, 8),
          ),
          items: fyList.map((year) {
            return DropdownItem<String>(
              value: year['id'],
              child: Text(
                year['name'] ?? '',
                style: const TextStyle(fontSize: 13),
              ),
            );
          }).toList(),
          onChanged: (selectedId) {
            if (selectedId == null) return;

            final matched = fyList.firstWhere(
                  (item) => item['id'] == selectedId,
              orElse: () => {},
            );

            final name = matched['name'] ?? '';
            _selectedFyNameNotifier.value = name;
            widget.onFinancialYearChanged?.call(selectedId, name);
          },
        ),
      ),
    );
  }
}