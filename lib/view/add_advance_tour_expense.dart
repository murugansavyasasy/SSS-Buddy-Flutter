import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Values/Colors/app_colors.dart';
import '../auth/model/AddTourExpenceModal.dart';
import '../auth/model/AdvanceTourExpenseModel.dart';
import '../components/toolbar_layout.dart';
import '../provider/app_providers.dart';
import '../viewModel/addAdvace_tour_viewmodal.dart';
import '../viewModel/advance_tourexpense_viewmodel.dart';
import '../viewModel/login_view_model.dart';
import 'advance_tour_expense.dart';

class AddAdvanceTourExpense extends ConsumerStatefulWidget {
  final Advancetourexpensemodel? editData;
  const AddAdvanceTourExpense({super.key, this.editData});

  @override
  ConsumerState<AddAdvanceTourExpense> createState() =>
      _AddAdvanceTourExpenseState();
}

class _AddAdvanceTourExpenseState extends ConsumerState<AddAdvanceTourExpense> {
  final _tourNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _purposeController = TextEditingController();
  final _place1Controller = TextEditingController();
  final _place2Controller = TextEditingController();
  final _place3Controller = TextEditingController();

  String? _selectedMonth;
  DateTime? _startDate;
  DateTime? _endDate;

  final _boardingController = TextEditingController();
  final _businessPromoController = TextEditingController();
  final _localConveyanceController = TextEditingController();
  final _foodController = TextEditingController();
  final _petrolController = TextEditingController();
  final _postageController = TextEditingController();
  final _printingController = TextEditingController();
  final _trainBusController = TextEditingController();
  final _miscController = TextEditingController();
  final _remarksController = TextEditingController();

  double _totalExpense = 0.0;

