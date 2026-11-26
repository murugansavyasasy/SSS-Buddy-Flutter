import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:sssbuddy/viewModel/financialyear_dd_viewmodel.dart';
import 'package:sssbuddy/viewModel/schollname_dd_viewmodel.dart';
import 'package:sssbuddy/viewModel/record_collection_payment_viewmodel.dart';

import '../Values/Colors/app_colors.dart';
import '../auth/model/FinancialYearModel.dart';
import '../components/DropdownError.dart';
import '../components/DropdownSkeleton.dart';
import '../components/form_width.dart';
import '../components/payment_forms.dart';
import '../components/searchable_dropdown.dart';
import '../components/toolbar_layout.dart';
import '../viewModel/invoice_dd_viewmodel.dart';
import '../viewModel/login_view_model.dart';
import 'dashboard.dart';

enum PaymentMode { none, cash, cheque, neft, rtgs, bankTransfer, upi, pdc }

extension PaymentModeExt on PaymentMode {
  String get label {
    switch (this) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.cheque:
        return 'Cheque';
      case PaymentMode.neft:
        return 'NEFT';
      case PaymentMode.rtgs:
        return 'RTGS';
      case PaymentMode.bankTransfer:
        return 'Bank Transfer';
      case PaymentMode.upi:
        return 'UPI';
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
      case PaymentMode.rtgs:
        return '5';
      case PaymentMode.bankTransfer:
        return '6';
      case PaymentMode.upi:
        return '7';
      default:
        return '0';
    }
  }
}

String _normalizeModeLabel(String raw) {
  return raw.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
}

class RecordCollection extends ConsumerStatefulWidget {
  const RecordCollection({super.key});

  @override
  ConsumerState<RecordCollection> createState() => _RecordCollectionState();
}

class _RecordCollectionState extends ConsumerState<RecordCollection> {
  // ── Basic fields ─────────────────────────────────────────────────────────
  final _amountController = TextEditingController();

  /// Read-only invoice field; reused across builds instead of a new
  /// controller on every rebuild.
  final _invoiceDisplayController = TextEditingController();

  String? selectedSchool;
  String? selectedSchoolCusId;
  String? selectedFinancialYearName;
  String? selectedFinancialYearId;

  // Invoice
  String? _invoiceId;
  String? _invoiceNumber;
  String? _pendingAmount;

  PaymentMode selectedPaymentMode = PaymentMode.none;
  String? selectedPaymentModeApiValue;

  // ── Cash controllers ──────────────────────────────────────────────────────
  final _cashDepositedOnCtrl = TextEditingController();
  final _cashDepositedBranchCtrl = TextEditingController();
  String? _selectedCashBank;

  // ── Cheque controllers ────────────────────────────────────────────────────
  final _chequeNumberCtrl = TextEditingController();
  final _chequeDateCtrl = TextEditingController();
  final _chequeBankCtrl = TextEditingController();
  final _chequeDepositedDateCtrl = TextEditingController();
  String? _selectedChequeDepositBank;

  // ── NEFT controllers ──────────────────────────────────────────────────────
  final _neftTransactionCtrl = TextEditingController();

  // ── RTGS controllers (new) ─────────────────────────────────────────────────
  final _rtgsTransactionCtrl = TextEditingController();
  final _rtgsBankNameCtrl = TextEditingController();

  // ── Bank Transfer controllers (new) ─────────────────────────────────────────
  final _bankTransferTransactionCtrl = TextEditingController();
  final _bankTransferBankNameCtrl = TextEditingController();

  // ── UPI controllers (new) ───────────────────────────────────────────────────
  final _upiTransactionCtrl = TextEditingController();
  final _upiBankNameCtrl = TextEditingController();

  // ── PDC controllers ───────────────────────────────────────────────────────
  final _pdcChequeNoCtrl = TextEditingController();
  final _pdcChequeDateCtrl = TextEditingController();
  final _pdcChequeBankCtrl = TextEditingController();
  final _pdcChequeBranchCtrl = TextEditingController();

