import 'package:flutter/material.dart';

import '../Values/Colors/app_colors.dart';
import '../components/toolbar_layout.dart';
import 'local_conveyence.dart';

class ExpenseEntry {
  final String label;
  final TextEditingController controller;

  ExpenseEntry({required this.label})
      : controller = TextEditingController();

  double get value => double.tryParse(controller.text) ?? 0.0;

  void dispose() => controller.dispose();
}

class AddLocalConveyence extends StatefulWidget {
  const AddLocalConveyence({super.key});

  @override
  State<AddLocalConveyence> createState() => _AddLocalConveyenceState();
}

class _AddLocalConveyenceState extends State<AddLocalConveyence> {
  static const List<String> _fieldLabels = [
    'Boarding & Lodging',
    'Local Conveyance',
    'Food & Beverages',
    'Petrol',
    'Postage & Courier',
    'Printing & Stationery',
    'Telephone & Data Charges',
    'Miscellaneous Expenses',
  ];

  late final List<ExpenseEntry> _withBillEntries;
  late final List<ExpenseEntry> _withoutBillEntries;
  final TextEditingController _withBillRemarks = TextEditingController();
  final TextEditingController _withoutBillRemarks = TextEditingController();

  double _withBillTotal = 0;
  double _withoutBillTotal = 0;
  final List<String> months = const [
    "January","February","March","April","May","June",
    "July","August","September","October","November","December"
  ];

  late String selectedMonth = months[DateTime.now().month - 1];
  @override
  void initState() {
    super.initState();
    _withBillEntries =
        _fieldLabels.map((l) => ExpenseEntry(label: l)).toList();
    _withoutBillEntries =
        _fieldLabels.map((l) => ExpenseEntry(label: l)).toList();

    for (final e in _withBillEntries) {
      e.controller.addListener(_recalculate);
    }
    for (final e in _withoutBillEntries) {
      e.controller.addListener(_recalculate);
    }
  }

  @override
  void dispose() {
    for (final e in _withBillEntries) {
      e.dispose();
    }
    for (final e in _withoutBillEntries) {
      e.dispose();
    }
    _withBillRemarks.dispose();
    _withoutBillRemarks.dispose();
    super.dispose();
  }

  void _recalculate() {
    setState(() {
      _withBillTotal =
          _withBillEntries.fold(0, (sum, e) => sum + e.value);
      _withoutBillTotal =
          _withoutBillEntries.fold(0, (sum, e) => sum + e.value);
    });
  }

  double get _overallTotal => _withBillTotal + _withoutBillTotal;

  void _submit() {
    // TODO: wire up to your ViewModel / API call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Claim submitted — ₹ ${_overallTotal.toStringAsFixed(2)}',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          ToolbarLayout(
            title: "Add Local Expenses",
            navigateTo: const LocalConveyence(),
            // ✅ ADD THIS
            dropdownLists: months,
            selectedMonth: selectedMonth,
            onMonthChanged: (value) {
              setState(() {
                selectedMonth = value;
              });
            },
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F6FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ExpenseSectionCard(
                    title: 'With Bill',
                    badge: 'Receipts required',
                    badgeColor: Colors.green,
                    entries: _withBillEntries,
                    remarksController: _withBillRemarks,
                    sectionTotal: _withBillTotal,
                    onChanged: _recalculate,
                  ),

                  const SizedBox(height: 16),
                  _ExpenseSectionCard(
                    title: 'Without Bill',
                    badge: 'Estimate only',
                    badgeColor: Colors.orange,
                    entries: _withoutBillEntries,
                    remarksController: _withoutBillRemarks,
                    sectionTotal: _withoutBillTotal,
                    onChanged: _recalculate,
                  ),

                  const SizedBox(height: 16),
                  _OverallTotalCard(total: _overallTotal),

                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(30, 12, 30, 24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryprimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Submit"),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _ExpenseSectionCard extends StatelessWidget {
  final String title;
  final String badge;
  final Color badgeColor;
  final List<ExpenseEntry> entries;
  final TextEditingController remarksController;
  final double sectionTotal;
  final VoidCallback onChanged;

  const _ExpenseSectionCard({
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.entries,
    required this.remarksController,
    required this.sectionTotal,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: HSLColor.fromColor(badgeColor)
                          .withLightness(0.3)
                          .toColor(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),

            // Expense rows
            ...entries.map(
                  (entry) => _ExpenseFieldRow(entry: entry),
            ),

            const SizedBox(height: 12),

            // Remarks
            TextField(
              controller: remarksController,
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Remarks',
                labelStyle:
                TextStyle(fontSize: 13, color: Colors.grey.shade600),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Section total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Section Total',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '₹ ${sectionTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
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
class _ExpenseFieldRow extends StatelessWidget {
  final ExpenseEntry entry;

  const _ExpenseFieldRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entry.label,
              style:
              TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          SizedBox(
            width: 110,
            height: 36,
            child: TextField(
              controller: entry.controller,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle:
                TextStyle(fontSize: 13, color: Colors.grey.shade500),
                hintText: '0.00',
                hintStyle:
                TextStyle(fontSize: 13, color: Colors.grey.shade400),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverallTotalCard extends StatelessWidget {
  final double total;

  const _OverallTotalCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Overall Total',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '₹ ${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}