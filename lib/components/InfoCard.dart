

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../auth/model/InfoRowData.dart';
import 'importantInfoRow.dart';

class InfoCard extends StatelessWidget {
  final List<InfoRowData> items;
  const InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.08), width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Importantinforow(data: item, showDivider: !isLast);
        }),
      ),
    );
  }
}