  // ── Image ─────────────────────────────────────────────────────────────────
  XFile? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  // ── Today's date string for ReceivedDate field ────────────────────────────
  String get _todayFormatted => DateFormat('dd/MM/yyyy').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(schoolnameProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _invoiceDisplayController.dispose();
    _amountController.dispose();
    _cashDepositedOnCtrl.dispose();
    _cashDepositedBranchCtrl.dispose();
    _chequeNumberCtrl.dispose();
    _chequeDateCtrl.dispose();
    _chequeBankCtrl.dispose();
    _chequeDepositedDateCtrl.dispose();
    _neftTransactionCtrl.dispose();
    _rtgsTransactionCtrl.dispose();
    _rtgsBankNameCtrl.dispose();
    _bankTransferTransactionCtrl.dispose();
    _bankTransferBankNameCtrl.dispose();
    _upiTransactionCtrl.dispose();
    _upiBankNameCtrl.dispose();
    _pdcChequeNoCtrl.dispose();
    _pdcChequeDateCtrl.dispose();
    _pdcChequeBankCtrl.dispose();
    _pdcChequeBranchCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // SCHOOL SELECTED
  // ============================================================
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

    // Re-fetch on year change too, in case invoices differ by year.
    ref.read(invoiceProvider.notifier).fetchForCustomer(selectedSchoolCusId!);
  }
  void _onPaymentModeChanged(String? mode) {
    if (mode == null) {
      setState(() => selectedPaymentMode = PaymentMode.none);
      return;
    }

    final normalized = _normalizeModeLabel(mode);

    setState(() {
      switch (normalized) {
        case 'cash':
          selectedPaymentMode = PaymentMode.cash;
          break;
        case 'cheque':
        case 'check':
          selectedPaymentMode = PaymentMode.cheque;
          break;
        case 'neft':
          selectedPaymentMode = PaymentMode.neft;
          break;
        case 'rtgs':
          selectedPaymentMode = PaymentMode.rtgs;
          break;
        case 'banktransfer':
          selectedPaymentMode = PaymentMode.bankTransfer;
          break;
        case 'upi':
          selectedPaymentMode = PaymentMode.upi;
          break;
        case 'pdc':
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
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (file != null) {
        setState(() {
          _selectedImage = file;
        });
      }
    } catch (e) {
      print("Image pick error: $e");
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
      case PaymentMode.cash:
        depositeddate = _cashDepositedOnCtrl.text;
        branchname = _cashDepositedBranchCtrl.text;
        depositedbankname = _selectedCashBank ?? '';
        break;

      case PaymentMode.cheque:
        chequenumber = _chequeNumberCtrl.text;
        chequedate = _chequeDateCtrl.text;
        depositeddate = _chequeDepositedDateCtrl.text;
        depositedbankname = _selectedChequeDepositBank ?? '';
        break;

      case PaymentMode.neft:
        transactionId = _neftTransactionCtrl.text;
        break;

      case PaymentMode.rtgs:
        transactionId = _rtgsTransactionCtrl.text;
        depositedbankname = _rtgsBankNameCtrl.text;
        break;

      case PaymentMode.bankTransfer:
        transactionId = _bankTransferTransactionCtrl.text;
        depositedbankname = _bankTransferBankNameCtrl.text;
        break;

      case PaymentMode.upi:
        transactionId = _upiTransactionCtrl.text;
        depositedbankname = _upiBankNameCtrl.text;
        break;

      case PaymentMode.pdc:
        chequenumber = _pdcChequeNoCtrl.text;
        depositeddate = _pdcChequeDateCtrl.text;
        branchname = _pdcChequeBranchCtrl.text;
        depositedbankname = _pdcChequeBankCtrl.text;
        break;

      default:
        break;
    }

    final payload = {
      'InvoiceID': _invoiceId ?? '0',
      'CustomerId': selectedSchoolCusId ?? '0',
      'FinancialYear': selectedFinancialYearName ?? '',
      'InvoiceNumber': _invoiceNumber ?? 'No Invoices Found',
      'Received': _amountController.text,
      'ReceivedDate': _todayFormatted,
      'PaymentMode': selectedPaymentModeApiValue ?? selectedPaymentMode.apiValue,
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

    return payload;
  }

  Future<void> _onSubmit() async {
    final amount = _amountController.text.trim();
    final financialYear = selectedFinancialYearName ?? '';

    // Common validations
    if (selectedSchoolCusId == null || selectedSchoolCusId == '0') {
      _showAlert('Select your school name');
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
      _showAlert('Select mode of payment');
      return;
    }

    switch (selectedPaymentMode) {
      case PaymentMode.cash:
        final depositedDate = _cashDepositedOnCtrl.text.trim();
        final branch = _cashDepositedBranchCtrl.text.trim();

        if (depositedDate.isEmpty) {
          _showAlert('Enter deposited date');
          return;
        }

        if (_selectedCashBank == null || _selectedCashBank!.isEmpty) {
          _showAlert('Select bank');
          return;
        }

        if (branch.isEmpty) {
          _showAlert('Enter deposited branch');
          return;
        }
        break;

      case PaymentMode.cheque:
        final chequeNo = _chequeNumberCtrl.text.trim();
        final chequeDate = _chequeDateCtrl.text.trim();
        final chequeBank = _chequeBankCtrl.text.trim();
        final depositedDate = _chequeDepositedDateCtrl.text.trim();

        if (chequeNo.isEmpty) {
          _showAlert('Enter cheque number');
          return;
        }

        if (chequeDate.isEmpty) {
          _showAlert('Enter cheque date');
          return;
        }

        if (chequeBank.isEmpty) {
          _showAlert('Enter cheque bank');
          return;
        }

        if (_selectedChequeDepositBank == null || _selectedChequeDepositBank!.isEmpty) {
          _showAlert('Select bank');
          return;
        }

        final dCheque = _parseDate(chequeDate);
        final dDeposited = _parseDate(
          depositedDate.isEmpty ? chequeDate : depositedDate,
        );

        if (dCheque == null || dDeposited == null) {
          _showAlert('Invalid date format');
          return;
        }

        if (depositedDate.isNotEmpty && dDeposited.isBefore(dCheque)) {
          _showAlert('Deposited date should be after cheque date');
          return;
        }
        break;

      case PaymentMode.neft:
        if (_neftTransactionCtrl.text.trim().isEmpty) {
          _showAlert('Enter NEFT transaction number');
          return;
        }
        break;

      case PaymentMode.rtgs:
        if (_rtgsTransactionCtrl.text.trim().isEmpty) {
          _showAlert('Enter RTGS reference number');
          return;
        }
        if (_rtgsBankNameCtrl.text.trim().isEmpty) {
          _showAlert('Enter bank name');
          return;
        }
        break;

      case PaymentMode.bankTransfer:
        if (_bankTransferTransactionCtrl.text.trim().isEmpty) {
          _showAlert('Enter reference number');
          return;
        }
        if (_bankTransferBankNameCtrl.text.trim().isEmpty) {
          _showAlert('Enter bank name');
          return;
        }
        break;

      case PaymentMode.upi:
        if (_upiTransactionCtrl.text.trim().isEmpty) {
          _showAlert('Enter UPI transaction / reference ID');
          return;
        }
        break;

      case PaymentMode.pdc:
        if (_pdcChequeNoCtrl.text.trim().isEmpty) {
          _showAlert('Enter cheque number');
          return;
        }

        if (_pdcChequeDateCtrl.text.trim().isEmpty) {
          _showAlert('Enter cheque date');
          return;
        }

        if (_pdcChequeBankCtrl.text.trim().isEmpty) {
          _showAlert('Enter cheque bank');
          return;
        }

        if (_pdcChequeBranchCtrl.text.trim().isEmpty) {
          _showAlert('Enter cheque bank branch');
          return;
        }
        break;

      case PaymentMode.none:
        return;
    }

    try {
      final payload = _buildPayload();
      final loginState = await ref.read(loginProvider.future);
      final userId = loginState?.employeeId.toString();

      if (userId == null || userId.isEmpty) {
        _showAlert('User login details not found');
        return;
      }

      final success = await ref
          .read(createPaymentProvider.notifier)
          .createPayment(
        invoiceID: payload['InvoiceID'] ?? '',
        customerId: payload['CustomerId'] ?? '',
        financialYear: payload['FinancialYear'] ?? '',
        invoiceNumber: payload['InvoiceNumber'] ?? '',
        received: payload['Received'] ?? '',
        receivedDate: payload['ReceivedDate'] ?? '',
        paymentMode: payload['PaymentMode'] ?? '',
        createdBy: userId,
        cashRecdDate: payload['CashRecdDate'] ?? '',
        chequeDate: payload['ChequeDate'] ?? '',
        chequeNumber: payload['ChequeNumber'] ?? '',
        neftDetails: payload['NEFTDetails'] ?? '',
        depositedBank: payload['DepositedBank'] ?? '',
        depositedBranch: payload['DepositedBranch'] ?? '',
        depositedBy: userId,
        depositedDate: payload['DepositedDate'] ?? '',
        imageFile: _selectedImage,
      );

      if (success) {
        final result = ref.read(createPaymentProvider).value;
        _showSuccessAlert(
          result?.resultMessage ?? 'Payment successfully updated',
        );
      } else {
        final err = ref.read(createPaymentProvider).error;
        _showAlert(
          err?.toString() ?? 'Payment submission failed',
        );
      }
    } catch (e) {
      _showAlert("Error: $e");
    }
  }
  // ── Amount helpers ──────────────────────────────────────────────────────
  static double? _money(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    return cleaned.isEmpty ? null : double.tryParse(cleaned);
  }

  static String _rupees(double v) => NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: v == v.roundToDouble() ? 0 : 2,
      ).format(v);

  void _fillFullPending() {
    final pending = _money(_pendingAmount);
    if (pending == null) return;
    HapticFeedback.selectionClick();
    final text = pending == pending.roundToDouble() ? pending.toInt().toString() : pending.toStringAsFixed(2);
    _amountController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schoolnameAsync = ref.watch(schoolnameProvider);
    final financialAsync = ref.watch(financialyearProvider);
    final invoiceAsync = ref.watch(invoiceProvider);
    final paymentModeAsync = ref.watch(paymentModeProvider);
    final submitState = ref.watch(createPaymentProvider);

    final bool isSubmitting = submitState.isLoading;

    final bool hasValidInvoice =
        _invoiceId != null && _invoiceId != '0' && _invoiceId!.isNotEmpty;
    final bool schoolIsSelected =
        selectedSchoolCusId != null && selectedSchoolCusId!.isNotEmpty;
    final bool yearIsSelected = (selectedFinancialYearName ?? '').isNotEmpty;

    // Keep the invoice fields in step with the loaded invoices.
    _syncInvoice(invoiceAsync, schoolIsSelected);

    final side = formSidePadding(context, 16);

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
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: _pageBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        // iPad: centred 640 pt column (see form_width.dart).
                        padding: EdgeInsets.fromLTRB(side, 20, side, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Live summary ──
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _amountController,
                              builder: (_, v, __) => _SummaryHero(
                                school: selectedSchool,
                                year: selectedFinancialYearName,
                                invoiceNumber: hasValidInvoice ? _invoiceNumber : null,
                                pending: hasValidInvoice ? _money(_pendingAmount) : null,
                                received: _money(v.text),
                                loadingInvoice: schoolIsSelected && invoiceAsync.isLoading,
                                noInvoice: schoolIsSelected &&
                                    !invoiceAsync.isLoading &&
                                    !invoiceAsync.hasError &&
                                    !hasValidInvoice,
                                rupees: _rupees,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ── 1. School & year ──
                            _StepCard(
                              step: 1,
                              title: "School & financial year",
                              subtitle: "Whose payment are you recording?",
                              done: schoolIsSelected && yearIsSelected,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _schoolDropdown(schoolnameAsync),
                                  const SizedBox(height: 14),
                                  _yearDropdown(financialAsync),
                                  if (schoolIsSelected && invoiceAsync.hasError) ...[
                                    const SizedBox(height: 14),
                                    DropdownError(
                                      label: "Invoice Details",
                                      onRetry: () => ref
                                          .read(invoiceProvider.notifier)
                                          .fetchForCustomer(selectedSchoolCusId!),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ── 2. Amount ──
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _amountController,
                              builder: (_, v, __) => _StepCard(
                                step: 2,
                                title: "Amount received",
                                subtitle: "How much did the school pay?",
                                done: (_money(v.text) ?? 0) > 0,
                                child: _AmountInput(
                                  controller: _amountController,
                                  pending: hasValidInvoice ? _money(_pendingAmount) : null,
                                  onFillPending: _fillFullPending,
                                  rupees: _rupees,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ── 3. Payment mode ──
                            _StepCard(
                              step: 3,
                              title: "Mode of payment",
                              subtitle: "Pick how the money was paid, then fill its details.",
                              done: selectedPaymentMode != PaymentMode.none,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _paymentModes(paymentModeAsync),
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 260),
                                    curve: Curves.easeOutCubic,
                                    alignment: Alignment.topCenter,
                                    child: selectedPaymentMode == PaymentMode.none
                                        ? const SizedBox(width: double.infinity)
                                        : Padding(
                                            padding: const EdgeInsets.only(top: 18),
                                            child: KeyedSubtree(
                                              key: ValueKey(selectedPaymentMode),
                                              child: _buildPaymentForm(),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ── 4. Attachment ──
                            _StepCard(
                              step: 4,
                              title: "Receipt photo",
                              subtitle: "Optional · a photo of the cheque, slip or receipt.",
                              done: _selectedImage != null,
                              optional: true,
                              child: _ImagePickerTile(
                                selectedImage: _selectedImage,
                                onCamera: () => _pickImage(ImageSource.camera),
                                onGallery: () => _pickImage(ImageSource.gallery),
                                onReplace: _showImageSourceDialog,
                                onRemove: _removeImage,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Sticky submit bar ──
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _amountController,
                      builder: (_, v, __) => _SubmitBar(
                        sidePadding: side,
                        amount: _money(v.text),
                        rupees: _rupees,
                        isSubmitting: isSubmitting,
                        enabled: !isSubmitting && hasValidInvoice,
                        hint: isSubmitting ||
                                hasValidInvoice ||
                                (schoolIsSelected && invoiceAsync.isLoading)
                            ? null
                            : schoolIsSelected
                                ? "This school has no pending invoice to record a collection against"
                                : "Select a school to load its invoice",
                        onSubmit: _onSubmit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Copies the first loaded invoice into the form state (after the frame,
  /// as before), or clears it when the school has none.
  void _syncInvoice(AsyncValue<List<dynamic>> invoiceAsync, bool schoolIsSelected) {
    if (!schoolIsSelected) return;
    final invoices = invoiceAsync.value;
    if (invoiceAsync.isLoading || invoices == null) return;
    if (invoices.isEmpty) {
      if (_invoiceId != null || _invoiceNumber != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _invoiceId = null;
            _invoiceNumber = null;
            _pendingAmount = null;
          });
        });
      }
      return;
    }
    final first = invoices.first;
    final newInvoiceId = first.InvoiceId.toString();
    final String newInvoiceNumber = first.InvoiceNumber;
    final String newPendingAmount = first.PendingAmount;
    if (_invoiceId != newInvoiceId ||
        _invoiceNumber != newInvoiceNumber ||
        _pendingAmount != newPendingAmount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _invoiceId = newInvoiceId;
          _invoiceNumber = newInvoiceNumber;
          _pendingAmount = newPendingAmount;
        });
      });
    }
  }

  Widget _schoolDropdown(AsyncValue<List<dynamic>> schoolnameAsync) {
    if (!schoolnameAsync.hasValue && schoolnameAsync.isLoading) {
      return const DropdownSkeleton(label: "Select School");
    }
    if (schoolnameAsync.hasError && !schoolnameAsync.hasValue) {
      return DropdownError(
        label: "Select School",
        onRetry: () => ref.read(schoolnameProvider.notifier).refresh(),
      );
    }
    return SearchableDropdown<dynamic>(
      key: const ValueKey('school_dropdown'),
      label: "Select School",
      hint: "Choose a school",
      value: selectedSchoolCusId,
      items: schoolnameAsync.value ?? [],
      itemLabel: (e) => e.CustomerName ?? "",
      itemValue: (e) => e.CustomerID ?? "",
      showSearchButtonOnEmpty: true,
      isLoading: schoolnameAsync.isLoading,
      onOpen: () => ref.read(schoolnameProvider.notifier).refresh(),
      onSearch: (query) => ref.read(schoolnameProvider.notifier).searchSchool(query),
      onChanged: (value) {
        if (value == null) return;
        try {
          final match = (schoolnameAsync.value ?? []).firstWhere((e) => e.CustomerID == value);
          _onSchoolSelected(match.CustomerName, match.CustomerID);
        } catch (_) {
          _showAlert('Could not select that school, please try again');
        }
      },
    );
  }

  Widget _yearDropdown(AsyncValue<List<Financialyearmodel>> financialAsync) => financialAsync.when(
        loading: () => const DropdownSkeleton(label: "Select Financial Year"),
        error: (e, _) => DropdownError(
          label: "Select Financial Year",
          onRetry: () => ref.read(financialyearProvider.notifier).refresh(),
        ),
        data: (years) => SearchableDropdown<Financialyearmodel>(
          label: "Select Financial Year",
          hint: "Choose a year",
          value: selectedFinancialYearName,
          items: years,
          itemLabel: (e) => e.label,
          itemValue: (e) => e.label,
          onChanged: (value) {
            if (value == null) return;
            final selectedYear = years.firstWhere((e) => e.label == value);
            _onFinancialYearChanged(selectedYear.label, selectedYear.id.toString());
          },
        ),
      );

  Widget _paymentModes(AsyncValue<List<dynamic>> paymentModeAsync) => paymentModeAsync.when(
        loading: () => const DropdownSkeleton(label: "Mode of Payment"),
        error: (e, _) => DropdownError(
          label: "Mode of Payment",
          onRetry: () => ref.read(paymentModeProvider.notifier).refresh(),
        ),
        data: (modes) {
          if (modes.isEmpty) {
            return const _InactiveDropdownHint(hint: "No payment modes found");
          }
          return LayoutBuilder(builder: (context, box) {
            final cols = box.maxWidth >= 520 ? 4 : 3;
            const gap = 10.0;
            final w = (box.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final m in modes)
                  SizedBox(
                    width: w,
                    child: _ModeTile(
                      label: m.label,
                      icon: _modeIcon(m.label),
                      selected: selectedPaymentModeApiValue == m.value.toString(),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => selectedPaymentModeApiValue = m.value.toString());
                        _onPaymentModeChanged(m.label);
                      },
                    ),
                  ),
              ],
            );
          });
        },
      );

  static IconData _modeIcon(String label) {
    switch (_normalizeModeLabel(label)) {
      case 'cash':
        return Icons.payments_rounded;
      case 'cheque':
      case 'check':
        return Icons.edit_document;
      case 'pdc':
        return Icons.event_note_rounded;
      case 'neft':
      case 'rtgs':
        return Icons.account_balance_rounded;
      case 'banktransfer':
        return Icons.swap_horiz_rounded;
      case 'upi':
        return Icons.qr_code_2_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  Widget _buildPaymentForm() {
    switch (selectedPaymentMode) {
      case PaymentMode.cash:
        return CashPaymentForm(
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
          selectedDepositBank: _selectedChequeDepositBank,
          onDepositBankChanged: (v) =>
              setState(() => _selectedChequeDepositBank = v),
        );
      case PaymentMode.neft:
        return NeftPaymentForm(neftTransactionController: _neftTransactionCtrl);
      case PaymentMode.rtgs:
        return RtgsPaymentForm(
          rtgsTransactionController: _rtgsTransactionCtrl,
          rtgsBankNameController: _rtgsBankNameCtrl,
        );
      case PaymentMode.bankTransfer:
        return BankTransferPaymentForm(
          bankTransferTransactionController: _bankTransferTransactionCtrl,
          bankTransferBankNameController: _bankTransferBankNameCtrl,
        );
      case PaymentMode.upi:
        return UpiPaymentForm(
          upiTransactionController: _upiTransactionCtrl,
          upiBankNameController: _upiBankNameCtrl,
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
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}


const _pageBg = Color(0xFFF3F6FB);
const _ink = Color(0xFF1B2638);
const _muted = Color(0xFF6B7385);
const _line = Color(0xFFE3E8F1);
const _cardShadow = [
  BoxShadow(color: Color(0x0F1B2638), blurRadius: 18, offset: Offset(0, 6)),
  BoxShadow(color: Color(0x081B2638), blurRadius: 3, offset: Offset(0, 1)),
];

/// Gradient card at the top: who is paying, the invoice, and a live
/// "paid vs pending" bar as the amount is typed.
class _SummaryHero extends StatelessWidget {
  final String? school;
  final String? year;
  final String? invoiceNumber;
  final double? pending;
  final double? received;
  final bool loadingInvoice;
  final bool noInvoice;
  final String Function(double) rupees;

  const _SummaryHero({
    required this.school,
    required this.year,
    required this.invoiceNumber,
    required this.pending,
    required this.received,
    required this.loadingInvoice,
    required this.noInvoice,
    required this.rupees,
  });

  @override
  Widget build(BuildContext context) {
    final white70 = Colors.white.withValues(alpha: 0.75);
    final p = pending;
    final r = received ?? 0;
    final ratio = p == null || p <= 0 ? 0.0 : (r / p).clamp(0.0, 1.0);

    String status;
    IconData statusIcon;
    Color statusColor = Colors.white;
    if (p == null) {
      status = school == null
          ? 'Choose a school to see its pending invoice'
          : loadingInvoice
              ? 'Loading invoice…'
              : noInvoice
                  ? 'No pending invoice for this school'
                  : 'Invoice not loaded';
      statusIcon = loadingInvoice ? Icons.hourglass_top_rounded : Icons.info_outline_rounded;
    } else if (r <= 0) {
      status = 'Enter the amount received';
      statusIcon = Icons.edit_rounded;
    } else if (r > p) {
      status = '${rupees(r - p)} more than the pending amount';
      statusIcon = Icons.warning_amber_rounded;
      statusColor = const Color(0xFFFFD08A);
    } else if (r == p) {
      status = 'Clears this invoice in full';
      statusIcon = Icons.verified_rounded;
      statusColor = const Color(0xFF9BF0C3);
    } else {
      status = '${rupees(p - r)} will still be pending';
      statusIcon = Icons.timelapse_rounded;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF233A63), AppColors.primary, Color(0xFF5E7DB4)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x33233A63), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('COLLECTING FROM',
                        style: TextStyle(fontSize: 10.5, letterSpacing: 1.1, fontWeight: FontWeight.w700, color: white70)),
                    const SizedBox(height: 2),
                    Text(school ?? 'No school selected',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16.5, height: 1.25, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          if (invoiceNumber != null || year != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (invoiceNumber != null) _heroChip(Icons.receipt_long_rounded, invoiceNumber!),
                if (year != null) _heroChip(Icons.calendar_month_rounded, 'FY $year'),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _heroAmount('Pending', p == null ? '—' : rupees(p), white70)),
              Container(width: 1, height: 34, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(width: 14),
              Expanded(child: _heroAmount('Collecting now', r > 0 ? rupees(r) : '—', white70)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Container(color: Colors.white.withValues(alpha: 0.18)),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: ratio),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => FractionallySizedBox(
                      widthFactor: v,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF7FE3B0), Color(0xFF3CCB8A)]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(statusIcon, size: 15, color: statusColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(status,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 5),
            Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      );

  Widget _heroAmount(String label, String value, Color labelColor) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: labelColor)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: const TextStyle(fontSize: 22, height: 1.15, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      );
}

/// White section card with a numbered badge that turns into a tick once
/// the step is filled in.
class _StepCard extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final bool done;
  final bool optional;
  final Widget child;

  const _StepCard({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.child,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: _cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: done ? AppColors.success : AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                    child: done
                        ? const Icon(Icons.check_rounded, key: ValueKey('done'), size: 17, color: Colors.white)
                        : Text('$step',
                            key: const ValueKey('n'),
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 12.5, height: 1.3, color: _muted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );
}

/// Large ₹ amount field with a "Full pending" shortcut.
class _AmountInput extends StatelessWidget {
  final TextEditingController controller;
  final double? pending;
  final VoidCallback onFillPending;
  final String Function(double) rupees;

  const _AmountInput({
    required this.controller,
    required this.pending,
    required this.onFillPending,
    required this.rupees,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _ink, letterSpacing: 0.5),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _muted.withValues(alpha: 0.35)),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 16, right: 6),
                child: Text('₹', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              filled: true,
              fillColor: _pageBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
              ),
            ),
          ),
          if (pending != null && pending! > 0) ...[
            const SizedBox(height: 10),
            ActionChip(
              onPressed: onFillPending,
              avatar: const Icon(Icons.bolt_rounded, size: 16, color: AppColors.primary),
              label: Text('Full pending · ${rupees(pending!)}'),
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
              backgroundColor: AppColors.primary.withValues(alpha: 0.08),
              side: BorderSide.none,
              shape: const StadiumBorder(),
            ),
          ],
        ],
      );
}

/// One selectable payment mode in the grid.
class _ModeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTile({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 78,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? AppColors.primary : _line, width: 1.4),
              boxShadow: selected
                  ? const [BoxShadow(color: Color(0x404F6693), blurRadius: 12, offset: Offset(0, 5))]
                  : null,
            ),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 24, color: selected ? Colors.white : AppColors.primary),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(label,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : _ink,
                              )),
                        ),
                      ],
                    ),
                  ),
                ),
                if (selected)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(Icons.check_circle_rounded, size: 16, color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      );
}

