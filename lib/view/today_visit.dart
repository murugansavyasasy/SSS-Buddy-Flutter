import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/view/root_mapview.dart';
import 'package:sssbuddy/view/status_report.dart';

import '../Values/Colors/app_colors.dart';
import '../components/toolbar_layout.dart';
import '../core/storage/secure_storage.dart';
import '../viewModel/today_visit_viewmodal.dart';

class TodayVisitPage extends ConsumerStatefulWidget {
  const TodayVisitPage({super.key});

  @override
  ConsumerState<TodayVisitPage> createState() => _TodayVisitPageState();
}

class _TodayVisitPageState extends ConsumerState<TodayVisitPage> {
  bool isTripStarted = false;
  bool isStartingTrip = false;
  bool isLoadingTrip = true;
  final TextEditingController dateController = TextEditingController();
  final TextEditingController schoolController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController personNameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController remarkController = TextEditingController();

  String? selectedPerson;
  String? selectedReason;

  final List<String> persons = ["Principal", "Teacher", "Admin", "Other"];
  final List<String> reasons = [
    "Demo",
    "Follow-up",
    "Collection",
    "Support",
    "Other",
  ];

  // Colors
  static const Color primaryColor = Color(0xFF1A1F36);
  static const Color accentColor = Color(0xFF4F6FFF);
  static const Color successColor = Color(0xFF22C55E);
  static const Color dangerColor = Color(0xFFEF4444);
  static const Color cardColor = Colors.white;
  static const Color mutedText = Color(0xFF8A94A6);

  @override
  void initState() {
    super.initState();
    dateController.text = _formattedToday();
    _initTripState();
  }

