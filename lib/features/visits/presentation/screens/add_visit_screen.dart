import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/visit_provider.dart';
import '../widgets/visit_form.dart';

class AddVisitScreen extends StatelessWidget {
  const AddVisitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VisitProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Visit',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 1),
            Text(
              'Record a new customer visit',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: provider.isOnline == true ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: provider.isOnline == true ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: provider.isOnline == true ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  provider.isOnline == true ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: provider.isOnline == true ? const Color(0xFF15803D) : const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: VisitForm(
            isLoading: provider.isSaving,
            onSave: ({
              required String customerName,
              required String notes,
              String? photoPath,
            }) async {
              final success = await provider.addVisit(
                customerName: customerName,
                notes: notes,
                photoPath: photoPath,
              );

              if (!context.mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Visit saved locally. Will sync when online.'),
                    duration: Duration(seconds: 3),
                  ),
                );
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to save visit. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