/// Bottom bar: why Submit is disabled (if it is) and the submit button
/// with the amount on it.
class _SubmitBar extends StatelessWidget {
  final double sidePadding;
  final double? amount;
  final String Function(double) rupees;
  final bool isSubmitting;
  final bool enabled;
  final String? hint;
  final VoidCallback onSubmit;

  const _SubmitBar({
    required this.sidePadding,
    required this.amount,
    required this.rupees,
    required this.isSubmitting,
    required this.enabled,
    required this.hint,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final a = amount;
    return Container(
      padding: EdgeInsets.fromLTRB(sidePadding, 12, sidePadding, 12 + MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x141B2638), blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hint != null) ...[
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 15, color: _muted),
                const SizedBox(width: 6),
                Expanded(child: Text(hint!, style: const TextStyle(fontSize: 12.5, color: _muted))),
              ],
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: enabled
                    ? const LinearGradient(colors: [Color(0xFF233A63), AppColors.primary])
                    : null,
                color: enabled ? null : AppColors.primary.withValues(alpha: 0.35),
                boxShadow: enabled
                    ? const [BoxShadow(color: Color(0x40233A63), blurRadius: 14, offset: Offset(0, 6))]
                    : null,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: enabled ? onSubmit : null,
                  child: Center(
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 20, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                a != null && a > 0 ? 'Submit ${rupees(a)}' : 'Submit Collection',
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Camera / gallery buttons, or the chosen photo with Replace and Remove.
class _ImagePickerTile extends StatelessWidget {
  final XFile? selectedImage;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  const _ImagePickerTile({
    required this.selectedImage,
    required this.onCamera,
    required this.onGallery,
    required this.onReplace,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final img = selectedImage;
    if (img != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Image.file is not supported on Web; the picked path there is a blob URL.
            kIsWeb
                ? Image.network(img.path, width: double.infinity, height: 190, fit: BoxFit.cover)
                : Image.file(File(img.path), width: double.infinity, height: 190, fit: BoxFit.cover),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 24, 12, 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0x99000000)],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF9BF0C3)),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text('Photo attached',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                    _overlayButton(Icons.autorenew_rounded, 'Replace', onReplace),
                    const SizedBox(width: 8),
                    _overlayButton(Icons.delete_outline_rounded, 'Remove', onRemove),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    Widget source(IconData icon, String label, VoidCallback onTap) => Expanded(
          child: Material(
            color: _pageBg,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Container(
                height: 92,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _line, width: 1.4),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
                  ],
                ),
              ),
            ),
          ),
        );
    return Row(
      children: [
        source(Icons.photo_camera_rounded, 'Take photo', onCamera),
        const SizedBox(width: 12),
        source(Icons.photo_library_rounded, 'From gallery', onGallery),
      ],
    );
  }

  Widget _overlayButton(IconData icon, String label, VoidCallback onTap) => Material(
        color: Colors.white.withValues(alpha: 0.2),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: Colors.white),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ],
            ),
          ),
        ),
      );
}