  Future<void> _initTripState() async {
    final storedStarted = await SecureStorage.getTripStarted();
    final storedDate = await SecureStorage.getTripStartDate();

    final today = _formattedToday();

    if (storedStarted && storedDate != null && storedDate == today) {
      isTripStarted = true;
    } else {
      await SecureStorage.clearTripData();
      isTripStarted = false;
    }

    setState(() {
      isLoadingTrip = false;
    });
  }
  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1];
  }

  String _formattedToday() {
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}-${_monthName(now.month)}-${now.year}";
  }

  Future<void> pickDate() async {
    if (!isTripStarted) return;
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: accentColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        dateController.text =
        "${picked.day.toString().padLeft(2, '0')}-${_monthName(picked.month)}-${picked.year}";
      });
    }
  }

  String? _validateFields() {
    if (schoolController.text.trim().isEmpty) return "School Name is required";
    if (areaController.text.trim().isEmpty) return "Area is required";
    if (districtController.text.trim().isEmpty) return "District is required";
    if (selectedPerson == null) return "Please select Person Met";
    if (selectedReason == null) return "Please select Reason for Visit";
    return null;
  }

  Future<void> _handleEndDay() async {
    final error = _validateFields();

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(error)),
            ],
          ),
          backgroundColor: dangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final success =
    await ref.read(todayVisitProvider.notifier).manageTrip("stop");
    if (!mounted) return;

    if (success) {
      await SecureStorage.clearTripData();
      setState(() => isTripStarted = false);
      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Trip ended successfully!"),
          backgroundColor: successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to end trip. Try again."),
          backgroundColor: dangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _clearForm() {
    schoolController.clear();
    areaController.clear();
    districtController.clear();
    personNameController.clear();
    contactController.clear();
    remarkController.clear();
    setState(() {
      selectedPerson = null;
      selectedReason = null;
      dateController.text = _formattedToday();
    });
  }

  @override
  void dispose() {
    dateController.dispose();
    schoolController.dispose();
    areaController.dispose();
    districtController.dispose();
    personNameController.dispose();
    contactController.dispose();
    remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          ToolbarLayout(
            title: "Today Visit",
            navigateTo: const StatusReport(),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  _buildStatusBanner(),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionCard(
                            icon: Icons.event_note_rounded,
                            title: "Visit Details",
                            children: [
                              _buildDateField(),
                              _buildInputField(
                                controller: schoolController,
                                label: "School Name",
                                icon: Icons.school_outlined,
                                required: true,
                                hint: "Enter school name",
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInputField(
                                      controller: areaController,
                                      label: "Area",
                                      icon: Icons.location_on_outlined,
                                      required: true,
                                      hint: "Enter area",
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildInputField(
                                      controller: districtController,
                                      label: "District",
                                      icon: Icons.map_outlined,
                                      required: true,
                                      hint: "Enter district",
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSectionCard(
                            icon: Icons.person_outline_rounded,
                            title: "Contact Info",
                            children: [
                              _buildDropdown(
                                value: selectedPerson,
                                label: "Person Met",
                                icon: Icons.badge_outlined,
                                items: persons,
                                required: true,
                                onChanged: (val) =>
                                    setState(() => selectedPerson = val),
                              ),
                              _buildInputField(
                                controller: personNameController,
                                label: "Name of the Person",
                                icon: Icons.person_outlined,
                                hint: "Enter person name",
                              ),
                              _buildInputField(
                                controller: contactController,
                                label: "Contact Number",
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                hint: "Enter mobile number",
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSectionCard(
                            icon: Icons.notes_rounded,
                            title: "Visit Notes",
                            children: [
                              _buildDropdown(
                                value: selectedReason,
                                label: "Reason for Visit",
                                icon: Icons.help_outline_rounded,
                                items: reasons,
                                required: true,
                                onChanged: (val) =>
                                    setState(() => selectedReason = val),
                              ),
                              _buildInputField(
                                controller: remarkController,
                                label: "Any Other Specific Remarks?",
                                icon: Icons.chat_bubble_outline_rounded,
                                maxLines: 3,
                                hint: "Write your remarks here...",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ✅ Fixed bottom action buttons (always visible)
                  _buildFixedBottomButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Fixed bottom buttons — always visible, never scrolls away
  Widget _buildFixedBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildRecordVisitButton()),
          const SizedBox(width: 12),
          Expanded(child: _buildEndDayButton()),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    if (isLoadingTrip) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isTripStarted
              ? [const Color(0xFF16A34A), const Color(0xFF22C55E)]
              : [const Color(0xFFDC2626), const Color(0xFFEF4444)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isTripStarted
                  ? Icons.directions_car_rounded
                  : Icons.car_crash_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTripStarted ? "Trip In Progress" : "No Active Trip",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  isTripStarted
                      ? "Tracking your route"
                      : "Start your trip now",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // BUTTON / LOADER
          if (!isTripStarted)
            isStartingTrip
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                setState(() => isStartingTrip = true);
                final success = await ref
                    .read(todayVisitProvider.notifier)
                    .manageTrip("start");
                if (!mounted) return;
                setState(() => isStartingTrip = false);
                if (success) {
                  final today = _formattedToday();
                  await SecureStorage.saveTripData(true, today);
                  setState(() => isTripStarted = true);

                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Failed to start trip")),
                  );
                }
              },
              child: const Text(
                "START",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

          if (isTripStarted)
            const Icon(
              Icons.check_circle,
              color: Colors.white,
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: accentColor, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F1F5)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: pickDate,
        child: AbsorbPointer(
          child: _buildInputField(
            controller: dateController,
            label: "Visit Date",
            icon: Icons.calendar_today_outlined,
            required: true,
            readOnly: true,
            suffixIcon: Icons.edit_calendar_rounded,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool required = false,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    IconData? suffixIcon,
  }) {
    final isEnabled = isTripStarted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isEnabled ? primaryColor : mutedText,
                  letterSpacing: 0.2,
                ),
              ),
              if (required)
                const Text(
                  " *",
                  style: TextStyle(color: dangerColor, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            enabled: isEnabled,
            readOnly: readOnly,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 14,
              color: isEnabled ? primaryColor : mutedText,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 13,
                color: mutedText.withOpacity(0.7),
              ),
              prefixIcon: Icon(
                icon,
                size: 18,
                color: isEnabled ? accentColor : mutedText,
              ),
              suffixIcon: suffixIcon != null
                  ? Icon(
                suffixIcon,
                size: 18,
                color: isEnabled ? accentColor : mutedText,
              )
                  : null,
              filled: true,
              fillColor: isEnabled ? Colors.white : const Color(0xFFF8F9FF),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE8EAF0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE8EAF0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: accentColor, width: 1.5),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEEF0F5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
    bool required = false,
  }) {
    final isEnabled = isTripStarted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isEnabled ? primaryColor : mutedText,
                  letterSpacing: 0.2,
                ),
              ),
              if (required)
                const Text(
                  " *",
                  style: TextStyle(color: dangerColor, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isEnabled ? accentColor : mutedText,
            ),
            style: TextStyle(
              fontSize: 14,
              color: isEnabled ? primaryColor : mutedText,
              fontWeight: FontWeight.w500,
            ),
            dropdownColor: Colors.white,
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                size: 18,
                color: isEnabled ? accentColor : mutedText,
              ),
              filled: true,
              fillColor: isEnabled ? Colors.white : const Color(0xFFF8F9FF),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE8EAF0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE8EAF0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: accentColor, width: 1.5),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEEF0F5)),
              ),
            ),
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: isEnabled ? onChanged : null,
            hint: Text(
              "Select $label",
              style: const TextStyle(color: mutedText, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordVisitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add_location_alt_outlined, size: 20),
        label: const Text(
          "RECORD A VISIT",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isTripStarted ? accentColor : mutedText,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: isTripStarted
            ? () async {
          final error = _validateFields();
          if (error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(error)),
                  ],
                ),
                backgroundColor: dangerColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            return;
          }
          try {
            final success = await ref
                .read(todayVisitProvider.notifier)
                .submitVisitRecord(
              schoolName: schoolController.text.trim(),
              area: areaController.text.trim(),
              district: districtController.text.trim(),
              personName: personNameController.text.trim(),
              contactNumber: contactController.text.trim(),
              remarks: remarkController.text.trim(),
              reasonOfVisit: selectedReason ?? "",
              personMet: selectedPerson ?? "",
              dateOfVisit: dateController.text,
            );
            if (!mounted) return;
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Visit recorded successfully ✅"),
                  backgroundColor: successColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              _clearForm();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Failed to record visit ❌"),
                  backgroundColor: dangerColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString())),
            );
          }
        }
            : null,
      ),
    );
  }

  Widget _buildEndDayButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.stop_circle_outlined, size: 20),
        label: const Text(
          "END DAY",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: isTripStarted ? dangerColor : mutedText,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(
            color: isTripStarted ? dangerColor : mutedText,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: isTripStarted ? () => _handleEndDay() : null,
      ),
    );
  }
}