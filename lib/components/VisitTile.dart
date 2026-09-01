import 'package:flutter/material.dart';
import '../auth/model/OverallTripDetailsModel.dart';

class VisitTile extends StatelessWidget {
  final VisitDetail visit;

  const VisitTile({super.key, required this.visit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school_outlined, size: 18, color: Colors.blue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  visit.school_name ?? 'Unknown School',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),


          if (visit.latitude != null && visit.longitude != null) ...[
            const SizedBox(height: 10),
            FutureBuilder<String>(
              future: TripAddressLoader.getCachedAddress(
                latitude: visit.latitude!,
                longitude: visit.longitude!,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Loading address...",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  );
                }

                final address = snapshot.data;
                if (address == null || address == "Address unavailable") {
                  return const SizedBox.shrink(); // address இல்லனா ஒன்னும் காட்ட வேண்டாம்
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined, size: 18, color: Colors.red.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // PERSON
          if (visit.person_name != null && visit.person_name!.trim().isNotEmpty)
            _InfoRow(icon: Icons.person_outline, label: 'Person', value: visit.person_name!),

          // REASON
          if (visit.reason_of_visit != null && visit.reason_of_visit!.trim().isNotEmpty)
            _InfoRow(icon: Icons.assignment_outlined, label: 'Reason', value: visit.reason_of_visit!),

          if (visit.remarks != null && visit.remarks!.trim().isNotEmpty)
            _InfoRow(icon: Icons.notes_outlined, label: 'Remarks', value: visit.remarks!),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}