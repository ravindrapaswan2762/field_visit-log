import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../../../../core/services/photo_service.dart';
import '../../../../core/utils/validators.dart';

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
  final _photoService = PhotoService();
  String? _photoPath;

  static final _dateTimeFormat = DateFormat('MMM d, yyyy • hh:mm a');

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final path = await _photoService.pickAndSavePhoto(source: source);
    if (path != null && mounted) {
      setState(() => _photoPath = path);
    }
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
    final nowFormatted = _dateTimeFormat.format(DateTime.now());

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Main White Form Card ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x060F172A),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Customer Name ────────────────────────────────────────
                _buildHeader(
                  icon: Icons.person_outline,
                  label: 'Customer Name',
                  isRequired: true,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('customer_name_field'),
                  controller: _nameController,
                  enabled: !widget.isLoading,
                  textCapitalization: TextCapitalization.words,
                  validator: Validators.customerName,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Acme Corporation',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '2–80 characters',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),

                const SizedBox(height: 18),

                // ── 2. Visit Notes ──────────────────────────────────────────
                _buildHeader(
                  icon: Icons.article_outlined,
                  label: 'Visit Notes',
                  isRequired: true,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('notes_field'),
                  controller: _notesController,
                  enabled: !widget.isLoading,
                  minLines: 4,
                  maxLines: 6,
                  maxLength: 500,
                  validator: Validators.notes,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A), height: 1.4),
                  decoration: InputDecoration(
                    hintText: 'Discussed the new product features and pricing. Customer is interested in the premium plan...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    filled: true,
                    fillColor: Colors.white,
                    counterText: '',
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '5–500 characters',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),

                const SizedBox(height: 18),

                // ── 3. Visit Date & Time ────────────────────────────────────
                _buildHeader(
                  icon: Icons.calendar_today_outlined,
                  label: 'Visit Date & Time',
                  isRequired: false,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        nowFormatted,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Captured automatically when you save',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),

                const SizedBox(height: 18),

                // ── 4. Photo Attachment (Optional) ──────────────────────────
                _buildHeader(
                  icon: Icons.camera_alt_outlined,
                  label: 'Photo Attachment',
                  suffix: ' (Optional)',
                  isRequired: false,
                ),
                const SizedBox(height: 10),

                if (_photoPath != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 52,
                            height: 52,
                            child: kIsWeb
                                ? Image.network(
                                    _photoPath!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                  )
                                : Image.file(
                                    File(_photoPath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '1 photo selected',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${p.basename(_photoPath!)} • 2.4 MB',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                          onPressed: widget.isLoading ? null : () => setState(() => _photoPath = null),
                          tooltip: 'Remove photo',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Action buttons: Gallery & Camera
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.isLoading ? null : () => _pickPhoto(ImageSource.gallery),
                        icon: const Icon(Icons.image_outlined, size: 17, color: Color(0xFF2563EB)),
                        label: const Text(
                          'Choose from Gallery',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.isLoading ? null : () => _pickPhoto(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined, size: 17, color: Color(0xFF2563EB)),
                        label: const Text(
                          'Take Photo',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Bottom Information Banner ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.info_outline, size: 17, color: Color(0xFF2563EB)),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your visit will be saved locally even without an internet connection.\nIt will sync automatically when connectivity returns.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF1E40AF),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Save Visit Button ─────────────────────────────────────────────
          ElevatedButton.icon(
            key: const Key('save_visit_button'),
            onPressed: widget.isLoading ? null : _submit,
            icon: widget.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.article_outlined, size: 18, color: Colors.white),
            label: Text(
              widget.isLoading ? 'Saving…' : 'Save Visit',
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({
    required IconData icon,
    required String label,
    String? suffix,
    required bool isRequired,
  }) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF2563EB)),
        ),
        const SizedBox(width: 8),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEF4444),
                  ),
                ),
              if (suffix != null)
                TextSpan(
                  text: suffix,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF64748B),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
