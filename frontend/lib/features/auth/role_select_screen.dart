import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/freelancer_provider.dart';
import '../common/widgets/custom_button.dart';
import '../common/widgets/custom_text_field.dart';
import '../customer/customer_nav_screen.dart';
import '../freelancer/freelancer_nav_screen.dart';
import 'login_screen.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  bool _isLoading = false;

  Future<void> _selectCustomer() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final cust = context.read<CustomerProvider>();

    await auth.setActiveRole('customer');
    final hasProfile = await cust.fetchProfile();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (hasProfile) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CustomerNavScreen()),
      );
    } else {
      _showCustomerSetupSheet();
    }
  }

  Future<void> _selectFreelancer() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final free = context.read<FreelancerProvider>();

    await auth.setActiveRole('freelancer');
    final hasProfile = await free.fetchProfile();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (hasProfile) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const FreelancerNavScreen()),
      );
    } else {
      _showFreelancerSetupSheet();
    }
  }

  void _showCustomerSetupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _CustomerSetupSheet(),
    );
  }

  void _showFreelancerSetupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const _FreelancerSetupSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Choose Role'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await auth.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'Welcome, ${auth.user?.username ?? 'Planner'}!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'How would you like to use PlanEra today?',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _buildRoleCard(
                      title: 'Event Organizer / Customer',
                      subtitle:
                          'Post event requirements, hire qualified freelancers, verify candidate check-ins with attendance codes, and track event progress.',
                      icon: Icons.business_center_outlined,
                      accentColor: AppColors.primary,
                      onTap: _isLoading ? null : _selectCustomer,
                    ),
                    const SizedBox(height: 20),
                    _buildRoleCard(
                      title: 'Freelancer / Talent',
                      subtitle:
                          'Receive curated event invitations matching your skills, accept shifts, enter check-in attendance codes, and raise redflags if necessary.',
                      icon: Icons.person_search_outlined,
                      accentColor: AppColors.secondary,
                      onTap: _isLoading ? null : _selectFreelancer,
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 16, color: accentColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerSetupSheet extends StatefulWidget {
  const _CustomerSetupSheet();

  @override
  State<_CustomerSetupSheet> createState() => _CustomerSetupSheetState();
}

class _CustomerSetupSheetState extends State<_CustomerSetupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null) {
      setState(() => _imagePath = file.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final cust = context.read<CustomerProvider>();
    final success = await cust.createProfile(
      phoneno: _phoneController.text,
      state: _stateController.text,
      city: _cityController.text,
      pincode: _pincodeController.text,
      imagePath: _imagePath,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(); // close sheet
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CustomerNavScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cust = context.watch<CustomerProvider>();

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
                  const Text(
                    'Setup Customer Profile',
                    style: TextStyle(
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
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryContainer,
                    child: _imagePath != null
                        ? const Icon(Icons.check, color: AppColors.primary, size: 36)
                        : const Icon(Icons.add_a_photo_outlined,
                            color: AppColors.primary, size: 32),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  _imagePath != null ? 'Photo Selected' : 'Add Profile Photo (Optional)',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              if (cust.errorMessage != null) ...[
                Text(
                  cust.errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
                const SizedBox(height: 12),
              ],
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'e.g. 9876543210',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (v) => v == null || v.trim().isEmpty ? 'Phone required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _cityController,
                      label: 'City',
                      hint: 'City',
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _stateController,
                      label: 'State',
                      hint: 'State',
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _pincodeController,
                label: 'Pincode',
                hint: 'e.g. 400001',
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.trim().isEmpty ? 'Pincode required' : null,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Save & Continue',
                isLoading: cust.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FreelancerSetupSheet extends StatefulWidget {
  const _FreelancerSetupSheet();

  @override
  State<_FreelancerSetupSheet> createState() => _FreelancerSetupSheetState();
}

class _FreelancerSetupSheetState extends State<_FreelancerSetupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _linkedinController = TextEditingController();
  String _category = 'Professional';
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null) {
      setState(() => _imagePath = file.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final free = context.read<FreelancerProvider>();
    final success = await free.createProfile(
      phone: _phoneController.text,
      category: _category,
      state: _stateController.text,
      city: _cityController.text,
      pincode: _pincodeController.text,
      linkedin: _linkedinController.text,
      imagePath: _imagePath,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(); // close sheet
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const FreelancerNavScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final free = context.watch<FreelancerProvider>();

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
                  const Text(
                    'Setup Freelancer Profile',
                    style: TextStyle(
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
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.secondaryContainer,
                    child: _imagePath != null
                        ? const Icon(Icons.check, color: AppColors.secondary, size: 36)
                        : const Icon(Icons.add_a_photo_outlined,
                            color: AppColors.secondary, size: 32),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  _imagePath != null ? 'Photo Selected' : 'Add Profile Photo (Optional)',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
              if (free.errorMessage != null) ...[
                Text(
                  free.errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
                const SizedBox(height: 12),
              ],
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'e.g. 9876543210',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
                validator: (v) => v == null || v.trim().isEmpty ? 'Phone required' : null,
              ),
              const SizedBox(height: 12),
              const Text(
                'Skill Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'Professional', child: Text('Professional')),
                  DropdownMenuItem(value: 'Cultural', child: Text('Cultural')),
                  DropdownMenuItem(value: 'Private', child: Text('Private')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _cityController,
                      label: 'City',
                      hint: 'City',
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _stateController,
                      label: 'State',
                      hint: 'State',
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _pincodeController,
                label: 'Pincode',
                hint: 'e.g. 400001',
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _linkedinController,
                label: 'LinkedIn Profile (Optional)',
                hint: 'https://linkedin.com/in/...',
                keyboardType: TextInputType.url,
                prefixIcon: Icons.link,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Save & Continue',
                isLoading: free.isLoading,
                backgroundColor: AppColors.secondary,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
