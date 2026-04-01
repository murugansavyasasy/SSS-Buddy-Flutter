import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Values/Colors/app_colors.dart';
import '../auth/model/AdvanceTourExpenseDetailModel.dart';
import '../auth/model/AdvanceTourExpenseModel.dart';
import '../components/FormSectionHeader.dart';
import '../components/GrandTotalCard.dart';
import '../components/SectionHeader.dart';
import '../components/toolbar_layout.dart';
import '../viewModel/advance_tour_detail_viewmodel.dart';
import 'advance_tour_expense.dart';

class MoveToToursettlement extends ConsumerStatefulWidget {
  final Advancetourexpensemodel item;
  const MoveToToursettlement({super.key, required this.item});

  @override
  ConsumerState<MoveToToursettlement> createState() =>
      _MoveToToursettlementState();
}

class _MoveToToursettlementState extends ConsumerState<MoveToToursettlement> {
  // ── General Info Controllers ───────────────────────────────
  late TextEditingController _tourNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _purposeController;

  // Place controllers (3 places)
  late TextEditingController _place1Controller;
  late TextEditingController _place2Controller;
  late TextEditingController _place3Controller;

  DateTime? _startDate;
  DateTime? _endDate;

  String? _selectedMonth;
  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  // ── With Bill Controllers ──────────────────────────────────
  late TextEditingController _boardLodgeCtrl;
  late TextEditingController _businessPromoCtrl;
  late TextEditingController _convTravelCtrl;
  late TextEditingController _foodCtrl;
  late TextEditingController _fuelCtrl;
  late TextEditingController _postageCourierCtrl;
  late TextEditingController _printingCtrl;
  late TextEditingController _travelCtrl;
  late TextEditingController _miscCtrl;

  // ── Without Bill Controllers ───────────────────────────────
  late TextEditingController _boardLodgeWBCtrl;
  late TextEditingController _businessPromoWBCtrl;
  late TextEditingController _convTravelWBCtrl;
  late TextEditingController _foodWBCtrl;
  late TextEditingController _fuelWBCtrl;
  late TextEditingController _postageCourierWBCtrl;
  late TextEditingController _printingWBCtrl;
  late TextEditingController _travelWBCtrl;
  late TextEditingController _miscWBCtrl;

  final _formKey = GlobalKey<FormState>();
  void _parseDateRange(String raw) {
    final parts = raw.split(' - ');
    if (parts.length == 2) {
      _startDate = _parseDMY(parts[0].trim());
      _endDate   = _parseDMY(parts[1].trim());
    }
  }

  DateTime? _parseDMY(String s) {
    final p = s.split('/');
    if (p.length != 3) return null;
    final day   = int.tryParse(p[0]);
    final month = int.tryParse(p[1]);
    final year  = int.tryParse(p[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  void _parseTourPlaces(String raw) {
    final parts = raw.split(' - ');
    _place1Controller.text = parts.isNotEmpty ? parts[0].trim() : '';
    _place2Controller.text = parts.length > 1  ? parts[1].trim() : '';
    _place3Controller.text = parts.length > 2  ? parts[2].trim() : '';
  }

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _tourNameController    = TextEditingController(text: item.TourName);
    _descriptionController = TextEditingController(text: item.Description);
    _purposeController     = TextEditingController(text: item.TourPurpose);
    _place1Controller = TextEditingController();
    _place2Controller = TextEditingController();
    _place3Controller = TextEditingController();
    _parseTourPlaces(item.TourPlace);

    _parseDateRange(item.Date);

    _selectedMonth = _months.contains(item.monthOfClaim)
        ? item.monthOfClaim
        : null;

    _boardLodgeCtrl       = TextEditingController();
    _businessPromoCtrl    = TextEditingController();
    _convTravelCtrl       = TextEditingController();
    _foodCtrl             = TextEditingController();
    _fuelCtrl             = TextEditingController();
    _postageCourierCtrl   = TextEditingController();
    _printingCtrl         = TextEditingController();
    _travelCtrl           = TextEditingController();
    _miscCtrl             = TextEditingController();

    _boardLodgeWBCtrl       = TextEditingController();
    _businessPromoWBCtrl    = TextEditingController();
    _convTravelWBCtrl       = TextEditingController();
    _foodWBCtrl             = TextEditingController();
    _fuelWBCtrl             = TextEditingController();
    _postageCourierWBCtrl   = TextEditingController();
    _printingWBCtrl         = TextEditingController();
    _travelWBCtrl           = TextEditingController();
    _miscWBCtrl             = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(advancetourdetailProvider.notifier)
          .fetchDetail(item.idTourExpense.toString());
    });
  }

