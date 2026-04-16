import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../provider/app_providers.dart';
import '../auth/model/DemolistEditModel.dart';
import '../repository/clientrepository.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/app_providers.dart';
import '../auth/model/DemolistEditModel.dart';
import '../repository/clientrepository.dart';

class DemolistEditViewmodel
    extends StateNotifier<AsyncValue<List<Demolisteditmodel>>> {
  final ClientRepository _repository;

  DemolistEditViewmodel(this._repository)
      : super(const AsyncValue.loading());

  Future<void> getdemolisteditdetails(String demoId) async {
    state = const AsyncValue.loading();
    try {
      final data = await _repository.getdemolisteditdetail(demoId);
      state = AsyncValue.data(data);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateDemo(
      Map<String, dynamic> body,
      BuildContext context,
      ) async {
    try {
      final response = await _repository.updateDemo(body);

      if (response.isNotEmpty && response[0]['Status'] == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response[0]['Message'] ?? 'Demo updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        final errorMsg = response.isNotEmpty
            ? response[0]['Message'] ?? 'Update failed'
            : 'Unknown error from server';
        throw Exception(errorMsg);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
    }
  }
}

final demolistEditProvider =
StateNotifierProvider<DemolistEditViewmodel, AsyncValue<List<Demolisteditmodel>>>(
      (ref) {
    final repo = ref.read(repositoryProvider);
    return DemolistEditViewmodel(repo);
  },
);