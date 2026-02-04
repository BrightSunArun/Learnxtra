// ignore_for_file: use_build_context_synchronously, avoid_print, deprecated_member_use

import 'package:LearnXtraParent/screens/profile_setup/parent_profile_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar.dart';

class ParentProfileDetailsScreen extends StatefulWidget {
  const ParentProfileDetailsScreen({super.key});

  @override
  State<ParentProfileDetailsScreen> createState() =>
      _ParentProfileDetailsScreenState();
}

class _ParentProfileDetailsScreenState
    extends State<ParentProfileDetailsScreen> {
  bool isLoading = true;
  Map<String, dynamic>? _parentData;
  String? errorMessage;
  String? mobileNumber; // remains nullable

  late final ApiService apiService;

  @override
  void initState() {
    super.initState();
    apiService = Get.find<ApiService>();
    _fetchParentProfile();
  }

  Future<void> _fetchParentProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final storedMobile = prefs.getString('parentMobileNumber');

    print("Mobile number from prefs: $storedMobile");

    setState(() {
      mobileNumber = storedMobile; // ← save it here
      isLoading = true;
      errorMessage = null;
    });

    if (storedMobile == null || storedMobile.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = "Mobile number not found in storage.";
      });
      if (mounted) {
        getSnackbar(
          title: "Warning",
          message: "Please log in again to restore your session.",
        );
      }
      return;
    }

    try {
      final profile = await apiService.getParentProfile();

      if (profile.isEmpty) {
        throw Exception('Empty profile response');
      }

      setState(() {
        _parentData = profile;
      });
    } catch (e) {
      print("Error fetching parent profile: $e");
      setState(() {
        errorMessage = "Failed to load profile. Please try again.";
      });
      if (mounted) {
        getSnackbar(
          title: "Error",
          message: errorMessage ?? "Something went wrong",
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _goToEditScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ParentProfileSetupScreen(
          calledFrom: "settings",
        ),
      ),
    );
    if (mounted && result == true) {
      // optional: only refresh if edit saved
      _fetchParentProfile();
    }
  }

  String _getInitials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) {
      return '?';
    }

    final parts = fullName.trim().split(RegExp(r'\s+'));
    String initials = '';

    for (var p in parts.take(2)) {
      if (p.isNotEmpty) {
        initials += p[0].toUpperCase();
      }
    }

    return initials.isEmpty ? '?' : initials;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        title: const Text(
          "My Profile",
          style: TextStyle(
            wordSpacing: 1.6,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryTeal,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!isLoading && _parentData != null)
            PopupMenuButton<String>(
              color: Colors.white,
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'edit') _goToEditScreen();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20, color: Colors.black87),
                      SizedBox(width: 16),
                      Text("Edit Profile",
                          style: TextStyle(color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 64, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 16, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: _fetchParentProfile,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Retry"),
                        ),
                      ],
                    ),
                  )
                : _parentData == null
                    ? const Center(child: Text("No profile data available"))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor:
                                        AppColors.primaryTeal.withOpacity(0.15),
                                    backgroundImage:
                                        _parentData!['profileImageUrl'] !=
                                                    null &&
                                                (_parentData!['profileImageUrl']
                                                            as String?)
                                                        ?.isNotEmpty ==
                                                    true
                                            ? NetworkImage(
                                                _parentData!['profileImageUrl']
                                                    as String)
                                            : null,
                                    child: _parentData!['profileImageUrl'] ==
                                                null ||
                                            (_parentData!['profileImageUrl']
                                                        as String?)
                                                    ?.isEmpty ==
                                                true
                                        ? Text(
                                            _getInitials(
                                              _parentData!['fullName']
                                                  as String?,
                                            ),
                                            style: TextStyle(
                                              fontSize: 52,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primaryTeal,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    (_parentData!['fullName'] as String?) ??
                                        'Unknown',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            _buildInfoCard(
                              title: "Contact Information",
                              children: [
                                _buildDetailRow("Email",
                                    (_parentData!['email'] as String?) ?? "—"),
                                _buildDetailRow(
                                  "Mobile",
                                  mobileNumber ?? "Not available",
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildInfoCard(
                              title: "Address",
                              children: [
                                _buildDetailRow(
                                    "Address",
                                    (_parentData!['address'] as String?) ??
                                        "—"),
                                _buildDetailRow(
                                    "Pin Code",
                                    (_parentData!['pinCode'] as String?) ??
                                        "—"),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (_parentData!['linkedChildren'] != null &&
                                (_parentData!['linkedChildren'] as List)
                                    .isNotEmpty) ...[
                              _buildInfoCard(
                                title: "Linked Children",
                                children: [
                                  _buildDetailRow(
                                    "Count",
                                    "${(_parentData!['linkedChildren'] as List).length}",
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryTeal,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.gray700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
