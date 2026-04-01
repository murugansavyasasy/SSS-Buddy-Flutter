import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sssbuddy/viewModel/financialyear_dd_viewmodel.dart';
import 'package:sssbuddy/viewModel/schollname_dd_viewmodel.dart';
import '../Values/Colors/app_colors.dart';
import '../components/DropdownError.dart';
import '../components/DropdownSkeleton.dart';
import '../components/payment_forms.dart';
import '../components/searchable_dropdown.dart';
import '../components/toolbar_layout.dart';
import '../viewModel/invoice_dd_viewmodel.dart';
import 'dashboard.dart';

enum PaymentMode { none, cash, cheque, neft, pdc }

extension PaymentModeExt on PaymentMode {
  String get label {
    switch (this) {
      case PaymentMode.cash: return 'Cash';
      case PaymentMode.cheque: return 'Cheque';
      case PaymentMode.neft: return 'NEFT';
      case PaymentMode.pdc: return 'PDC';
      default: return '';
    }
  }
}

class RecordCollection extends ConsumerStatefulWidget {
  const RecordCollection({super.key});

  @override
  ConsumerState<RecordCollection> createState() => _RecordCollectionState();
}

class _RecordCollectionState extends ConsumerState<RecordCollection> {
  final _amountController = TextEditingController();
  final _invoiceController = TextEditingController();

  String? selectedSchool;
  String? selectedSchoolCusId;
  String? selectedFinancialYear;
  String? selectedInvoice;
  PaymentMode selectedPaymentMode = PaymentMode.none;

  final _cashReceivedOnCtrl = TextEditingController();
  final _cashDepositedOnCtrl = TextEditingController();
  final _cashDepositedBranchCtrl = TextEditingController();
  String? _selectedCashBank;

  final _chequeNumberCtrl = TextEditingController();
  final _chequeDateCtrl = TextEditingController();
  final _chequeBankCtrl = TextEditingController();
  final _chequeDepositedDateCtrl = TextEditingController();

  final _neftTransactionCtrl = TextEditingController();

  final _pdcChequeNoCtrl = TextEditingController();
  final _pdcChequeDateCtrl = TextEditingController();
  final _pdcChequeBankCtrl = TextEditingController();
  final _pdcChequeBranchCtrl = TextEditingController();

  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  static const _paymentModes = ['Cash', 'Cheque', 'NEFT', 'PDC'];

  @override
  void dispose() {
    _amountController.dispose();
    _invoiceController.dispose();
    _cashReceivedOnCtrl.dispose();
    _cashDepositedOnCtrl.dispose();
    _cashDepositedBranchCtrl.dispose();
    _chequeNumberCtrl.dispose();
    _chequeDateCtrl.dispose();
    _chequeBankCtrl.dispose();
    _chequeDepositedDateCtrl.dispose();
    _neftTransactionCtrl.dispose();
    _pdcChequeNoCtrl.dispose();
    _pdcChequeDateCtrl.dispose();
    _pdcChequeBankCtrl.dispose();
    _pdcChequeBranchCtrl.dispose();
    super.dispose();
  }

  void _onSchoolSelected(String? customerName, String? cusId) {
    setState(() {
      selectedSchool = customerName;
      selectedSchoolCusId = cusId;
      selectedInvoice = null;
      _invoiceController.clear();
      _amountController.clear();
    });
    if (cusId != null && cusId.isNotEmpty) {
      ref.read(invoiceProvider.notifier).fetchForCustomer(cusId);
    } else {
      ref.read(invoiceProvider.notifier).clear();
    }
  }


  void _onPaymentModeChanged(String? mode) {
    setState(() {
      switch (mode) {
        case 'Cash': selectedPaymentMode = PaymentMode.cash; break;
        case 'Cheque': selectedPaymentMode = PaymentMode.cheque; break;
        case 'NEFT': selectedPaymentMode = PaymentMode.neft; break;
        case 'PDC': selectedPaymentMode = PaymentMode.pdc; break;
        default: selectedPaymentMode = PaymentMode.none;
      }
    });
  }

