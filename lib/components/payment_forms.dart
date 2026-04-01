import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Values/Colors/app_colors.dart';
import 'searchable_dropdown.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared Section Header
// ─────────────────────────────────────────────────────────────────────────────
class PaymentSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const PaymentSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CASH FORM
// ─────────────────────────────────────────────────────────────────────────────
class CashPaymentForm extends StatelessWidget {
  final TextEditingController cashReceivedOnController;
  final TextEditingController cashDepositedOnController;
  final TextEditingController cashDepositedBranchController;
  final String? selectedBank;
  final ValueChanged<String?> onBankChanged;

  static const List<String> _banks = [
    'Karur Vysya Bank',
    'Kotak Mahindra Bank',
    'ICICI Bank',
  ];

  const CashPaymentForm({
    super.key,
    required this.cashReceivedOnController,
    required this.cashDepositedOnController,
    required this.cashDepositedBranchController,
    required this.selectedBank,
    required this.onBankChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedFormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PaymentSectionHeader(
            title: 'Cash Details',
            icon: Icons.account_balance_wallet_outlined,
            color: Color(0xFF059669),
          ),
          FormDateField(
            controller: cashReceivedOnController,
            label: 'Cash Received On',
            icon: Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 14),
          FormDateField(
            controller: cashDepositedOnController,
            label: 'Cash Deposited On',
            icon: Icons.calendar_month_outlined,
          ),
          const SizedBox(height: 14),
          SearchableDropdown<String>(
            label: 'Cash Deposited Bank',
            hint: 'Select a bank',
            value: selectedBank,
            items: _banks,
            itemLabel: (e) => e,
            itemValue: (e) => e,
            onChanged: onBankChanged,
          ),
          const SizedBox(height: 14),
          FormInputField(
            controller: cashDepositedBranchController,
            label: 'Cash Deposited Branch',
            icon: Icons.business_outlined,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHEQUE FORM
// ─────────────────────────────────────────────────────────────────────────────
class ChequePaymentForm extends StatelessWidget {
  final TextEditingController chequeNumberController;
  final TextEditingController chequeDateController;
  final TextEditingController chequeBankController;
  final TextEditingController chequeDepositedDateController;

  const ChequePaymentForm({
    super.key,
    required this.chequeNumberController,
    required this.chequeDateController,
    required this.chequeBankController,
    required this.chequeDepositedDateController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedFormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PaymentSectionHeader(
            title: 'Cheque Details',
            icon: Icons.receipt_long_outlined,
            color: Color(0xFF2563EB),
          ),
          FormInputField(
            controller: chequeNumberController,
            label: 'Cheque Number',
            icon: Icons.tag_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 14),
          FormDateField(
            controller: chequeDateController,
            label: 'Cheque Date',
            icon: Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 14),
          FormInputField(
            controller: chequeBankController,
            label: 'Cheque Bank',
            icon: Icons.account_balance_outlined,
          ),
          const SizedBox(height: 14),
          FormDateField(
            controller: chequeDepositedDateController,
            label: 'Cheque Deposited Date',
            icon: Icons.calendar_month_outlined,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NEFT FORM
// ─────────────────────────────────────────────────────────────────────────────
class NeftPaymentForm extends StatelessWidget {
  final TextEditingController neftTransactionController;

  const NeftPaymentForm({
    super.key,
    required this.neftTransactionController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedFormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PaymentSectionHeader(
            title: 'NEFT Details',
            icon: Icons.swap_horiz_rounded,
            color: Color(0xFF7C3AED),
          ),
          FormInputField(
            controller: neftTransactionController,
            label: 'NEFT Transaction Number',
            icon: Icons.confirmation_number_outlined,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PDC FORM
// ─────────────────────────────────────────────────────────────────────────────
class PdcPaymentForm extends StatelessWidget {
  final TextEditingController pdcChequeNoController;
  final TextEditingController pdcChequeDateController;
  final TextEditingController pdcChequeBankController;
  final TextEditingController pdcChequeBranchController;

  const PdcPaymentForm({
    super.key,
    required this.pdcChequeNoController,
    required this.pdcChequeDateController,
    required this.pdcChequeBankController,
    required this.pdcChequeBranchController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedFormSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PaymentSectionHeader(
            title: 'PDC Details',
            icon: Icons.credit_card_outlined,
            color: Color(0xFFD97706),
          ),
          FormInputField(
            controller: pdcChequeNoController,
            label: 'Cheque No',
            icon: Icons.tag_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 14),
          FormDateField(
            controller: pdcChequeDateController,
            label: 'Cheque Date',
            icon: Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 14),
          FormInputField(
            controller: pdcChequeBankController,
            label: 'Cheque Bank',
            icon: Icons.account_balance_outlined,
          ),
          const SizedBox(height: 14),
          FormInputField(
            controller: pdcChequeBranchController,
            label: 'Cheque Bank Branch',
            icon: Icons.business_outlined,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared: Animated wrapper for smooth show/hide
// ─────────────────────────────────────────────────────────────────────────────
class AnimatedFormSection extends StatefulWidget {
  final Widget child;
  const AnimatedFormSection({super.key, required this.child});

  @override
  State<AnimatedFormSection> createState() => _AnimatedFormSectionState();
}

class _AnimatedFormSectionState extends State<AnimatedFormSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared: FormInputField
// ─────────────────────────────────────────────────────────────────────────────
class FormInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;

  const FormInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF111827),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared: Date picker field
// ─────────────────────────────────────────────────────────────────────────────
class FormDateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const FormDateField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
  });

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      controller.text =
      "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormInputField(
      controller: controller,
      label: label,
      icon: icon,
      readOnly: true,
      onTap: () => _pickDate(context),
    );
  }
}