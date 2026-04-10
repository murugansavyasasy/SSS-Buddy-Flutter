import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TourSettlement extends ConsumerWidget {
  const TourSettlement({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour Settlement'),
        // Remove this line later when feature is ready
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Big icon / illustration
              Icon(
                Icons.construction_rounded,
                size: 120,
                color: Colors.grey.shade400,
              ),

              const SizedBox(height: 32),

              // Main heading
              Text(
                "Coming Soon!",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                "Tour Settlement is under development.\n\nIt will be released in the next batch.\nStay tuned!",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Optional helpful button
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text("Go Back"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}