  void _populateExpenseControllers(Advancetourexpensedetailmodel detail) {
    _boardLodgeCtrl.text = detail.boardLodge.toStringAsFixed(2);
    _businessPromoCtrl.text = detail.businessPromo.toStringAsFixed(2);
    _convTravelCtrl.text = detail.convTravel.toStringAsFixed(2);
    _foodCtrl.text = detail.food.toStringAsFixed(2);
    _fuelCtrl.text = detail.fuel.toStringAsFixed(2);
    _postageCourierCtrl.text = detail.postageCourier.toStringAsFixed(2);
    _printingCtrl.text = detail.printing.toStringAsFixed(2);
    _travelCtrl.text = detail.travel.toStringAsFixed(2);
    _miscCtrl.text = detail.misc.toStringAsFixed(2);

    _boardLodgeWBCtrl.text = detail.boardLodgeWithoutBill.toStringAsFixed(2);
    _businessPromoWBCtrl.text =
        detail.businessPromoWithoutBill.toStringAsFixed(2);
    _convTravelWBCtrl.text = detail.convTravelWithoutBill.toStringAsFixed(2);
    _foodWBCtrl.text = detail.foodWithoutBill.toStringAsFixed(2);
    _fuelWBCtrl.text = detail.fuelWithoutBill.toStringAsFixed(2);
    _postageCourierWBCtrl.text =
        detail.postageCourierWithoutBill.toStringAsFixed(2);
    _printingWBCtrl.text = detail.printingWithoutBill.toStringAsFixed(2);
    _travelWBCtrl.text = detail.travelWithoutBill.toStringAsFixed(2);
    _miscWBCtrl.text = detail.miscWithoutBill.toStringAsFixed(2);
  }

  double get _totalWithBill =>
      _parseDouble(_boardLodgeCtrl) +
          _parseDouble(_businessPromoCtrl) +
          _parseDouble(_convTravelCtrl) +
          _parseDouble(_foodCtrl) +
          _parseDouble(_fuelCtrl) +
          _parseDouble(_postageCourierCtrl) +
          _parseDouble(_printingCtrl) +
          _parseDouble(_travelCtrl) +
          _parseDouble(_miscCtrl);

  double get _totalWithoutBill =>
      _parseDouble(_boardLodgeWBCtrl) +
          _parseDouble(_businessPromoWBCtrl) +
          _parseDouble(_convTravelWBCtrl) +
          _parseDouble(_foodWBCtrl) +
          _parseDouble(_fuelWBCtrl) +
          _parseDouble(_postageCourierWBCtrl) +
          _parseDouble(_printingWBCtrl) +
          _parseDouble(_travelWBCtrl) +
          _parseDouble(_miscWBCtrl);

  double _parseDouble(TextEditingController c) =>
      double.tryParse(c.text) ?? 0.0;

