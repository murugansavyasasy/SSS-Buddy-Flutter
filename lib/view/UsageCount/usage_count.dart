import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/components/toolbar_layout.dart';
import 'package:sssbuddy/view/UsageCount/usage_section.dart';
import 'package:sssbuddy/view/school_listview.dart';
import '../../Values/Colors/app_colors.dart';
import '../../auth/model/UsageCount.dart';
import '../../viewModel/usagecount_view_model.dart';
import 'card_header.dart';
import 'date_button.dart';

class UsageCountScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  const UsageCountScreen({super.key, required this.item});

  @override
  ConsumerState<UsageCountScreen> createState() => _UsageCountScreenState();
}

class _UsageCountScreenState extends ConsumerState<UsageCountScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = false;
  Usagecount? _usage;


  Future<void> _pickDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (_fromDate ?? DateTime.now())
          : (_toDate ?? DateTime.now()),
      firstDate: DateTime(1990),
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

  String _formatApiDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
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

    final vm = ref.read(usagecountViewModelProvider.notifier);

    final success = await vm.usagecount(
      widget.item['SchoolID'].toString(),
      _formatApiDate(_fromDate!),
      _formatApiDate(_toDate!),
    );
    if (success) {
      final data = ref.read(usagecountViewModelProvider).value;

      setState(() {
        _usage = data;
      });
    }
    setState(() => _isLoading = false);
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
                isSearch : false
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
                            child: DateButton(
                              label: 'From Date',
                              value: _formatDate(_fromDate),
                              onTap: () => _pickDate(context, true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DateButton(
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

                      if (_usage != null) _buildUsageCard(),
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
          CardHeader(
            title: "${widget.item['SchoolID'] ?? "-"}  ${widget.item['SchoolName'] ?? "-"}",
            borderColor: teal,
          ),

          UsageSection(
            sectionTitle: 'Voice Usage',
            values: [
              {'title': 'Used', 'value': _usage!.VoiceUsage.toString()},
              {'title': 'Allocated', 'value': _usage!.VoiceAllocated.toString()},
            ],
            borderColor: teal,
          ),

          UsageSection(
            sectionTitle: 'SMS Usage',
            values: [
              {'title': 'Used', 'value': _usage!.SMSUsage.toString()},
              {'title': 'Allocated', 'value': _usage!.SMSAllocated.toString()},
            ],
            borderColor: teal,
          ),

          UsageSection(
            sectionTitle: 'Total App Usage',
            values: [
              {'title': 'Count', 'value': _usage!.AppUsageCount.toString()},
            ],
            borderColor: teal,
            isLast: true,
          ),
        ],
      ),
    );
  }
}