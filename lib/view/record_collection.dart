import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sssbuddy/viewModel/financialyear_dd_viewmodel.dart';
import 'package:sssbuddy/viewModel/schollname_dd_viewmodel.dart';
import 'package:sssbuddy/viewModel/record_collection_payment_viewmodel.dart';

import '../Values/Colors/app_colors.dart';
import '../components/DropdownError.dart';
import '../components/DropdownSkeleton.dart';
import '../components/payment_forms.dart';
import '../components/searchable_dropdown.dart';
import '../components/toolbar_layout.dart';
import '../viewModel/invoice_dd_viewmodel.dart';
import '../viewModel/login_view_model.dart';
import 'dashboard.dart';

enum PaymentMode { none, cash, cheque, neft, pdc }

extension PaymentModeExt on PaymentMode {
  String get label {
    switch (this) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.cheque:
        return 'Cheque';
      case PaymentMode.neft:
        return 'NEFT';
      case PaymentMode.pdc:
        return 'PDC';
      default:
        return '';
    }
  }

  String get apiValue {
    switch (this) {
      case PaymentMode.cash:
        return '1';
      case PaymentMode.cheque:
        return '2';
      case PaymentMode.neft:
        return '3';
      case PaymentMode.pdc:
        return '4';
      default:
        return '0';
    }
  }
}

class RecordCollection extends ConsumerStatefulWidget {
  const RecordCollection({super.key});

  @override
  ConsumerState<RecordCollection> createState() => _RecordCollectionState();
}

class _RecordCollectionState extends ConsumerState<RecordCollection> {
  // ── Basic fields ─────────────────────────────────────────────────────────
  final _amountController = TextEditingController();

  String? selectedSchool;
  String? selectedSchoolCusId;
  String? selectedFinancialYearName;
  String? selectedFinancialYearId;

  // Invoice
  String? _invoiceId;
  String? _invoiceNumber;
  String? _pendingAmount;

  PaymentMode selectedPaymentMode = PaymentMode.none;

  // ── Cash controllers ──────────────────────────────────────────────────────
  final _cashReceivedOnCtrl = TextEditingController();
  final _cashDepositedOnCtrl = TextEditingController();
  final _cashDepositedBranchCtrl = TextEditingController();
  String? _selectedCashBank;

  // ── Cheque controllers ────────────────────────────────────────────────────
  final _chequeNumberCtrl = TextEditingController();
  final _chequeDateCtrl = TextEditingController();
  final _chequeBankCtrl = TextEditingController();
  final _chequeDepositedDateCtrl = TextEditingController();
  final _chequeBranchCtrl = TextEditingController();
  String? _selectedChequeDepositBank;

  // ── NEFT controllers ──────────────────────────────────────────────────────
  final _neftTransactionCtrl = TextEditingController();

  // ── PDC controllers ───────────────────────────────────────────────────────
  final _pdcChequeNoCtrl = TextEditingController();
  final _pdcChequeDateCtrl = TextEditingController();
  final _pdcChequeBankCtrl = TextEditingController();
  final _pdcChequeBranchCtrl = TextEditingController();

  // ── Image ─────────────────────────────────────────────────────────────────
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  static const _paymentModes = ['Cash', 'Cheque', 'NEFT', 'PDC'];

  // ── Today's date string for ReceivedDate field ────────────────────────────
  String get _todayFormatted => DateFormat('dd/MM/yyyy').format(DateTime.now());

