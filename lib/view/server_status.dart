import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Values/Colors/app_colors.dart';
import '../auth/model/DialoutServerModel.dart';
import '../components/toolbar_layout.dart';
import '../viewModel/server_status_viewmodel.dart';
import 'dashboard.dart';

class ServerStatusScreen extends ConsumerWidget {
  const ServerStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverState = ref.watch(serverStatusViewModelProvider);

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
              title: "Server Status",
              navigateTo: const Dashboard(),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  children: [
                    _buildProductDropdown(ref),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => ref
                            .read(serverStatusViewModelProvider.notifier)
                            .refresh(),
                        child: serverState.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (e, _) => _buildError(ref, e),
                          data: (servers) => servers.isEmpty
                              ? _buildEmptyState(context)
                              : _buildList(servers),
                        ),
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

  // 🔽 Product dropdown
  Widget _buildProductDropdown(WidgetRef ref) {
    final selected = ref.watch(selectedServerProductProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selected,
            isExpanded: true,
            borderRadius: BorderRadius.circular(12),
            icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C2340),
            ),
            items: serverProducts
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              ref.read(selectedServerProductProvider.notifier).state = value;
            },
          ),
        ),
      ),
    );
  }

  // 🔴 Error UI
  Widget _buildError(WidgetRef ref, Object e) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 150),
        Column(
          children: [
            const Icon(Icons.error_outline,
                size: 60, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              "Failed to load servers\n${e.toString().replaceFirst("Exception: ", "")}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(serverStatusViewModelProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text("Retry"),
            ),
          ],
        ),
      ],
    );
  }

  // 📭 Empty UI
  Widget _buildEmptyState(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Column(
          children: [
            Icon(Icons.dns_outlined, size: 110, color: Colors.grey.shade400),
            const SizedBox(height: 28),
            Text(
              "No Servers Found",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "There are no dialout servers to display.",
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ],
    );
  }

  // 📋 List
  Widget _buildList(List<DialoutServerModel> list) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _ServerCard(item: list[index]),
    );
  }
}

class _ServerCard extends StatelessWidget {
  final DialoutServerModel item;
  const _ServerCard({required this.item});

  static const _textDark = Color(0xFF1C2340);

  @override
  Widget build(BuildContext context) {
    final statusColor =
        item.isActive ? const Color(0xFF1DB954) : const Color(0xFFE53935);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withOpacity(0.25), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    statusColor.withOpacity(0.12),
                    statusColor.withOpacity(0.02),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.dns_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.serverName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Server ID #${item.id}",
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(isActive: item.isActive, color: statusColor),
                ],
              ),
            ),

            // Info chips
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Row(
                children: [
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.phone_in_talk_rounded,
                      label: "Default DID",
                      value: item.defaultDid,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.hub_rounded,
                      label: "Provider",
                      value: item.providerCode,
                    ),
                  ),
                ],
              ),
            ),

            // Feature toggles (2 x 2)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _FeatureToggle(
                          icon: Icons.power_settings_new_rounded,
                          label: "Active",
                          server: item,
                          flagKey: DialoutServerModel.keyActive,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FeatureToggle(
                          icon: Icons.receipt_long_rounded,
                          label: "Call Log",
                          server: item,
                          flagKey: DialoutServerModel.keyCallLog,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _FeatureToggle(
                          icon: Icons.cloud_upload_rounded,
                          label: "File Upload",
                          server: item,
                          flagKey: DialoutServerModel.keyFileUpload,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FeatureToggle(
                          icon: Icons.send_rounded,
                          label: "Send Data",
                          server: item,
                          flagKey: DialoutServerModel.keySendData,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isActive;
  final Color color;
  const _StatusPill({required this.isActive, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 7,
            width: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? "Online" : "Offline",
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 1),
                Text(
                  value.isEmpty ? "-" : value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C2340),
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

class _FeatureToggle extends ConsumerStatefulWidget {
  final IconData icon;
  final String label;
  final DialoutServerModel server;
  final String flagKey;
  const _FeatureToggle({
    required this.icon,
    required this.label,
    required this.server,
    required this.flagKey,
  });

  @override
  ConsumerState<_FeatureToggle> createState() => _FeatureToggleState();
}

class _FeatureToggleState extends ConsumerState<_FeatureToggle> {
  bool _updating = false;

  Future<bool> _confirmChange(bool newValue) async {
    final isActiveFlag = widget.flagKey == DialoutServerModel.keyActive;
    final action = isActiveFlag
        ? (newValue ? "Activate" : "Deactivate")
        : (newValue ? "Enable" : "Disable");
    final subject = isActiveFlag ? "Server" : widget.label;
    final color = newValue ? const Color(0xFF1DB954) : Colors.redAccent;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(widget.icon, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text("$action $subject")),
          ],
        ),
        content: Text(
          isActiveFlag
              ? "Are you sure you want to ${action.toLowerCase()} "
                  "\"${widget.server.serverName}\"?"
              : "Are you sure you want to ${action.toLowerCase()} "
                  "${widget.label} for \"${widget.server.serverName}\"?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(action),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  Future<void> _onChanged(bool newValue) async {
    if (!await _confirmChange(newValue)) return;
    if (!mounted) return;

    setState(() => _updating = true);

    final error = await ref
        .read(serverStatusViewModelProvider.notifier)
        .updateFlag(widget.server, widget.flagKey, newValue);

    if (!mounted) return;
    setState(() => _updating = false);

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ??
            "${widget.label} ${newValue ? "enabled" : "disabled"} for ${widget.server.serverName}"),
        backgroundColor: error == null ? const Color(0xFF1DB954) : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.server.flag(widget.flagKey);
    final color = value ? const Color(0xFF1DB954) : Colors.grey.shade500;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.08) : const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? color.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Icon(widget.icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C2340),
                    ),
                  ),
                ),
                Text(
                  value ? "Enabled" : "Disabled",
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 38,
            height: 24,
            child: _updating
                ? const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.contain,
                    child: Switch(
                      value: value,
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF1DB954),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: _onChanged,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
