import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/visit_provider.dart';
import '../widgets/visit_form.dart';

class AddVisitScreen extends StatelessWidget {
  const AddVisitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Visit'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Consumer<VisitProvider>(
            builder: (context, provider, _) {
              return VisitForm(
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
              );
            },
          ),
        ),
      ),
    );
  }
}
