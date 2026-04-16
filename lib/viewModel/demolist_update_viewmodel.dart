// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../provider/app_providers.dart';
//
// Future<void> updateDemo(
//     Map<String, dynamic> body,
//     BuildContext context,
//     ) async {
//   state = const AsyncLoading();
//
//   try {
//     final repo = ref.read(repositoryProvider);
//
//     final response = await repo.updateDemo(body);
//
//     if (response[0]['Status'] == 1) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(response[0]['Message'])),
//       );
//
//       Navigator.pop(context);
//     } else {
//       throw Exception(response[0]['Message']);
//     }
//   } catch (e, s) {
//     state = AsyncError(e, s);
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Error: $e")),
//     );
//   }
// }