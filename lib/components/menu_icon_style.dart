import 'package:flutter/material.dart';

import '../auth/model/Menuitem.dart';

/// Home menu icons: one rounded icon family and a curated jewel-tone palette
/// (instead of mixed Material icons in bright primary colours), keyed by
/// menu id so `Menulists.dart` stays untouched. Unknown ids keep the
/// item's own icon and colour.
const Map<int, (IconData, Color)> _menuStyles = {
  1: (Icons.record_voice_over_rounded, Color(0xFFE8833A)), // Create Demo
  2: (Icons.format_list_bulleted_rounded, Color(0xFF3B6FE0)), // Demo List
  3: (Icons.school_rounded, Color(0xFF1F9D57)), // School List
  4: (Icons.campaign_rounded, Color(0xFF9B5DE5)), // Circular List
  5: (Icons.insights_rounded, Color(0xFF0E9AD6)), // Status Report
  6: (Icons.account_balance_wallet_rounded, Color(0xFFD6457A)), // Record Collection
  8: (Icons.currency_rupee_rounded, Color(0xFFE0692B)), // Advance Tour Expense
  9: (Icons.directions_car_filled_rounded, Color(0xFF5B5FE0)), // Local Conveyence
  10: (Icons.business_center_rounded, Color(0xFF0F8FA8)), // Customer Details
  11: (Icons.folder_copy_rounded, Color(0xFFB7791F)), // School Documents
  12: (Icons.info_rounded, Color(0xFFE0524F)), // Important Info
  13: (Icons.smart_display_rounded, Color(0xFF7457E8)), // Management Videos
  14: (Icons.hourglass_bottom_rounded, Color(0xFF64748B)), // Zero Activity
  16: (Icons.notifications_active_rounded, Color(0xFFE8475F)), // Alerts
  18: (Icons.dns_rounded, Color(0xFF0D9488)), // Server Status
  19: (Icons.alt_route_rounded, Color(0xFF0EA5C6)), // Root Tracker
  20: (Icons.forum_rounded, Color(0xFF1FA463)), // Chat
  21: (Icons.event_repeat_rounded, Color(0xFFEF6A5A)), // Follow-ups
  22: (Icons.military_tech_rounded, Color(0xFFD99A12)), // Leaderboard
  23: (Icons.storefront_rounded, Color(0xFF3F5BD8)), // Exhibitions
  24: (Icons.confirmation_number_rounded, Color(0xFF12A37F)), // Tickets
  25: (Icons.receipt_long_rounded, Color(0xFF4F6693)), // Payment Submissions
};

IconData menuIcon(MenuItem m) => _menuStyles[m.id]?.$1 ?? m.icon;
Color menuColor(MenuItem m) => _menuStyles[m.id]?.$2 ?? m.color;