  Future<void> _pickImage() async {
    final XFile? file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file != null) {
      setState(() => _selectedImage = File(file.path));
    }
  }

  void _removeImage() => setState(() => _selectedImage = null);

  void _onSubmit() {
    // TODO: Collect all data and call your submit API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Record submitted successfully!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schoolnameAsync = ref.watch(schoolnameProvider);
    final financialAsync = ref.watch(financialyearProvider);
    final invoiceAsync = ref.watch(invoiceProvider);

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
            const ToolbarLayout(
              title: "Create Record Collection",
              navigateTo: Dashboard(),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      _SectionLabel(label: "Basic Information"),
                      const SizedBox(height: 12),

                      schoolnameAsync.when(
                        loading: () => const DropdownSkeleton(label: "Select School"),
                        error: (e, _) => DropdownError(
                          label: "Select School",
                          onRetry: () =>
                              ref.read(schoolnameProvider.notifier).refresh(),
                        ),
                        data: (schools) => SearchableDropdown<dynamic>(
                          label: "Select School",
                          hint: "Choose a school",
                          value: selectedSchool,
                          items: schools,
                          itemLabel: (e) => e.CustomerName ?? "",
                          itemValue: (e) => e.CustomerName ?? "",
                          onChanged: (v) {
                            if (v == null) return;
                            try {
                              final match = schools.firstWhere(
                                    (e) => e.CustomerName == v,
                              );
                              _onSchoolSelected(
                                match.CustomerName,
                                match.CustomerID?.toString() ?? '',
                              );
                            } catch (_) {
                              _onSchoolSelected(v, null);
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      financialAsync.when(
                        loading: () => const DropdownSkeleton(
                            label: "Select Financial Year"),
                        error: (e, _) => DropdownError(
                          label: "Select Financial Year",
                          onRetry: () => ref
                              .read(financialyearProvider.notifier)
                              .refresh(),
                        ),
                        data: (years) => SearchableDropdown<dynamic>(
                          label: "Select Financial Year",
                          hint: "Choose a year",
                          value: selectedFinancialYear,
                          items: years,
                          itemLabel: (e) => e.nameValue ?? "",
                          itemValue: (e) => e.nameValue ?? "",
                          onChanged: (v) =>
                              setState(() => selectedFinancialYear = v),
                        ),
                      ),

                      const SizedBox(height: 24),

                      _SectionLabel(label: "Invoice Details"),
                      const SizedBox(height: 12),

                      invoiceAsync.when(
                        loading: () => const DropdownSkeleton(label: "Invoice Details"),
                        error: (e, _) => DropdownError(
                          label: "Invoice Details",
                          onRetry: () {
                            if (selectedSchoolCusId != null) {
                              ref.read(invoiceProvider.notifier)
                                  .fetchForCustomer(selectedSchoolCusId!);
                            }
                          },
                        ),
                        data: (invoices) {
                          if (invoices.isEmpty) {
                            return const _InactiveDropdownHint(
                              hint: "No invoice found",
                            );
                          }

                          final invoice = invoices.first;

                          final displayText =
                              "${invoice.InvoiceNumber ?? ''} - ${invoice.PendingAmount ?? '0'}";


                          return FormInputField(
                            controller: TextEditingController(text: displayText),
                            label: "Invoice Details",
                            icon: Icons.receipt_long,
                            readOnly: true,
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      FormInputField(
                        controller: _amountController,
                        label: "Amount Received",
                        icon: Icons.currency_rupee_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _SectionLabel(label: "Payment Details"),
                      const SizedBox(height: 12),

                      SearchableDropdown<String>(
                        label: "Mode of Payment",
                        hint: "Select payment mode",
                        value: selectedPaymentMode == PaymentMode.none
                            ? null
                            : selectedPaymentMode.label,
                        items: _paymentModes,
                        itemLabel: (e) => e,
                        itemValue: (e) => e,
                        onChanged: _onPaymentModeChanged,
                      ),

                      if (selectedPaymentMode != PaymentMode.none) ...[
                        const SizedBox(height: 20),
                        _buildPaymentForm(),
                      ],

                      const SizedBox(height: 24),

                      _SectionLabel(label: "Attachment"),
                      const SizedBox(height: 12),
                      _ImagePickerTile(
                        selectedImage: _selectedImage,
                        onPick: _pickImage,
                        onRemove: _removeImage,
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline_rounded,
                                  size: 20),
                              SizedBox(width: 8),
                              Text(
                                "Submit Collection",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
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

  Widget _buildPaymentForm() {
    switch (selectedPaymentMode) {
      case PaymentMode.cash:
        return CashPaymentForm(
          cashReceivedOnController: _cashReceivedOnCtrl,
          cashDepositedOnController: _cashDepositedOnCtrl,
          cashDepositedBranchController: _cashDepositedBranchCtrl,
          selectedBank: _selectedCashBank,
          onBankChanged: (v) => setState(() => _selectedCashBank = v),
        );
      case PaymentMode.cheque:
        return ChequePaymentForm(
          chequeNumberController: _chequeNumberCtrl,
          chequeDateController: _chequeDateCtrl,
          chequeBankController: _chequeBankCtrl,
          chequeDepositedDateController: _chequeDepositedDateCtrl,
        );
      case PaymentMode.neft:
        return NeftPaymentForm(
          neftTransactionController: _neftTransactionCtrl,
        );
      case PaymentMode.pdc:
        return PdcPaymentForm(
          pdcChequeNoController: _pdcChequeNoCtrl,
          pdcChequeDateController: _pdcChequeDateCtrl,
          pdcChequeBankController: _pdcChequeBankCtrl,
          pdcChequeBranchController: _pdcChequeBranchCtrl,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}


class _InactiveDropdownHint extends StatelessWidget {
  final String hint;
  const _InactiveDropdownHint({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Text(
            hint,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}


class _ImagePickerTile extends StatelessWidget {
  final File? selectedImage;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ImagePickerTile({
    required this.selectedImage,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedImage != null) {
      return Stack(
        children: [
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              image: DecorationImage(
                image: FileImage(selectedImage!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 30, color: AppColors.primary.withOpacity(0.7)),
            const SizedBox(height: 6),
            Text(
              "Tap to add image",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "JPG, PNG supported",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

