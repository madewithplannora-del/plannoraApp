import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/event_request_model.dart';
import '../../providers/request_provider.dart';
import '../common/widgets/custom_button.dart';
import '../common/widgets/loading_view.dart';
import '../common/widgets/status_badge.dart';

class EventDetailsScreen extends StatefulWidget {
  final String requestId;

  const EventDetailsScreen({super.key, required this.requestId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RequestProvider>().fetchRequestById(widget.requestId);
    });
  }

  Future<void> _handleRemindAttendance() async {
    final req = context.read<RequestProvider>();
    final msg = await req.remindAttendance(widget.requestId);

    if (!mounted) return;

    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (req.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(req.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = context.watch<RequestProvider>();
    final event = req.currentRequest;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: req.isLoading && event == null
          ? const LoadingView(message: 'Loading event information...')
          : event == null
              ? Center(
                  child: Text(
                    req.errorMessage ?? 'Event not found',
                    style: const TextStyle(color: AppColors.error),
                  ),
                )
              : _buildContent(event, req),
    );
  }

  Widget _buildContent(EventRequestModel event, RequestProvider req) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy');
    final formattedDate =
        event.date != null ? dateFormat.format(event.date!) : 'Date not set';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusBadge(label: event.category),
                    Text(
                      '₹${event.pay.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  event.eventDetails,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.calendar_month_outlined,
                  title: 'Date',
                  value: formattedDate,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.access_time_outlined,
                  title: 'Shift Hours',
                  value: event.time,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.location_on_outlined,
                  title: 'Location',
                  value: '${event.location}, ${event.city}, ${event.state} - ${event.pincode}',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.group_outlined,
                  title: 'Required Candidates',
                  value: '${event.noOfCandidates} candidates',
                ),
                if (event.additionalDescription.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Additional Instructions:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.additionalDescription,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_user_outlined,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Attendance Verification',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Have hired freelancers arrived at the venue? You can send them an instant push/email reminder to submit their check-in code.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Send Attendance Reminder',
                  icon: Icons.notifications_active_outlined,
                  isLoading: req.isLoading,
                  onPressed: _handleRemindAttendance,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