  @override
  void dispose() {
    _amountController.dispose();
    _cashReceivedOnCtrl.dispose();
    _cashDepositedOnCtrl.dispose();
    _cashDepositedBranchCtrl.dispose();
    _chequeNumberCtrl.dispose();
    _chequeDateCtrl.dispose();
    _chequeBankCtrl.dispose();
    _chequeDepositedDateCtrl.dispose();
    _chequeBranchCtrl.dispose();
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
      _invoiceId = null;
      _invoiceNumber = null;
      _pendingAmount = null;
      _amountController.clear();
    });

    if (cusId != null && cusId.isNotEmpty) {
      ref.read(invoiceProvider.notifier).fetchForCustomer(cusId);
    } else {
      ref.read(invoiceProvider.notifier).clear();
    }
  }


  void _onFinancialYearChanged(String? yearName, String? yearId) {
    setState(() {
      selectedFinancialYearName = yearName;
      selectedFinancialYearId = yearId;
    });

    if (yearId == null || yearId == '0') return;

    final schoolNotSelected =
        selectedSchoolCusId == null ||
        selectedSchoolCusId!.isEmpty ||
        selectedSchoolCusId == 'null';

    if (schoolNotSelected) {
      _showAlert('Select the school name');
      return;
    }

    ref.read(invoiceProvider.notifier).fetchForCustomer(selectedSchoolCusId!);
  }

  void _onPaymentModeChanged(String? mode) {
    setState(() {
      switch (mode) {
        case 'Cash':
          selectedPaymentMode = PaymentMode.cash;
          break;
        case 'Cheque':
          selectedPaymentMode = PaymentMode.cheque;
          break;
        case 'NEFT':
          selectedPaymentMode = PaymentMode.neft;
          break;
        case 'PDC':
          selectedPaymentMode = PaymentMode.pdc;
          break;
        default:
          selectedPaymentMode = PaymentMode.none;
      }
    });
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select Action'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo from Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Select Image from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (file != null) {
      setState(() => _selectedImage = File(file.path));
    }
  }

  void _removeImage() => setState(() => _selectedImage = null);

  void _showAlert(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessAlert(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  DateTime? _parseDate(String dateStr) {
    try {
      return DateFormat('dd/MM/yyyy').parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _buildPayload() {
    String chequenumber = '';
    String chequedate = '';
    String cashreceiveddate = '';
    String depositeddate = '';
    String branchname = '';
    String depositedbankname = '';
    String transactionId = '';

    switch (selectedPaymentMode) {
      case PaymentMode.cash: // "1"
        cashreceiveddate = _cashReceivedOnCtrl.text;
        depositeddate = _cashDepositedOnCtrl.text;
        branchname = _cashDepositedBranchCtrl.text;
        depositedbankname = _selectedCashBank ?? '';
        break;

      case PaymentMode.cheque: // "2"
        chequenumber = _chequeNumberCtrl.text;
        chequedate = _chequeDateCtrl.text;
        depositeddate = _chequeDepositedDateCtrl.text;
        branchname = _chequeBranchCtrl.text;
        depositedbankname = _selectedChequeDepositBank ?? '';
        break;

      case PaymentMode.neft: // "3"
        transactionId = _neftTransactionCtrl.text;
        break;

      case PaymentMode.pdc: // "4"
        chequenumber = _pdcChequeNoCtrl.text;
        depositeddate = _pdcChequeDateCtrl.text;
        branchname = _pdcChequeBranchCtrl.text;
        depositedbankname = _pdcChequeBankCtrl.text;
        break;

      default:
        break;
    }

    return {
      'InvoiceID': _invoiceId ?? '0',
      'CustomerId': selectedSchoolCusId ?? '0',
      'FinancialYear': selectedFinancialYearName ?? '',
      'InvoiceNumber': _invoiceNumber ?? 'No Invoices Found',
      'Received': _amountController.text,
      'ReceivedDate': _todayFormatted,
      'PaymentMode': selectedPaymentMode.apiValue,
      'CreatedBy': '',
      'CashRecdDate': cashreceiveddate,
      'ChequeDate': chequedate,
      'ChequeNumber': chequenumber,
      'NEFTDetails': transactionId,
      'DepositedBank': depositedbankname,
      'DepositedBranch': branchname,
      'DepositedBy': '',
      'DepositedDate': depositeddate,
    };
  }

  Future<void> _onSubmit() async {
    final amount = _amountController.text.trim();
    final financialYear = selectedFinancialYearName ?? '';

    if (selectedSchoolCusId == null || selectedSchoolCusId == '0') {
      _showAlert('Select Your school name');
      return;
    }

    if (financialYear.isEmpty || financialYear == 'Select financial year') {
      _showAlert('Select financial year');
      return;
    }

    if (amount.isEmpty) {
      _showAlert('Enter the received amount');
      return;
    }

    if (selectedPaymentMode == PaymentMode.none) {
      _showAlert('Select Mode of Payment');
      return;
    }

    switch (selectedPaymentMode) {
      case PaymentMode.cash:
        final receivedDate = _cashReceivedOnCtrl.text.trim();
        final depositedDate = _cashDepositedOnCtrl.text.trim();
        final branch = _cashDepositedBranchCtrl.text.trim();

        if (receivedDate.isEmpty) {
          _showAlert('Enter the received date');
          return;
        }
        if (depositedDate.isEmpty) {
          _showAlert('Enter the Deposited date');
          return;
        }
        if (_selectedCashBank == null || _selectedCashBank!.isEmpty) {
          _showAlert('Select bank');
          return;
        }
        if (branch.isEmpty) {
          _showAlert('Enter the cash Deposited branch');
          return;
        }

        final dDeposited = _parseDate(depositedDate);
        final dReceived = _parseDate(receivedDate);
        if (dDeposited == null || dReceived == null) {
          _showAlert('Invalid date format');
          return;
        }
        if (dDeposited.isBefore(dReceived)) {
          _showAlert('Enter the deposited date after received date');
          return;
        }
        break;

      case PaymentMode.cheque:
        final chequeNo = _chequeNumberCtrl.text.trim();
        final chequeDate = _chequeDateCtrl.text.trim();
        final chequeBank = _chequeBankCtrl.text.trim();
        final depositedDate = _chequeDepositedDateCtrl.text.trim();
        final branch = _chequeBranchCtrl.text.trim();

        if (chequeNo.isEmpty) {
          _showAlert('Enter the cheque number');
          return;
        }
        if (chequeDate.isEmpty) {
          _showAlert('Enter the cheque date');
          return;
        }
        if (chequeBank.isEmpty) {
          _showAlert('Enter the cheque bank');
          return;
        }
        if (_selectedChequeDepositBank == null ||
            _selectedChequeDepositBank!.isEmpty) {
          _showAlert('Select Bank');
          return;
        }
        if (branch.isEmpty) {
          _showAlert('Enter the cash Deposited branch');
          return;
        }

        final dDeposited = _parseDate(
          depositedDate.isEmpty ? chequeDate : depositedDate,
        );
        final dCheque = _parseDate(chequeDate);
        if (dDeposited == null || dCheque == null) {
          _showAlert('Invalid date format');
          return;
        }
        if (depositedDate.isNotEmpty && dDeposited.isBefore(dCheque)) {
          _showAlert('Enter the deposited date after received date');
          return;
        }
        break;

      case PaymentMode.neft:
        break;

      case PaymentMode.pdc:
        if (_pdcChequeNoCtrl.text.trim().isEmpty) {
          _showAlert('Enter the Cheque number');
          return;
        }
        if (_pdcChequeDateCtrl.text.trim().isEmpty) {
          _showAlert('Enter the Cheque date');
          return;
        }
        if (_pdcChequeBankCtrl.text.trim().isEmpty) {
          _showAlert('Enter the cheque bank');
          return;
        }
        if (_pdcChequeBranchCtrl.text.trim().isEmpty) {
          _showAlert('Enter the cheque bank branch');
          return;
        }
        break;

      default:
        break;
    }

    final payload = _buildPayload();


    final loginState = ref.read(loginProvider).value;
    final userId = loginState?.VimsIdUser?.toString() ?? '';

    final success = await ref
        .read(createPaymentProvider.notifier)
        .createPayment(
          invoiceID: payload['InvoiceID']!,
          customerId: payload['CustomerId']!,
          financialYear: payload['FinancialYear']!,
          invoiceNumber: payload['InvoiceNumber']!,
          received: payload['Received']!,
          receivedDate: payload['ReceivedDate']!,
          paymentMode: payload['PaymentMode']!,
          createdBy: userId,
          cashRecdDate: payload['CashRecdDate']!,
          chequeDate: payload['ChequeDate']!,
          chequeNumber: payload['ChequeNumber']!,
          neftDetails: payload['NEFTDetails']!,
          depositedBank: payload['DepositedBank']!,
          depositedBranch: payload['DepositedBranch']!,
          depositedBy: userId,
          depositedDate: payload['DepositedDate']!,
          imageFile: _selectedImage,
        );

    if (success) {
      final result = ref.read(createPaymentProvider).value;
      _showSuccessAlert(
        result?.resultMessage ?? 'Payment Successfully Updated',
      );
    } else {
      final err = ref.read(createPaymentProvider).error;
      _showAlert(err?.toString() ?? 'Payment submission failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolnameAsync = ref.watch(schoolnameProvider);
    final financialAsync = ref.watch(financialyearProvider);
    final invoiceAsync = ref.watch(invoiceProvider);
    final submitState = ref.watch(createPaymentProvider);

    final bool isSubmitting = submitState.isLoading;

    final bool hasValidInvoice =
        _invoiceId != null && _invoiceId != '0' && _invoiceId!.isNotEmpty;

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
                      const _SectionLabel(label: "Basic Information"),
                      const SizedBox(height: 12),

                      schoolnameAsync.when(
                        loading: () =>
                            const DropdownSkeleton(label: "Select School"),
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
                          label: "Select Financial Year",
                        ),
                        error: (e, _) => DropdownError(
                          label: "Select Financial Year",
                          onRetry: () => ref
                              .read(financialyearProvider.notifier)
                              .refresh(),
                        ),
                        data: (years) => SearchableDropdown<dynamic>(
                          label: "Select Financial Year",
                          hint: "Choose a year",
                          value: selectedFinancialYearName,
                          items: years,
                          itemLabel: (e) => e.nameValue ?? "",
                          itemValue: (e) => e.nameValue ?? "",
                          onChanged: (v) {
                            if (v == null) return;
                            try {
                              final match = years.firstWhere(
                                (e) => e.nameValue == v,
                              );
                              _onFinancialYearChanged(
                                match.nameValue,
                                match.idValue?.toString() ?? '0',
                              );
                            } catch (_) {
                              _onFinancialYearChanged(v, '0');
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      if (selectedSchoolCusId != null &&
                          selectedFinancialYearId != null &&
                          selectedFinancialYearId != '0') ...[
                        const _SectionLabel(label: "Invoice Details"),
                        const SizedBox(height: 12),

                        invoiceAsync.when(
                          loading: () =>
                              const DropdownSkeleton(label: "Invoice Details"),
                          error: (e, _) => DropdownError(
                            label: "Invoice Details",
                            onRetry: () {
                              if (selectedSchoolCusId != null) {
                                ref
                                    .read(invoiceProvider.notifier)
                                    .fetchForCustomer(selectedSchoolCusId!);
                              }
                            },
                          ),
                          data: (invoices) {
                            if (invoices.isEmpty) {
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => setState(() {
                                  _invoiceId = null;
                                  _invoiceNumber = null;
                                }),
                              );
                              return const _InactiveDropdownHint(
                                hint: "No invoices found",
                              );
                            }

                            WidgetsBinding.instance.addPostFrameCallback(
                              (_) => setState(() {
                                _invoiceId =
                                    invoices.first.InvoiceId?.toString() ?? '0';
                                _invoiceNumber =
                                    invoices.first.InvoiceNumber ?? '';
                                _pendingAmount =
                                    invoices.first.PendingAmount?.toString() ??
                                    '0';
                              }),
                            );

                            final displayText =
                                "${invoices.first.InvoiceNumber ?? ''} - Pending ${invoices.first.PendingAmount ?? '0'}";

                            return FormInputField(
                              controller: TextEditingController(
                                text: displayText,
                              ),
                              label: "Invoice Details",
                              icon: Icons.receipt_long,
                              readOnly: true,
                            );
                          },
                        ),

                        const SizedBox(height: 16),
                      ],

                      FormInputField(
                        controller: _amountController,
                        label: "Amount Received",
                        icon: Icons.currency_rupee_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      const _SectionLabel(label: "Payment Details"),
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

                      const _SectionLabel(label: "Attachment"),
                      const SizedBox(height: 12),
                      _ImagePickerTile(
                        selectedImage: _selectedImage,
                        onPick: _showImageSourceDialog,
                        onRemove: _removeImage,
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: (isSubmitting || !hasValidInvoice)
                              ? null
                              : _onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.primary
                                .withOpacity(0.4),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 20,
                                    ),
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
          chequeBranchController: _chequeBranchCtrl,
          selectedDepositBank: _selectedChequeDepositBank,
          onDepositBankChanged: (v) =>
              setState(() => _selectedChequeDepositBank = v),
        );
      case PaymentMode.neft:
        return NeftPaymentForm(neftTransactionController: _neftTransactionCtrl);
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
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: Colors.grey.shade400,
          ),
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
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 16,
                ),
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
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 30,
              color: AppColors.primary.withOpacity(0.7),
            ),
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
