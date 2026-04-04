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
  const ToolbarLayout({
    super.key,
    required this.title,
    this.navigateTo,
    this.onSearch,
    this.searchHint = "Search...",
    this.onMonthChanged,
    this.selectedMonth,
    this.onBackPressed,
  });

  @override
  ConsumerState<ToolbarLayout> createState() => _ToolbarLayoutState();
}

class _ToolbarLayoutState extends ConsumerState<ToolbarLayout>
    with SingleTickerProviderStateMixin {
  final List<String> _months = const [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];
  bool _searchOpen = false;
  final TextEditingController _controller = TextEditingController();

  late final AnimationController _animController;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fade = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    _animController.dispose();
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
                    child: Center(
                      child: Icon(
                        _searchOpen ? Icons.arrow_back : Icons.arrow_back,
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
                  ),
                ),

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
                      value: widget.selectedMonth ?? _months.first,
                      isExpanded: true,
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
                      items: _months.map((month) {
                        return DropdownMenuItem(
                          value: month,
                          child: Text(
                            month,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
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
}
