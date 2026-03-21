import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/components/toolbar_layout.dart';
import 'package:sssbuddy/view/school_listview.dart';
import '../Values/Colors/app_colors.dart';

class UsageCountScreen extends ConsumerStatefulWidget {
  const UsageCountScreen({super.key});

  @override
  ConsumerState<UsageCountScreen> createState() => _UsageCountScreenState();
}

class _UsageCountScreenState extends ConsumerState<UsageCountScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = false;
  bool _hasData = false;

  final Map<String, dynamic> _usageData = {
    'schoolName': 'Govt Higher Sec School, Pudurpalayam',
    'voiceUsage': {
      'label': 'Voice Usage',
      'values': [
        {'title': 'Voice Allocated', 'value': '120'},
        {'title': 'Voice Usage', 'value': '85'},
      ],
    },
    'smsUsage': {
      'label': 'SMS Usage',
      'values': [
        {'title': 'SMS Allocated', 'value': '340'},
        {'title': 'SMS Usage', 'value': '210'},
      ],
    },
    'totalAppUsage': {
      'label': 'Total App Usage',
      'values': [
        {'title': 'App Usage Count', 'value': '58'},
      ],
    },
  };

  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (_fromDate ?? DateTime.now())
          : (_toDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_toDate != null && _toDate!.isBefore(picked)) {
            _toDate = null;
          }
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _getUsage() async {
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both From Date and To Date.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Replace with actual API call using _fromDate and _toDate
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    setState(() {
      _isLoading = false;
      _hasData = true;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select Date';
    return '${date.day.toString().padLeft(2, '0')} / '
        '${date.month.toString().padLeft(2, '0')} / '
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            const ToolbarLayout(
              title: "Usage Count",
              navigateTo: SchoolListview(),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _DateButton(
                              label: 'From Date',
                              value: _formatDate(_fromDate),
                              onTap: () => _pickDate(context, true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DateButton(
                              label: 'To Date',
                              value: _formatDate(_toDate),
                              onTap: () => _pickDate(context, false),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _getUsage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : const Text(
                            'Get Usage',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      if (_hasData) _buildUsageCard(),
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

  Widget _buildUsageCard() {
    final teal = const Color(0xFF1A3A5C);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: teal, width: 1.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            title: _usageData['schoolName'] as String,
            borderColor: teal,
          ),

          _UsageSection(
            sectionTitle: 'Voice Usage',
            values: (_usageData['voiceUsage']['values'] as List)
                .cast<Map<String, String>>(),
            borderColor: teal,
          ),

          _UsageSection(
            sectionTitle: 'SMS Usage',
            values: (_usageData['smsUsage']['values'] as List)
                .cast<Map<String, String>>(),
            borderColor: teal,
          ),

          _UsageSection(
            sectionTitle: 'Total App Usage',
            values: (_usageData['totalAppUsage']['values'] as List)
                .cast<Map<String, String>>(),
            borderColor: teal,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 1.4),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String title;
  final Color borderColor;

  const _CardHeader({required this.title, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: borderColor.withOpacity(0.08),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(7),
          topRight: Radius.circular(7),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _UsageSection extends StatelessWidget {
  final String sectionTitle;
  final List<Map<String, String>> values;
  final Color borderColor;
  final bool isLast;

  const _UsageSection({
    required this.sectionTitle,
    required this.values,
    required this.borderColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: borderColor, width: 1.0),
          bottom: isLast ? BorderSide.none : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: Colors.grey.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              sectionTitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),


          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: values.length == 1

                ? _ValueChip(
              title: values[0]['title']!,
              value: values[0]['value']!,
              fullWidth: true,
            )

                : Row(
              children: [
                Expanded(
                  child: _ValueChip(
                    title: values[0]['title']!,
                    value: values[0]['value']!,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ValueChip(
                    title: values[1]['title']!,
                    value: values[1]['value']!,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  final String title;
  final String value;
  final bool fullWidth;

  const _ValueChip({
    required this.title,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = const Color(0xFF1A3A5C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: borderColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: fullWidth
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}