  DateTime? _tryParseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Select Date';
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    // TODO: wire up to your submit API / provider
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Settlement submitted successfully!"),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _tourNameController.dispose();
    _descriptionController.dispose();
    _purposeController.dispose();
    _place1Controller.dispose();
    _place2Controller.dispose();
    _place3Controller.dispose();
    _boardLodgeCtrl.dispose();
    _businessPromoCtrl.dispose();
    _convTravelCtrl.dispose();
    _foodCtrl.dispose();
    _fuelCtrl.dispose();
    _postageCourierCtrl.dispose();
    _printingCtrl.dispose();
    _travelCtrl.dispose();
    _miscCtrl.dispose();
    _boardLodgeWBCtrl.dispose();
    _businessPromoWBCtrl.dispose();
    _convTravelWBCtrl.dispose();
    _foodWBCtrl.dispose();
    _fuelWBCtrl.dispose();
    _postageCourierWBCtrl.dispose();
    _printingWBCtrl.dispose();
    _travelWBCtrl.dispose();
    _miscWBCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncDetail = ref.watch(advancetourdetailProvider);
    asyncDetail.whenData((data) {
      if (data.isNotEmpty &&
          _boardLodgeCtrl.text.isEmpty) {
        _populateExpenseControllers(data.first);
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            ToolbarLayout(
              title: "Move To Settlement",
              navigateTo: const AdvanceTourExpense(),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: asyncDetail.when(
                  data: (_) => _buildForm(),
                  loading: () =>
                  const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section 1: General Info ──────────────────────
            FormSectionHeader(
              title: "General Information",
              icon: Icons.info_outline_rounded,
            ),
            const SizedBox(height: 14),

            _buildLabeledField(
              label: "Tour Name",
              child: _buildTextField(
                controller: _tourNameController,
                hint: "Enter tour name",
                validator: (v) =>
                v == null || v.isEmpty ? "Tour name is required" : null,
              ),
            ),
            const SizedBox(height: 14),

            _buildLabeledField(
              label: "Month of Claim",
              child: _buildMonthDropdown(),
            ),
            const SizedBox(height: 14),

            _buildLabeledField(
              label: "Description",
              child: _buildTextField(
                controller: _descriptionController,
                hint: "Enter description",
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 14),

            _buildLabeledField(
              label: "Purpose of Tour",
              child: _buildTextField(
                controller: _purposeController,
                hint: "Enter purpose of tour",
                maxLines: 2,
                validator: (v) =>
                v == null || v.isEmpty ? "Purpose is required" : null,
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _buildLabeledField(
                    label: "Start Date",
                    child: _buildDateButton(
                      date: _startDate,
                      onTap: () => _pickDate(context, true),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildLabeledField(
                    label: "End Date",
                    child: _buildDateButton(
                      date: _endDate,
                      onTap: () => _pickDate(context, false),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _buildLabeledField(
              label: "Places Visited",
              child: Column(
                children: [
                  _buildTextField(
                    controller: _place1Controller,
                    hint: "Place 1",
                    prefixIcon: _placeNumberBadge("1"),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _place2Controller,
                    hint: "Place 2",
                    prefixIcon: _placeNumberBadge("2"),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _place3Controller,
                    hint: "Place 3",
                    prefixIcon: _placeNumberBadge("3"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            const Divider(color: Color(0xFFEEEEEE), thickness: 1.2),
            const SizedBox(height: 20),

            SectionHeader(
              title: "Tour Summary – With Bill",
              icon: Icons.receipt_long_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(height: 14),
            _buildEditableExpenseCard(
              controllers: [
                _buildExpenseRow("Board & Lodge", _boardLodgeCtrl),
                _buildExpenseRow("Business Promo", _businessPromoCtrl),
                _buildExpenseRow("Conv & Travel", _convTravelCtrl),
                _buildExpenseRow("Food", _foodCtrl),
                _buildExpenseRow("Fuel", _fuelCtrl),
                _buildExpenseRow("Postage & Courier", _postageCourierCtrl),
                _buildExpenseRow("Printing", _printingCtrl),
                _buildExpenseRow("Travel", _travelCtrl),
                _buildExpenseRow("Miscellaneous", _miscCtrl),
              ],
              totalLabel: "Total (With Bill)",
              totalGetter: () => _totalWithBill,
              accentColor: AppColors.primary,
            ),

            const SizedBox(height: 20),

            SectionHeader(
              title: "Tour Summary – Without Bill",
              icon: Icons.receipt_outlined,
              color: Colors.orange,
            ),
            const SizedBox(height: 14),
            _buildEditableExpenseCard(
              controllers: [
                _buildExpenseRow("Board & Lodge", _boardLodgeWBCtrl),
                _buildExpenseRow("Business Promo", _businessPromoWBCtrl),
                _buildExpenseRow("Conv & Travel", _convTravelWBCtrl),
                _buildExpenseRow("Food", _foodWBCtrl),
                _buildExpenseRow("Fuel", _fuelWBCtrl),
                _buildExpenseRow("Postage & Courier", _postageCourierWBCtrl),
                _buildExpenseRow("Printing", _printingWBCtrl),
                _buildExpenseRow("Travel", _travelWBCtrl),
                _buildExpenseRow("Miscellaneous", _miscWBCtrl),
              ],
              totalLabel: "Total (Without Bill)",
              totalGetter: () => _totalWithoutBill,
              accentColor: Colors.orange,
            ),

            const SizedBox(height: 20),

            StatefulBuilder(
              builder: (_, setInner) => GrandTotalCard(
                grandTotal: _totalWithBill + _totalWithoutBill,
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded, size: 20),
                    SizedBox(width: 10),
                    Text(
                      "Submit Settlement",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }


  Widget _buildLabeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF666666),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    Widget? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
        TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedMonth,
      hint: const Text("Select Month",
          style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13.5)),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      items: _months
          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
          .toList(),
      onChanged: (val) => setState(() => _selectedMonth = val),
      validator: (v) => v == null ? "Please select a month" : null,
    );
  }

  Widget _buildDateButton({
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              _formatDate(date),
              style: TextStyle(
                fontSize: 13.5,
                color: date == null
                    ? const Color(0xFFAAAAAA)
                    : const Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeNumberBadge(String number) {
    return Container(
      margin: const EdgeInsets.all(10),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          number,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildEditableExpenseCard({
    required List<Widget> controllers,
    required String totalLabel,
    required double Function() totalGetter,
    required Color accentColor,
  }) {
    return StatefulBuilder(
      builder: (_, setInner) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              ...controllers,
              Container(
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.07),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      totalLabel,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                    Text(
                      "₹ ${totalGetter().toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpenseRow(
      String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF444444),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: TextFormField(
              controller: controller,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (_) => setState(() {}), // refresh totals live
              style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                prefixText: "₹ ",
                prefixStyle: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                  const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                  const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                  BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}