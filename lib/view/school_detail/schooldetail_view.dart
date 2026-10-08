import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/view/school_listview.dart';
import 'package:sssbuddy/view/UsageCount/usage_count.dart';
import '../../Values/Colors/app_colors.dart';
import '../../components/toolbar_layout.dart';
import '../ManagementInfo/management_info.dart';

// NOTE: ExamTable / TableRowModel ippo inga use aagala (sections-ah
// maathitten). Vera edathula use pannina, andha files appadiye irukkattum.

const Color _navy = Color(0xFF1A3A5C);

class SchooldetailView extends ConsumerWidget {
  final Map<String, dynamic> item;

  const SchooldetailView({super.key, required this.item});

  /// Value or "-" when null / empty.
  String _v(String key) {
    final s = (item[key] ?? '').toString().trim();
    return s.isEmpty ? '-' : s;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            ToolbarLayout(
              title: "School List Detail",
              navigateTo: SchoolListview(),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FB),
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    child: Column(
                      children: [
                        _buildHero(),
                        const SizedBox(height: 14),
                        _buildStats(),
                        const SizedBox(height: 14),
                        _buildPeriod(),
                        const SizedBox(height: 14),
                        _buildSchoolInfo(),
                        const SizedBox(height: 14),
                        _buildContacts(),
                        const SizedBox(height: 14),
                        _buildLogin(),
                        const SizedBox(height: 18),
                        _buildFooter(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================
  Widget _buildHero() {
    final name = (item['SchoolName'] ?? '_').toString();
    final status = _v('Status');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, Color(0xFF2C5A8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "ID  ${_v('SchoolID')}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              if (status != '-')
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              height: 1.25,
            ),
          ),
          if (_v('City') != '-') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 15, color: Colors.white70),
                const SizedBox(width: 4),
                Text(
                  _v('City'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // STATS (Students / Staff)
  // ============================================================
  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.groups_rounded,
            color: Colors.blue,
            label: 'Students',
            value: _v('Students'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.badge_rounded,
            color: Colors.teal,
            label: 'Staff',
            value: _v('Staff'),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PERIOD
  // ============================================================
  Widget _buildPeriod() {
    return _Section(
      title: 'Subscription Period',
      icon: Icons.event_rounded,
      child: Row(
        children: [
          Expanded(child: _DateBlock(label: 'From', value: _v('PeriodFrom'))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward_rounded,
                color: Colors.grey.shade400, size: 20),
          ),
          Expanded(child: _DateBlock(label: 'To', value: _v('PeriodTo'))),
        ],
      ),
    );
  }

  // ============================================================
  // SCHOOL INFO
  // ============================================================
  Widget _buildSchoolInfo() {
    return _Section(
      title: 'School Details',
      icon: Icons.school_rounded,
      child: Column(
        children: [
          _InfoRow(
              icon: Icons.home_rounded,
              label: 'Address',
              value: _v('Address')),
          _InfoRow(
              icon: Icons.location_city_rounded,
              label: 'City',
              value: _v('City')),
          _InfoRow(
              icon: Icons.call_rounded,
              label: 'Contact No',
              value: _v('UserName')),
          _InfoRow(
            icon: Icons.mail_rounded,
            label: 'Email',
            value: _v('ContactEmail'),
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTACTS
  // ============================================================
  Widget _buildContacts() {
    return _Section(
      title: 'Contact Persons',
      icon: Icons.contacts_rounded,
      child: Column(
        children: [
          _ContactTile(
            index: 1,
            name: _v('ContactPerson1'),
            number: _v('ContactNumber1'),
          ),
          const SizedBox(height: 10),
          _ContactTile(
            index: 2,
            name: _v('ContactPerson2'),
            number: _v('ContactNumber2'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOGIN
  // ============================================================
  Widget _buildLogin() {
    return _Section(
      title: 'Web Login',
      icon: Icons.lock_rounded,
      child: _InfoRow(
        icon: Icons.person_rounded,
        label: 'Web User Name',
        value: _v('UserName'),
        isLast: true,
      ),
    );
  }

  // ============================================================
  // FOOTER BUTTONS
  // ============================================================
  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UsageCountScreen(item: item),
                ),
              );
            },
            icon: const Icon(Icons.bar_chart_rounded, size: 18),
            label: const Text(
              "Usage Count",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _navy,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManagementInfo(item: item),
                ),
              );
            },
            icon: const Icon(Icons.manage_accounts_rounded, size: 18),
            label: const Text(
              "Management Info",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _navy,
              backgroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              side: const BorderSide(color: _navy),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==============================================================
// REUSABLE PIECES
// ==============================================================

/// White rounded card with a titled header.
class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _navy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: _navy),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 17, color: Colors.grey.shade500),
              const SizedBox(width: 10),
              SizedBox(
                width: 92,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final MaterialColor color;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color.shade700, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color.shade800,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBlock extends StatelessWidget {
  final String label;
  final String value;

  const _DateBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final int index;
  final String name;
  final String number;

  const _ContactTile({
    required this.index,
    required this.name,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: _navy.withOpacity(0.1),
            child: Text(
              '$index',
              style: const TextStyle(
                color: _navy,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  number,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.call_rounded, size: 18, color: Colors.green.shade600),
        ],
      ),
    );
  }
}