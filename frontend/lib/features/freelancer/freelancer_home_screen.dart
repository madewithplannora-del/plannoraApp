import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/freelancer_provider.dart';
import '../common/widgets/custom_button.dart';
import '../common/widgets/status_badge.dart';
import 'attendance_modal.dart';

class FreelancerHomeScreen extends StatefulWidget {
  const FreelancerHomeScreen({super.key});

  @override
  State<FreelancerHomeScreen> createState() => _FreelancerHomeScreenState();
}

class _FreelancerHomeScreenState extends State<FreelancerHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FreelancerProvider>().fetchProfile();
    });
  }

  void _openAttendanceModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AttendanceModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final free = context.watch<FreelancerProvider>();
    final auth = context.watch<AuthProvider>();
    final profile = free.profile;

    final receivedCount = free.receivedRequestIds.length;
    final acceptedCount = free.acceptedRequestIds.length;
    final attendedCount = free.attendedRequestIds.length;
    final redflagCount = free.redflagRequestIds.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Freelancer Portal'),
            Text(
              'Logged in as ${auth.user?.username ?? 'Talent'}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => free.fetchProfile(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => free.fetchProfile(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Profile Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
                          backgroundImage: profile?.profilePictureUrl != null &&
                                  profile!.profilePictureUrl!.isNotEmpty
                              ? NetworkImage(profile.profilePictureUrl!)
                              : null,
                          child: profile?.profilePictureUrl == null ||
                                  profile!.profilePictureUrl!.isEmpty
                              ? const Icon(Icons.person,
                                  color: Colors.white, size: 28)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.user?.username ?? 'Talent Profile',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${profile?.city ?? 'City'}, ${profile?.state ?? 'State'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label: profile?.category ?? 'Professional',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFF334155), height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem('Received', receivedCount.toString(),
                            const Color(0xFF60A5FA)),
                        _buildStatItem('Accepted', acceptedCount.toString(),
                            const Color(0xFF34D399)),
                        _buildStatItem('Attended', attendedCount.toString(),
                            const Color(0xFFA78BFA)),
                        _buildStatItem('Flagged', redflagCount.toString(),
                            const Color(0xFFF87171)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Venue Check-in Action Card
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
                    const Row(
                      children: [
                        Icon(Icons.pin_drop,
                            color: AppColors.secondary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'On-Site Attendance Check-in',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Reached the event venue? Enter the 6-digit attendance code given by the host to confirm your check-in and get verified.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Enter Attendance Code',
                      icon: Icons.qr_code_scanner,
                      backgroundColor: AppColors.secondary,
                      onPressed: _openAttendanceModal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Smart Matching Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.bolt,
                        color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Automated Match Dispatch',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Whenever an event matching your "${profile?.category ?? 'Professional'}" category is posted in ${profile?.city ?? 'your area'}, invitations are dispatched automatically.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
