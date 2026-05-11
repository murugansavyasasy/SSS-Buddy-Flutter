import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/toolbar_layout.dart';
import '../viewModel/zeroactivity_viewmodal.dart';

class ZeroActivityScreen extends ConsumerStatefulWidget {
  const ZeroActivityScreen({super.key});

  @override
  ConsumerState<ZeroActivityScreen> createState() =>
      _ZeroActivityScreenState();
}

class _ZeroActivityScreenState
    extends ConsumerState<ZeroActivityScreen> {

  String selectedValue = "All";

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(zeroActivityProvider);

    /// ✅ Dynamic Status Dropdown (from API)
    final statusList = dataAsync.when(
      data: (list) {
        final uniqueStatus = list
            .map((e) => e.instituteStatus)
            .toSet()
            .toList();

        return ["All", ...uniqueStatus];
      },
      loading: () => ["All"],
      error: (_, __) => ["All"],
    );

    return Scaffold(
      backgroundColor: const Color(0xFF5B6F95),
      body: Column(
        children: [

          /// 🔝 HEADER WITH SEARCH + DROPDOWN
          ToolbarLayout(
            title: "Zero Activity",
            searchHint: "Search....",

            dropdownLists: statusList,
            selectedMonth: selectedValue,

            /// 🎯 STATUS FILTER (LOCAL)
            onMonthChanged: (value) {
              if (value == null) return;

              setState(() {
                selectedValue = value;
              });

              ref
                  .read(zeroActivityProvider.notifier)
                  .filterByStatus(value);
            },

            /// 🔍 SEARCH
            onSearch: (query) {
              ref
                  .read(zeroActivityProvider.notifier)
                  .filter(query);
            },
          ),

          /// 📋 LIST VIEW
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F6FA),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
              child: dataAsync.when(
                loading: () =>
                const Center(child: CircularProgressIndicator()),

                error: (e, _) =>
                    Center(child: Text("Error: $e")),

                data: (list) {
                  if (list.isEmpty) {
                    return const Center(
                        child: Text("No Data Found"));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            item.instituteName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          subtitle: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text("Sales: ${item.salesPerson}"),
                              Text(
                                "Web Login: ${item.lastWebLogin.isEmpty ? "No Data" : item.lastWebLogin}",
                              ),
                            ],
                          ),

                          /// 🟢 STATUS BADGE
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: item.instituteStatus == "LIVE"
                                  ? Colors.green
                                  : Colors.red,
                              borderRadius:
                              BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.displayStatus,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}