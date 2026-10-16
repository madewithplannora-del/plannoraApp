import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/freelancer_provider.dart';
import '../../providers/request_provider.dart';
import '../common/widgets/custom_button.dart';
import '../common/widgets/custom_text_field.dart';

class AttendanceModal extends StatefulWidget {
  final String? initialRequestId;

  const AttendanceModal({super.key, this.initialRequestId});

  @override
  State<AttendanceModal> createState() => _AttendanceModalState();
}

class _AttendanceModalState extends State<AttendanceModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _requestIdController;
  final _codeController = TextEditingController();
  bool _isRedFlag = false;

  @override
  void initState() {
    super.initState();
    _requestIdController =
        TextEditingController(text: widget.initialRequestId ?? '');
  }

  @override
  void dispose() {
    _requestIdController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final req = context.read<RequestProvider>();
    final free = context.read<FreelancerProvider>();
    final requestId = _requestIdController.text.trim();
    final code = _codeController.text.trim();

    bool success;
    if (_isRedFlag) {
      success = await req.submitRedflag(requestId, code);
    } else {
      success = await req.submitAttendance(requestId, code);
    }

    if (!mounted) return;

    if (success) {
      await free.fetchProfile(); // reload progress
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isRedFlag
                ? 'Redflag recorded for event.'
                : 'Attendance successfully verified! Check-in confirmed.',
          ),
          backgroundColor: _isRedFlag ? AppColors.warning : AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = context.watch<RequestProvider>();

    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isRedFlag ? 'Raise Event Red Flag' : 'Venue Check-in',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _isRedFlag
                    ? 'Report an issue with the event venue or organizer using the venue verification code.'
                    : 'Enter the 6-digit attendance code provided by the event host at the venue.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              if (req.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    req.errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (widget.initialRequestId == null ||
                  widget.initialRequestId!.isEmpty) ...[
                CustomTextField(
                  controller: _requestIdController,
                  label: 'Event Request ID',
                  hint: 'Paste event request ID',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Request ID required' : null,
                ),
                const SizedBox(height: 16),
              ],
              CustomTextField(
                controller: _codeController,
                label: '6-Digit Verification Code',
                hint: 'e.g. 123456',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.pin_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Code required';
                  if (v.trim().length != 6) return 'Must be 6 digits';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _isRedFlag,
                    activeColor: AppColors.error,
                    onChanged: (val) {
                      setState(() => _isRedFlag = val ?? false);
                    },
                  ),
                  const Expanded(
                    child: Text(
                      'Flag this event (Red Flag report)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: _isRedFlag ? 'Submit Red Flag' : 'Verify Attendance',
                isLoading: req.isLoading,
                backgroundColor:
                    _isRedFlag ? AppColors.error : AppColors.secondary,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