  final List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.editData != null) {
      final data = widget.editData!;

      _tourNameController.text = data.TourName;
      _descriptionController.text = data.Description;
      _purposeController.text = data.TourPurpose;

      _place1Controller.text = data.TourPlace;
      _selectedMonth = _months[int.parse(data.monthOfClaim) - 1];

      _totalExpense = double.tryParse(data.TotalTourExpense) ?? 0.0;
    }

    for (final ctrl in _summaryControllers) {
      ctrl.addListener(_calculateTotal);
    }
  }

  List<TextEditingController> get _summaryControllers => [
    _boardingController,
    _businessPromoController,
    _localConveyanceController,
    _foodController,
    _petrolController,
    _postageController,
    _printingController,
    _trainBusController,
    _miscController,
  ];

  void _calculateTotal() {
    //changed  by balu
    double total = 0.0;
    for (final ctrl in _summaryControllers) {
      total += double.tryParse(ctrl.text.trim()) ?? 0.0;
    }
    setState(() => _totalExpense = total);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
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
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() async {
    final loginData = ref.read(loginProvider).value;
    if (loginData == null) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select dates")),
      );
      return;
    }

    final request = TourExpenseRequest(
      idTourExpense: "0",
      idUser: loginData.VimsIdUser.toString(),
      tourPurpose: _purposeController.text,
      monthOfClaim:
      (_months.indexOf(_selectedMonth ?? "Jan") + 1).toString(),
      tourName: _tourNameController.text,
      tourId: "",
      startDate:
      "${_startDate!.day}/${_startDate!.month}/${_startDate!.year}",
      endDate:
      "${_endDate!.day}/${_endDate!.month}/${_endDate!.year}",
      tourPlace1: _place1Controller.text,
      tourPlace2: _place2Controller.text,
      tourPlace3: _place3Controller.text,
      remarksWithoutBill: _remarksController.text,
      description: _descriptionController.text,
      totalTourExpense: _totalExpense.toString(),
      processBy: loginData.VimsIdUser.toString(),
      processType: "AdvanceTour",
      tourItemList: [
        TourItem(
          boardLodge: _boardingController.text,
          businessPromo: _businessPromoController.text,
          convTravel: _localConveyanceController.text,
          food: _foodController.text,
          fuel: _petrolController.text,
          postageCourier: _postageController.text,
          printing: _printingController.text,
          travel: _trainBusController.text,
          misc: _miscController.text,
        ),
      ],
    );
    await ref
        .read(tourExpenseProvider.notifier)
        .submitTourExpense(request);
  }
  void _clearForm() {
    _tourNameController.clear();
    _descriptionController.clear();
    _purposeController.clear();
    _place1Controller.clear();
    _place2Controller.clear();
    _place3Controller.clear();
    _remarksController.clear();

    for (final ctrl in _summaryControllers) {
      ctrl.clear();
    }

    setState(() {
      _selectedMonth = null;
      _startDate = null;
      _endDate = null;
      _totalExpense = 0.0;
    });
  }
  @override
  void dispose() {
    _tourNameController.dispose();
    _descriptionController.dispose();
    _purposeController.dispose();
    _place1Controller.dispose();
    _place2Controller.dispose();
    _place3Controller.dispose();
    for (final ctrl in _summaryControllers) {
      ctrl.dispose();
    }
    _remarksController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: Colors.black54),
      prefixIcon: icon != null
          ? Icon(icon, size: 18, color: AppColors.primary)
          : null,
      filled: true,
      fillColor: const Color(0xFFF5F6FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: _inputDecoration(label, icon: Icons.currency_rupee),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<TourExpenseResponse?>>(
      tourExpenseProvider,
          (previous, next) {
        next.when(
          data: (res) {
            if (res != null && res.result == 1) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res.resultMessage)),
              );

              _clearForm();
              Navigator.pop(context, true);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res?.resultMessage ?? "Failed")),
              );
            }
          },
          loading: () {},
          error: (e, st) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Submission Failed ❌")),
            );
          },
        );
      },
    );
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
              title: "Add Tour Expense",
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader("General Information"),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _tourNameController,
                          decoration: _inputDecoration(
                            "Tour Name",
                            icon: Icons.tour,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<String>(
                          value: _selectedMonth,
                          decoration: _inputDecoration(
                            "Month of Claim",
                            icon: Icons.calendar_month,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          items: _months
                              .map(
                                (m) =>
                                    DropdownMenuItem(value: m, child: Text(m)),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedMonth = val),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: _inputDecoration(
                            "Description",
                            icon: Icons.description_outlined,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _purposeController,
                          maxLines: 2,
                          decoration: _inputDecoration(
                            "Purpose of Tour",
                            icon: Icons.flag_outlined,
                          ),
                        ),
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () => _pickDate(isStart: true),
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    decoration: _inputDecoration(
                                      _startDate == null
                                          ? "Start Date"
                                          : "${_startDate!.day}/${_startDate!.month}/${_startDate!.year}",
                                      icon: Icons.date_range_outlined,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () => _pickDate(isStart: false),
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    decoration: _inputDecoration(
                                      _endDate == null
                                          ? "End Date"
                                          : "${_endDate!.day}/${_endDate!.month}/${_endDate!.year}",
                                      icon: Icons.event_available_outlined,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          "Add Places",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _place1Controller,
                          decoration: _inputDecoration(
                            "Place 1",
                            icon: Icons.location_on_outlined,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _place2Controller,
                          decoration: _inputDecoration(
                            "Place 2",
                            icon: Icons.location_on_outlined,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: TextFormField(
                          controller: _place3Controller,
                          decoration: _inputDecoration(
                            "Place 3",
                            icon: Icons.location_on_outlined,
                          ),
                        ),
                      ),

                      _sectionHeader("Advance Tour Summary"),

                      _amountField("Boarding and Lodging", _boardingController),
                      _amountField(
                        "Business Promotion",
                        _businessPromoController,
                      ),
                      _amountField(
                        "Local Conveyance",
                        _localConveyanceController,
                      ),
                      _amountField("Food and Beverages", _foodController),
                      _amountField("Petrol", _petrolController),
                      _amountField("Postage and Courier", _postageController),
                      _amountField(
                        "Printing and Stationary",
                        _printingController,
                      ),
                      _amountField("Train / Bus Ticket", _trainBusController),
                      _amountField("Miscellaneous Expenses", _miscController),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: TextFormField(
                          controller: _remarksController,
                          maxLines: 3,
                          decoration: _inputDecoration(
                            "Remarks",
                            icon: Icons.comment_outlined,
                          ),
                        ),
                      ),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Total Tour Expense",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              "₹ ${_totalExpense.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Submit",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
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
}
