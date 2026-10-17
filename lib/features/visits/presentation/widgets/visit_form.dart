import 'package:flutter/material.dart';
import '../../../../core/utils/validators.dart';
import 'photo_attachment.dart';

class VisitForm extends StatefulWidget {
  const VisitForm({
    super.key,
    required this.onSave,
    this.isLoading = false,
  });

  final Future<void> Function({
    required String customerName,
    required String notes,
    String? photoPath,
  }) onSave;
  final bool isLoading;

  @override
  State<VisitForm> createState() => _VisitFormState();
}

class _VisitFormState extends State<VisitForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  String? _photoPath;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.onSave(
      customerName: _nameController.text,
      notes: _notesController.text,
      photoPath: _photoPath,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('customer_name_field'),
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Customer Name *',
              hintText: 'Enter customer name (2–80 characters)',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
            validator: Validators.customerName,
            enabled: !widget.isLoading,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('notes_field'),
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Visit Notes *',
              hintText: 'Enter visit notes (5–500 characters)',
              prefixIcon: Icon(Icons.notes_outlined),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            maxLength: 500,
            validator: Validators.notes,
            enabled: !widget.isLoading,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 8),
          PhotoAttachment(
            photoPath: _photoPath,
            enabled: !widget.isLoading,
            onPhotoSelected: (path) => setState(() => _photoPath = path),
            onPhotoRemoved: () => setState(() => _photoPath = null),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('save_visit_button'),
            onPressed: widget.isLoading ? null : _submit,
            icon: widget.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(widget.isLoading ? 'Saving…' : 'Save Visit'),
          ),
        ],
      ),
    );
  }
}
