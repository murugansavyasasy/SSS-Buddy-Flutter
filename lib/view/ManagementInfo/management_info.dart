import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sssbuddy/components/toolbar_layout.dart';
import 'package:sssbuddy/view/ManagementInfo/school_header.dart';
import 'package:sssbuddy/view/school_listview.dart';
import '../../Values/Colors/app_colors.dart';
import '../../viewModel/management_info_viewmodel.dart';
import 'member_card.dart';


class ManagementInfo extends ConsumerStatefulWidget {
  final Map<String, dynamic> item;
  const ManagementInfo({super.key, required this.item});

  @override
  ConsumerState<ManagementInfo> createState() => _ManagementInfoScreenState();
}

class _ManagementInfoScreenState extends ConsumerState<ManagementInfo> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    final vm = ref.read(managementInfoViewModelProvider.notifier);
    await vm.managementinfo(int.parse(widget.item['SchoolID'].toString()));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(managementInfoViewModelProvider);
    final members = state.value;

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
              title: "Management Info",
              navigateTo: SchoolListview(),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SchoolHeader(
                      schoolName: widget.item['SchoolName'] ?? '-',
                    ),

                    Expanded(
                      child: state.when(  // 👈 Use state.when() instead of manual _isLoading
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (e, s) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.redAccent, size: 40),
                              const SizedBox(height: 8),
                              const Text('Failed to load data'),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _fetchData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                        data: (members) => members == null || members.isEmpty
                            ? const Center(
                          child: Text(
                            'No members found.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                            : ListView.separated(
                          padding:
                          const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: members.length,
                          separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                          itemBuilder: (context, index) => MemberCard(
                              member: members[index], index: index),
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
}
