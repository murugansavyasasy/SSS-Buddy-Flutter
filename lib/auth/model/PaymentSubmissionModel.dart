import 'package:intl/intl.dart';

/// Models for Payment Submissions (/api/mobile/payment-submissions): an
/// account manager reports money a school paid against a pending proforma
/// and uploads the proof; accounts later matches it with the bank and
/// receipts it. Amounts arrive as strings ("19175.00") or numbers.

dynamic _pick(Map m, List<String> keys) {
  for (final k in keys) {
    if (m.containsKey(k) && m[k] != null) return m[k];
  }
  return null;
}

String _str(Map m, List<String> keys, [String fallback = '']) {
  final v = _pick(m, keys);
  return v == null ? fallback : v.toString();
}

int _int(Map m, List<String> keys, [int fallback = 0]) {
  final v = _pick(m, keys);
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

double _amount(Map m, List<String> keys) => parseAmount(_pick(m, keys));

DateTime? _date(Map m, List<String> keys) {
  final v = _pick(m, keys);
  if (v == null) return null;
  return DateTime.tryParse(v.toString())?.toLocal();
}

Map<String, dynamic>? _map(dynamic v) => v is Map ? v.cast<String, dynamic>() : null;

/// "19175.00", 19175, null → 19175.0 (0 when missing or not a number).
double parseAmount(dynamic v) {
  if (v is num) return v.toDouble();
  if (v == null) return 0;
  return double.tryParse(v.toString().replaceAll(',', '').trim()) ?? 0;
}

final _rupee = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _rupeePaise = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

/// ₹ with Indian grouping: 1917500 → "₹19,17,500"; paise only when present.
String formatRupees(double v) =>
    (v - v.truncateToDouble()).abs() < 0.005 ? _rupee.format(v) : _rupeePaise.format(v);

/// Dates are sent as YYYY-MM-DD.
String apiDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// "20 Nov 2026".
String psDate(DateTime? d) => d == null ? '' : DateFormat('d MMM yyyy').format(d);

/// "24 Nov 2026, 10:41 AM".
String psDateTime(DateTime? d) => d == null ? '' : DateFormat('d MMM yyyy, h:mm a').format(d);

/// "upi" → "UPI", "bank_transfer" → "Bank transfer".
String paymentModeLabel(String v) {
  final s = v.trim();
  if (s.isEmpty) return '';
  const upper = {'upi', 'neft', 'rtgs', 'imps'};
  if (upper.contains(s.toLowerCase())) return s.toUpperCase();
  final words = s.replaceAll(RegExp(r'[_\-]+'), ' ').toLowerCase();
  return words[0].toUpperCase() + words.substring(1);
}

/// What the status chip shows.
enum SubmissionStage { awaitingBank, foundInBank, receipted, rejected, withdrawn }

extension SubmissionStageX on SubmissionStage {
  String get label => switch (this) {
        SubmissionStage.awaitingBank => 'Awaiting bank',
        SubmissionStage.foundInBank => 'Found in bank',
        SubmissionStage.receipted => 'Receipted',
        SubmissionStage.rejected => 'Rejected',
        SubmissionStage.withdrawn => 'Withdrawn',
      };
}

/// The bank credit matched to a submission.
class PsBankTxn {
  final DateTime? valueDate;
  final double amount;
  final String refNo;

  /// "suggested" = found, waiting for accounts to confirm.
  final String status;

  const PsBankTxn({this.valueDate, this.amount = 0, this.refNo = '', this.status = ''});

  factory PsBankTxn.fromJson(Map<String, dynamic> j) => PsBankTxn(
        valueDate: _date(j, ['valueDate', 'txnDate', 'date']),
        amount: _amount(j, ['amount', 'creditAmount']),
        refNo: _str(j, ['refNo', 'referenceNumber', 'utr']),
        status: _str(j, ['status']),
      );
}

/// What the AI read from a proof (POST /payment-submissions/extract).
class PsExtraction {
  final int id;

  /// "ok", "not_a_proof" or "failed".
  final String status;
  final String paymentMode;
  final String txnRef;
  final DateTime? txnDate;
  final double amount;
  final String payerName;
  final String payerBank;
  final String payeeName;
  final String payeeAccount;
  final String txnStatus;
  final double confidence;
  final List<String> warnings;
  final String proofUrl;
  final String error;

  const PsExtraction({
    this.id = 0,
    this.status = '',
    this.paymentMode = '',
    this.txnRef = '',
    this.txnDate,
    this.amount = 0,
    this.payerName = '',
    this.payerBank = '',
    this.payeeName = '',
    this.payeeAccount = '',
    this.txnStatus = '',
    this.confidence = 0,
    this.warnings = const [],
    this.proofUrl = '',
    this.error = '',
  });

  factory PsExtraction.fromJson(Map<String, dynamic> j) {
    final w = _pick(j, ['warnings']);
    final d = _str(j, ['txnDate']);
    return PsExtraction(
      id: _int(j, ['id', 'extractionId']),
      status: _str(j, ['status'], 'ok').toLowerCase(),
      paymentMode: _str(j, ['paymentMode']),
      txnRef: _str(j, ['txnRef', 'referenceNumber']),
      // Date only: parsed as a local calendar day.
      txnDate: d.isEmpty ? null : DateTime.tryParse(d.length >= 10 ? d.substring(0, 10) : d),
      amount: _amount(j, ['amount']),
      payerName: _str(j, ['payerName']),
      payerBank: _str(j, ['payerBank']),
      payeeName: _str(j, ['payeeName']),
      payeeAccount: _str(j, ['payeeAccount']),
      txnStatus: _str(j, ['txnStatus']),
      confidence: parseAmount(_pick(j, ['confidence'])),
      warnings: w is List ? w.map((e) => e.toString()).where((s) => s.isNotEmpty).toList() : const [],
      proofUrl: _str(j, ['proofUrl', 'url']),
      error: _str(j, ['error', 'message']),
    );
  }

  bool get isOk => status == 'ok';
  bool get notAProof => status == 'not_a_proof';

  /// Payment mode for the form: the AI's cash_deposit is the cash mode.
  String get formMode => paymentMode == 'cash_deposit' ? 'cash' : paymentMode;
}

/// A school the user can submit a payment for (Step 2).
class PsCustomer {
  final int id;
  final String companyName;
  final String dashboardId;
  final String customerCode;
  final int proformaCount;
  final double pendingTotal;

  const PsCustomer({
    required this.id,
    required this.companyName,
    this.dashboardId = '',
    this.customerCode = '',
    this.proformaCount = 0,
    this.pendingTotal = 0,
  });

  factory PsCustomer.fromJson(Map<String, dynamic> j) => PsCustomer(
        id: _int(j, ['id', 'customerId']),
        companyName: _str(j, ['companyName', 'customerName', 'name']),
        dashboardId: _str(j, ['dashboardId']),
        customerCode: _str(j, ['customerCode']),
        proformaCount: _int(j, ['proformaCount']),
        pendingTotal: _amount(j, ['pendingTotal']),
      );
}

/// An open proforma of a school (Step 3).
class PsProforma {
  final int id;
  final String invoiceNumber;
  final String invoiceName;
  final DateTime? invoiceDate;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final double total;
  final double pendingAmount;

  /// Already submitted and awaiting the bank.
  final double submittedPending;

  /// The most a new submission can be.
  final double claimable;

  const PsProforma({
    required this.id,
    required this.invoiceNumber,
    this.invoiceName = '',
    this.invoiceDate,
    this.periodStart,
    this.periodEnd,
    this.total = 0,
    this.pendingAmount = 0,
    this.submittedPending = 0,
    this.claimable = 0,
  });

  factory PsProforma.fromJson(Map<String, dynamic> j) => PsProforma(
        id: _int(j, ['id', 'invoiceId']),
        invoiceNumber: _str(j, ['invoiceNumber']),
        invoiceName: _str(j, ['invoiceName']),
        invoiceDate: _date(j, ['invoiceDate']),
        periodStart: _date(j, ['periodStart']),
        periodEnd: _date(j, ['periodEnd']),
        total: _amount(j, ['total']),
        pendingAmount: _amount(j, ['pendingAmount']),
        submittedPending: _amount(j, ['submittedPending']),
        claimable: _amount(j, ['claimable']),
      );

  /// "Jun–Aug 2026" (or "Nov 2026–Jan 2027" across years).
  String get period {
    final s = periodStart, e = periodEnd;
    if (s == null || e == null) return '';
    if (s.year == e.year) {
      return '${DateFormat('MMM').format(s)}–${DateFormat('MMM yyyy').format(e)}';
    }
    return '${DateFormat('MMM yyyy').format(s)}–${DateFormat('MMM yyyy').format(e)}';
  }
}

/// A payment submission (list row and detail).
class PaymentSubmission {
  final int id;
  final int customerId;
  final String customerName;
  final int invoiceId;
  final String invoiceNumber;

  /// "active" once the proforma was approved as a tax invoice.
  final String invoiceStatus;
  final double amount;
  final DateTime? paymentDate;
  final String paymentMethod;
  final String referenceNumber;
  final String payerBank;
  final String notes;

  /// pending, done, rejected or withdrawn.
  final String status;
  final String receiptNumber;
  final String reviewNotes;
  final String reviewedByName;
  final DateTime? reviewedAt;
  final DateTime? submittedAt;
  final String submittedBy;
  final String submittedByName;

  /// "app" or "web".
  final String source;
  final PsBankTxn? bankTxn;
  final List<String> supportingDocs;
  final PsExtraction? extraction;

  const PaymentSubmission({
    required this.id,
    this.customerId = 0,
    this.customerName = '',
    this.invoiceId = 0,
    this.invoiceNumber = '',
    this.invoiceStatus = '',
    this.amount = 0,
    this.paymentDate,
    this.paymentMethod = '',
    this.referenceNumber = '',
    this.payerBank = '',
    this.notes = '',
    this.status = 'pending',
    this.receiptNumber = '',
    this.reviewNotes = '',
    this.reviewedByName = '',
    this.reviewedAt,
    this.submittedAt,
    this.submittedBy = '',
    this.submittedByName = '',
    this.source = '',
    this.bankTxn,
    this.supportingDocs = const [],
    this.extraction,
  });

  factory PaymentSubmission.fromJson(Map<String, dynamic> j) {
    final bank = _map(_pick(j, ['bankTxn', 'bankTransaction']));
    final ext = _map(_pick(j, ['extraction']));
    final docs = _pick(j, ['supportingDocs', 'proofUrls', 'proofs']);
    final d = _str(j, ['paymentDate']);
    return PaymentSubmission(
      id: _int(j, ['id']),
      customerId: _int(j, ['customerId']),
      customerName: _str(j, ['customerName', 'companyName', 'schoolName']),
      invoiceId: _int(j, ['invoiceId']),
      invoiceNumber: _str(j, ['invoiceNumber']),
      invoiceStatus: _str(j, ['invoiceStatus']),
      amount: _amount(j, ['amount']),
      paymentDate: d.isEmpty ? null : DateTime.tryParse(d.length >= 10 ? d.substring(0, 10) : d),
      paymentMethod: _str(j, ['paymentMethod', 'paymentMode']),
      referenceNumber: _str(j, ['referenceNumber', 'txnRef']),
      payerBank: _str(j, ['payerBank']),
      notes: _str(j, ['notes']),
      status: _str(j, ['status'], 'pending').toLowerCase(),
      receiptNumber: _str(j, ['receiptNumber']),
      reviewNotes: _str(j, ['reviewNotes']),
      reviewedByName: _str(j, ['reviewedByName']),
      reviewedAt: _date(j, ['reviewedAt']),
      submittedAt: _date(j, ['submittedAt', 'createdAt']),
      submittedBy: _str(j, ['submittedBy', 'submittedById']),
      submittedByName: _str(j, ['submittedByName']),
      source: _str(j, ['source']),
      bankTxn: bank == null ? null : PsBankTxn.fromJson(bank),
      supportingDocs: docs is List
          ? [
              for (final e in docs)
                if (e is Map)
                  _str(e, ['url', 'fileUrl', 'proofUrl', 'path'])
                else
                  e.toString(),
            ].where((s) => s.isNotEmpty).toList()
          : const [],
      extraction: ext == null ? null : PsExtraction.fromJson(ext),
    );
  }

  SubmissionStage get stage => switch (status) {
        'done' => SubmissionStage.receipted,
        'rejected' => SubmissionStage.rejected,
        'withdrawn' => SubmissionStage.withdrawn,
        _ => bankTxn == null ? SubmissionStage.awaitingBank : SubmissionStage.foundInBank,
      };

  bool get isTaxInvoice => invoiceStatus.toLowerCase() == 'active';

  /// Only the person who submitted it can withdraw, and only while pending.
  bool canWithdraw(String userId) =>
      status == 'pending' && userId.isNotEmpty && submittedBy == userId;
}

/// One page of GET /payment-submissions.
class PsPage {
  final List<PaymentSubmission> items;
  final int page;
  final int totalPages;

  const PsPage({required this.items, required this.page, required this.totalPages});
}

/// Body for POST /payment-submissions.
class SubmitPaymentRequest {
  final int customerId;
  final int invoiceId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String referenceNumber;
  final String payerBank;
  final String notes;
  final List<String> proofUrls;
  final int? extractionId;

  const SubmitPaymentRequest({
    required this.customerId,
    required this.invoiceId,
    required this.amount,
    required this.paymentDate,
    this.paymentMethod = '',
    this.referenceNumber = '',
    this.payerBank = '',
    this.notes = '',
    this.proofUrls = const [],
    this.extractionId,
  });

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'invoiceId': invoiceId,
        // Whole rupees go as an int (20650), paise as a decimal.
        'amount': amount == amount.truncateToDouble() ? amount.toInt() : amount,
        'paymentDate': apiDate(paymentDate),
        'paymentMethod': paymentMethod,
        'referenceNumber': referenceNumber,
        'payerBank': payerBank,
        'notes': notes,
        'proofUrls': proofUrls,
        if (extractionId != null) 'extractionId': extractionId,
      };
}
