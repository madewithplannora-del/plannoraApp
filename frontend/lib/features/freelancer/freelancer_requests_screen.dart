import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/freelancer_provider.dart';
import '../../providers/request_provider.dart';
import '../common/widgets/custom_button.dart';
import '../common/widgets/empty_view.dart';
import '../common/widgets/status_badge.dart';
import 'attendance_modal.dart';

class FreelancerRequestsScreen extends StatefulWidget {
  const FreelancerRequestsScreen({super.key});

  @override
  State<FreelancerRequestsScreen> createState() =>
      _FreelancerRequestsScreenState();
}

class _FreelancerRequestsScreenState extends State<FreelancerRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FreelancerProvider>().fetchProfile();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openAttendanceFor(String requestId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AttendanceModal(initialRequestId: requestId),
    );
  }

  Future<void> _handleAccept(String requestId) async {
    final req = context.read<RequestProvider>();
    final free = context.read<FreelancerProvider>();
    final success = await req.freelancerAccept(requestId);

    if (!mounted) return;

    if (success) {
      await free.fetchProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shift accepted successfully!'),
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

  Future<void> _handleReject(String requestId) async {
    final req = context.read<RequestProvider>();
    final free = context.read<FreelancerProvider>();
    final success = await req.freelancerReject(requestId);

    if (!mounted) return;

    if (success) {
      await free.fetchProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request declined.'),
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
    final free = context.watch<FreelancerProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Jobs & Shift Requests'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.secondary,
          tabs: [
            Tab(text: 'Invited (${free.receivedRequestIds.length})'),
            Tab(text: 'Accepted (${free.acceptedRequestIds.length})'),
            Tab(text: 'History (${free.attendedRequestIds.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReceivedTab(free),
          _buildAcceptedTab(free),
          _buildHistoryTab(free),
        ],
      ),
    );
  }

  Widget _buildReceivedTab(FreelancerProvider free) {
    final ids = free.receivedRequestIds;

    if (ids.isEmpty) {
      return const EmptyView(
        icon: Icons.inbox_outlined,
        title: 'No Pending Invitations',
        message: 'When event hosts require your skill category in your city, requests will appear here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: ids.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final reqId = ids[index].toString();
        return _buildJobCard(
          requestId: reqId,
          statusLabel: 'Pending Invitation',
          actions: [
            Expanded(
              child: CustomButton(
                text: 'Decline',
                isOutlined: true,
                onPressed: () => _handleReject(reqId),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Accept Shift',
                backgroundColor: AppColors.secondary,
                onPressed: () => _handleAccept(reqId),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAcceptedTab(FreelancerProvider free) {
    final ids = free.acceptedRequestIds;

    if (ids.isEmpty) {
      return const EmptyView(
        icon: Icons.event_available_outlined,
        title: 'No Accepted Shifts',
        message: 'Accept incoming invitations from the "Invited" tab to confirm your booking.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: ids.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final reqId = ids[index].toString();
        return _buildJobCard(
          requestId: reqId,
          statusLabel: 'Confirmed Shift',
          actions: [
            Expanded(
              child: CustomButton(
                text: 'Enter Attendance Code',
                icon: Icons.check_circle_outline,
                backgroundColor: AppColors.secondary,
                onPressed: () => _openAttendanceFor(reqId),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryTab(FreelancerProvider free) {
    final attendedIds = free.attendedRequestIds;

    if (attendedIds.isEmpty) {
      return const EmptyView(
        icon: Icons.history_outlined,
        title: 'No Completed Shifts Yet',
        message: 'Completed and verified event attendances will show here in your history.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: attendedIds.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final reqId = attendedIds[index].toString();
        return _buildJobCard(
          requestId: reqId,
          statusLabel: 'Attended & Verified',
          actions: [],
        );
      },
    );
  }

  Widget _buildJobCard({
    required String requestId,
    required String statusLabel,
    required List<Widget> actions,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(label: statusLabel),
                Text(
                  'ID: ...${requestId.length > 6 ? requestId.substring(requestId.length - 6) : requestId}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Event Assignment #$requestId',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Assigned through PlanEra automated staffing pool matching your location and qualifications.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(children: actions),
            ],
          ],
        ),
      ),
    );
  }
}
