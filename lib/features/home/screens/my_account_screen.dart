import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/api_service.dart';
import '../../../core/storage/account_profile_storage.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme.dart';
import '../bottomnavs/bottom_nav.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final ApiService _apiService = ApiService.instance;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _isEditing = false;
  String? _backendSyncMessage;
  String? _imagePath;
  String _userRole = 'Commenter';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final token = await SecureStorage.readToken();
    final isAuthenticated = token != null && token.trim().isNotEmpty;

    if (!isAuthenticated) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
      return;
    }

    Map<String, dynamic>? remotePortfolio;
    try {
      final userId = await SecureStorage.readUserId();
      remotePortfolio = await _apiService.fetchPortfolio(userId);
      print('Fetched portfolio from backend: $remotePortfolio');
      print('Fetched portfolio from backend: $remotePortfolio');
      _backendSyncMessage = null;
    } on ApiServiceException catch (error) {
      print('Failed to fetch portfolio from backend: ${error.message}');
      remotePortfolio = null;
      _backendSyncMessage = 'Failed to fetch portfolio from backend: ${error.message}';
    }

    final saved = await AccountProfileStorage.getProfile();
    final registered = await AccountProfileStorage.getRegisteredProfileForActiveUser();
    final activeIdentifier = await AccountProfileStorage.getActiveUserIdentifier();

    String? readRemote(List<String> keys) {
      if (remotePortfolio == null) return null;
      for (final key in keys) {
        final value = remotePortfolio[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      return null;
    }

    final remoteFirstName = readRemote(const ['first_name']);
    final remoteMiddleName = readRemote(const ['middle_name']);
    final remoteLastName = readRemote(const ['last_name']);
    final remoteJoinedName = [
      if (remoteFirstName != null) remoteFirstName,
      if (remoteMiddleName != null) remoteMiddleName,
      if (remoteLastName != null) remoteLastName,
    ].where((part) => part.isNotEmpty).join(' ');
    
    final remoteFullName =
        readRemote(const ['full_name', 'fullName', 'name']) ??
        (remoteJoinedName.isNotEmpty ? remoteJoinedName : '');

    final fullName =
      (remoteFullName.isNotEmpty ? remoteFullName : null) ??
      (saved?['fullName'] as String?) ??
      ((registered?['firstName'] as String?) != null ||
          (registered?['lastName'] as String?) != null
        ? '${(registered?['firstName'] as String?) ?? ''} ${(registered?['lastName'] as String?) ?? ''}'
          .trim()
        : '');
    final nameParts = fullName.trim().split(RegExp(r'\s+'));
    final firstName =
      remoteFirstName ??
      (saved?['firstName'] as String?) ??
      (registered?['firstName'] as String?) ??
      (nameParts.isNotEmpty ? nameParts.first : '');
    final lastName =
      remoteLastName ??
      (saved?['lastName'] as String?) ??
      (registered?['lastName'] as String?) ??
      (nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '');
    final savedRole = (saved?['role'] as String?)?.trim();
    final registeredRole = (registered?['role'] as String?)?.trim();
    final resolvedRole =
      (savedRole != null && savedRole.isNotEmpty)
        ? savedRole
        : (registeredRole != null && registeredRole.isNotEmpty)
          ? registeredRole
          : 'Commenter';

    if (!mounted) {
      return;
    }

    setState(() {
      _isAuthenticated = true;
      _firstNameController.text = firstName;
      _lastNameController.text = lastName;
      _phoneController.text =
        readRemote(const ['phone', 'phone_number', 'mobile_number']) ??
        (saved?['phone'] as String?) ??
        '';
      _emailController.text =
        readRemote(const ['email', 'username']) ??
          (saved?['email'] as String?) ??
          (registered?['email'] as String?) ??
          (activeIdentifier ?? '');
      _imagePath = saved?['imagePath'] as String?;
      _userRole = resolvedRole;
      _isLoading = false;
    });
  }

  Future<void> _pickProfileImage() async {
    if (!_isEditing) {
      return;
    }

    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );

    if (file == null || !mounted) {
      return;
    }

    setState(() => _imagePath = file.path);
  }

  Future<void> _saveProfile() async {
    final userId = await SecureStorage.readUserId();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final fullName = [firstName, lastName].where((part) => part.isNotEmpty).join(' ').trim();

    await AccountProfileStorage.saveProfile({
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'imagePath': _imagePath,
      'role': _userRole,
    });

    bool syncedToBackend = false;
    String? backendError;
    try {
      await _apiService.updatePortfolio(
        firstName: firstName,
        lastName: lastName,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        imagePath: _imagePath,
        role: _userRole,
      );
      syncedToBackend = true;
      _backendSyncMessage = null;
    } on ApiServiceException catch (error) {
      backendError = error.message;
      _backendSyncMessage = 'Saved locally only: ${error.message}';
    }

    if (!mounted) {
      return;
    }

    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          syncedToBackend
              ? 'Account updated successfully on backend.'
              : 'Saved locally, backend sync failed${backendError == null ? '' : ': $backendError'}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final maxHeight = constraints.maxHeight;
          final horizontalPadding = (maxWidth * 0.06).clamp(16.0, 32.0);
          final contentMaxWidth = maxWidth > 720 ? 720.0 : maxWidth;
          final headerRadius = (maxWidth * 0.06).clamp(16.0, 28.0);

          return SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(headerRadius),
                      bottomRight: Radius.circular(headerRadius),
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            bottom: 0,
                            child: Image.asset(
                              'assets/splash/backlogo.png',
                              width: 96,
                              height: 100,
                              fit: BoxFit.contain,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              maxHeight * 0.05,
                              horizontalPadding,
                              24,
                            ),
                            child: Column(
                              children: [
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => context.go('/settings'),
                                      icon: const Icon(
                                        Icons.arrow_back_ios,
                                        color: AppTheme.surface,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'My Account',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.headlineMedium?.copyWith(
                                          color: AppTheme.surface,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _isAuthenticated
                                          ? () => setState(() => _isEditing = !_isEditing)
                                          : null,
                                      icon: const Icon(
                                        Icons.edit,
                                        color: AppTheme.surface,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : !_isAuthenticated
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'Please sign in to access My Account.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.secondaryText,
                                  ),
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                horizontal: horizontalPadding,
                                vertical: 24
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: contentMaxWidth),
                                child: Column(
                                  children: [
                                    Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        GestureDetector(
                                          onTap: _pickProfileImage,
                                          child: CircleAvatar(
                                            radius: 30,
                                            backgroundColor: AppTheme.borderColor,
                                            backgroundImage:
                                                _imagePath != null && _imagePath!.isNotEmpty
                                                    ? FileImage(File(_imagePath!))
                                                    : null,
                                            child: _imagePath == null || _imagePath!.isEmpty
                                                ? const Icon(
                                                    Icons.person,
                                                    color: AppTheme.primaryDark,
                                                    size: 30,
                                                  )
                                                : null,
                                          ),
                                        ),
                                        // Material(
                                        //   color: Colors.transparent,
                                        //   child: InkWell(
                                        //     onTap: _pickProfileImage,
                                        //     borderRadius: BorderRadius.circular(999),
                                        //     child: Ink(
                                        //       width: 30,
                                        //       height: 30,
                                        //       decoration: BoxDecoration(
                                        //         color: AppTheme.primary,
                                        //         borderRadius: BorderRadius.circular(999),
                                        //         border: Border.all(
                                        //           color: AppTheme.surface,
                                        //           width: 2,
                                        //         ),
                                        //       ),
                                        //       child: const Icon(
                                        //         Icons.touch_app,
                                        //         size: 16,
                                        //         color: AppTheme.surface,
                                        //       ),
                                        //     ),
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${_firstNameController.text} ${_lastNameController.text}'.trim(),
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: AppTheme.primaryText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _emailController.text,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: AppTheme.secondaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Welcome to your account!',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.primaryText,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (_backendSyncMessage != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        _backendSyncMessage!,
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: AppTheme.statusRed,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 18),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surface,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: AppTheme.borderColor),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _buildInfoCard('First Name', _firstNameController.text),
                                          _buildInfoCard('Last Name', _lastNameController.text),
                                          _buildInfoCard('Phone Number', _phoneController.text),
                                          _buildInfoCard('Email Address', _emailController.text),
                                          _buildInfoCard('Role', _userRole),
                                        ],
                                      ),
                                    ),
                                    if (_isEditing) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.surface,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: AppTheme.borderColor),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Edit Information',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                color: AppTheme.primaryText,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            _buildEditField('First Name', _firstNameController),
                                            _buildEditField('Last Name', _lastNameController),
                                            _buildEditField('Phone Number', _phoneController),
                                            _buildEditField('Email Address', _emailController),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _saveProfile,
                                          child: const Text('Save Changes'),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 3,
        onIndexChanged: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/documents');
              break;
            case 2:
              context.go('/feedback');
              break;
            case 3:
              context.go('/settings');
              break;
          }
        },
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.secondaryText,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value.trim().isEmpty ? '-' : value,
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryText,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.secondaryText,
                ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            textAlign: TextAlign.start,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: AppTheme.inputField,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryText,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}