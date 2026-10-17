import '../../../../core/widgets/visit_image.dart';
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
    final path = await _photoService.pickAndSavePhoto(source: source, context: context);
    if (path != null && mounted) {
      setState(() => _photoPath = path);
    }
  }


  String _photoSubtitle(String path) {
    if (path.startsWith('data:image')) {
      return 'Camera photo • Captured';
    }
    return '${p.basename(path)} • 2.4 MB';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.onSave(
      customerName: _nameController.text,
      notes: _notesController.text,
      photoPath: _photoPath,
    );
  }

  // ── Shared UI helpers ────────────────────────────────────────────────────

  InputDecoration _inputDecoration({
    required String hint,
    double hintSize = 13.5,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    bool hideCounter = false,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: const Color(0xFF94A3B8), fontSize: hintSize),
      filled: true,
      fillColor: Colors.white,
      counterText: hideCounter ? '' : null,
      isDense: true,
      contentPadding: padding,
      border: border(const Color(0xFFDDE3EC)),
      enabledBorder: border(const Color(0xFFDDE3EC)),
      disabledBorder: border(const Color(0xFFE8EDF4)),
      focusedBorder: border(const Color(0xFF2563EB), 1.5),
      errorBorder: border(const Color(0xFFEF4444)),
      focusedErrorBorder: border(const Color(0xFFEF4444), 1.5),
    );
  }

  Widget _helper(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11.5, color: Color(0xFF7B8BA5)),
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFEDF1F7)),
    );
  }

  /// One form section: round icon on the left, label + content on the right.
  Widget _section({
    required IconData icon,
    required String label,
    String? suffix,
    required bool isRequired,
    required List<Widget> children,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F4F9),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF1E293B)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 30,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildLabel(label, suffix, isRequired),
                ),
              ),
              const SizedBox(height: 6),
              ...children,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String label, String? suffix, bool isRequired) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          if (isRequired)
            const TextSpan(
              text: '  *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE11D48),
              ),
            ),
          if (suffix != null)
            TextSpan(
              text: suffix,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
              ),
            ),
        ],
      ),
    );
  }

  Widget _photoPickerButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2563EB),
          ),
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFFFAFCFF),
        side: const BorderSide(color: Color(0xFFC9DBF7)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      ),
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
            padding: const EdgeInsets.fromLTRB(10, 12, 12, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5EAF2)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x080F172A),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Customer Name ────────────────────────────────────────
                _section(
                  icon: Icons.person_outline,
                  label: 'Customer Name',
                  isRequired: true,
                  children: [
                    TextFormField(
                      key: const Key('customer_name_field'),
                      controller: _nameController,
                      enabled: !widget.isLoading,
                      textCapitalization: TextCapitalization.words,
                      validator: Validators.customerName,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                          fontSize: 14.5, color: Color(0xFF0F172A)),
                      decoration: _inputDecoration(
                        hint: 'Acme Corporation',
                        hintSize: 14.5,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                      ),
                    ),
                    _helper('2–80 characters'),
                  ],
                ),

                _divider(),

                // ── 2. Visit Notes ──────────────────────────────────────────
                _section(
                  icon: Icons.article_outlined,
                  label: 'Visit Notes',
                  isRequired: true,
                  children: [
                    TextFormField(
                      key: const Key('notes_field'),
                      controller: _notesController,
                      enabled: !widget.isLoading,
                      minLines: 4,
                      maxLines: 6,
                      maxLength: 500,
                      validator: Validators.notes,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                        height: 1.5,
                      ),
                      decoration: _inputDecoration(
                        hint:
                            'Discussed the new product features and pricing. Customer is interested in the premium plan...',
                        hintSize: 13.5,
                        padding: const EdgeInsets.all(14),
                        hideCounter: true,
                      ),
                    ),
                    _helper('5–500 characters'),
                  ],
                ),

                _divider(),

                // ── 3. Visit Date & Time ────────────────────────────────────
                _section(
                  icon: Icons.calendar_today_outlined,
                  label: 'Visit Date & Time',
                  isRequired: false,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE3E9F1)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              nowFormatted,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                        ],
                      ),
                    ),
                    _helper('Captured automatically when you save'),
                  ],
                ),

                _divider(),

                // ── 4. Photo Attachment (Optional) ──────────────────────────
                _section(
                  icon: Icons.camera_alt_outlined,
                  label: 'Photo Attachment',
                  suffix: ' (Optional)',
                  isRequired: false,
                  children: [
                    if (_photoPath != null) ...[
                      CustomPaint(
                        painter: const _DashedBorderPainter(
                          color: Color(0xFFBBD2F5),
                          radius: 12,
                          dashLength: 5,
                          gapLength: 4,
                          strokeWidth: 1,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFCFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 58,
                                  height: 50,
                                  child: VisitImage(
                                    path: _photoPath!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image),
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
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _photoSubtitle(_photoPath!),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Material(
                                color: const Color(0xFFEDF1F7),
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: widget.isLoading
                                      ? null
                                      : () => setState(() => _photoPath = null),
                                  child: const Tooltip(
                                    message: 'Remove photo',
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: Icon(Icons.close,
                                          size: 16, color: Color(0xFF334155)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Action buttons: Gallery & Camera
                    Row(
                      children: [
                        Expanded(
                          flex: 11,
                          child: _photoPickerButton(
                            icon: Icons.image_outlined,
                            label: 'Choose from Gallery',
                            onPressed: widget.isLoading
                                ? null
                                : () => _pickPhoto(ImageSource.gallery),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 9,
                          child: _photoPickerButton(
                            icon: Icons.camera_alt_outlined,
                            label: 'Take Photo',
                            onPressed: widget.isLoading
                                ? null
                                : () => _pickPhoto(ImageSource.camera),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Bottom Information Banner ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F6FD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCE8F9)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 20, color: Color(0xFF2563EB)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your visit will be saved locally even without an internet connection.\nIt will sync automatically when connectivity returns.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF3D63C9),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Save Visit Button ─────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
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
                  : const Icon(Icons.save_outlined,
                      size: 20, color: Colors.white),
              label: Text(
                widget.isLoading ? 'Saving…' : 'Save Visit',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A82E6),
                disabledBackgroundColor: const Color(0xFF93B4EF),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws a dashed rounded-rectangle border (no extra package needed).
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    this.radius = 12,
    this.dashLength = 5,
    this.gapLength = 4,
    this.strokeWidth = 1,
  });

  final Color color;
  final double radius;
  final double dashLength;
  final double gapLength;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(strokeWidth / 2),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength ||
      old.strokeWidth != strokeWidth;
}