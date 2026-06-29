import 'package:flutter/material.dart';
import 'package:sssbuddy/auth/model/Menuitem.dart';

List<MenuItem> getMenuItems({
  required String vimsUserType,
  required String schoolUserType,
}) {
  final List<MenuItem> menus = [];

  // School menus
  if (vimsUserType == "19") {
    menus.addAll([
      MenuItem(
        id: 1,
        title: "Create Demo",
        icon: Icons.create,
        color: Colors.orange,
      ),
      MenuItem(
        id: 2,
        title: "Demo List",
        icon: Icons.list,
        color: Colors.blue,
      ),
      MenuItem(
        id: 13,
        title: "Management Videos",
        icon: Icons.video_library,
        color: Colors.deepPurple,
      ),
    ]);
  } else {
    menus.addAll([
      MenuItem(
        id: 1,
        title: "Create Demo",
        icon: Icons.create,
        color: Colors.orange,
      ),
      MenuItem(
        id: 2,
        title: "Demo List",
        icon: Icons.list,
        color: Colors.blue,
      ),
      MenuItem(
        id: 3,
        title: "School List",
        icon: Icons.school,
        color: Colors.green,
      ),
      MenuItem(
        id: 4,
        title: "Circular List",
        icon: Icons.announcement,
        color: Colors.purple,
      ),
      MenuItem(
        id: 5,
        title: "Status Report",
        icon: Icons.assignment_turned_in,
        color: Colors.purpleAccent,
      ),
      MenuItem(
        id: 6,
        title: "Record Collection",
        icon: Icons.payment,
        color: Colors.pink,
      ),
      MenuItem(
        id: 12,
        title: "Important Info",
        icon: Icons.info_outline,
        color: Colors.redAccent,
      ),
      MenuItem(
        id: 14,
        title: "Zero Activity",
        icon: Icons.do_not_disturb,
        color: Colors.blueGrey,
      ),
    ]);

    if (schoolUserType == "Admin" ||
        schoolUserType == "Support") {
      menus.add(
        MenuItem(
          id: 16,
          title: "Alerts",
          icon: Icons.notifications_active,
          color: Colors.red,
        ),
      );
    }
  }

  // VIMS section
  if (!(vimsUserType == "19" ||
      schoolUserType == "MyTeam")) {
    menus.addAll([
      MenuItem(
        id: 10,
        title: "Customer Details",
        icon: Icons.business,
        color: Colors.cyan,
      ),
      MenuItem(
        id: 9,
        title: "Local Conveyence",
        icon: Icons.directions_car,
        color: Colors.indigo,
      ),
      MenuItem(
        id: 8,
        title: "Advance Tour Expense",
        icon: Icons.attach_money,
        color: Colors.deepOrange,
      ),
    ]);
  }

  // Common section
  if (vimsUserType != "19") {
    menus.addAll([
      MenuItem(
        id: 11,
        title: "School Documents",
        icon: Icons.folder_open,
        color: Colors.brown,
      ),
      MenuItem(
        id: 13,
        title: "Management Videos",
        icon: Icons.video_library,
        color: Colors.deepPurple,
      ),
    ]);
  }

  return menus;
}