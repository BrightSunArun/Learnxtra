import 'package:LearnXtraChild/src/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  Map<String, dynamic>? parentData;
  Map<String, dynamic>? childData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataFromPrefs();
  }

  Future<void> _loadDataFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final parentJson = prefs.getString('parent_data');
    final childJson = prefs.getString('child_data');

    setState(() {
      if (parentJson != null && parentJson.isNotEmpty) {
        try {
          parentData = jsonDecode(parentJson) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('Parent JSON parse error: $e');
        }
      }

      if (childJson != null && childJson.isNotEmpty) {
        try {
          childData = jsonDecode(childJson) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('Child JSON parse error: $e');
        }
      }

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (parentData == null || childData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(
          child: Text('No profile data found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        toolbarHeight: 60,
        backgroundColor: AppColors.primaryTeal,
        title: const Text(
          'Profile Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        centerTitle: true,
        elevation: 16,
        surfaceTintColor: AppColors.primaryTeal,
        shadowColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            // ── Child Section ────────────────────────────────
            _buildSectionHeader('Child Information'),
            const SizedBox(height: 12),
            _buildInfoCard([
              _InfoRow(
                  icon: Icons.child_care,
                  label: 'Name',
                  value: childData!['name']?.toString() ?? '-'),
              _InfoRow(
                  icon: Icons.cake,
                  label: 'Age',
                  value: '${childData!['age']?.toString() ?? '-'} years'),
              _InfoRow(
                  icon: Icons.school,
                  label: 'Grade',
                  value: childData!['grade']?.toString() ?? '-'),
              _InfoRow(
                  icon: Icons.book,
                  label: 'Board',
                  value: childData!['board']?.toString() ?? '-'),
              _InfoRow(
                  icon: Icons.map,
                  label: 'State',
                  value: childData!['state']?.toString() ?? '-'),
              _InfoRow(
                  icon: Icons.account_balance,
                  label: 'School',
                  value: childData!['school_name']?.toString() ?? '-'),
              _InfoRow(
                icon: Icons.location_city,
                label: 'School Address',
                value: childData!['school_address']?.toString() ?? '-',
              ),
            ]),

            const SizedBox(height: 32),

            // ── Parent Section ───────────────────────────────
            _buildSectionHeader('Parent Information'),
            const SizedBox(height: 12),
            _buildInfoCard([
              _InfoRow(
                  icon: Icons.person,
                  label: 'Name',
                  value: parentData!['full_name']?.toString() ?? '-'),
              _InfoRow(
                  icon: Icons.phone,
                  label: 'Mobile',
                  value: parentData!['mobile_number']?.toString() ?? '-'),
              _InfoRow(
                  icon: Icons.email,
                  label: 'Email',
                  value: parentData!['email']?.toString() ?? '-'),
              _InfoRow(
                  icon: Icons.location_on,
                  label: 'Address',
                  value: parentData!['address']?.toString() ?? '-'),
              _InfoRow(
                  icon: Icons.pin,
                  label: 'PIN Code',
                  value: parentData!['pin_code']?.toString() ?? '-'),
            ]),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryTeal),
    );
  }

  Widget _buildInfoCard(List<_InfoRow> rows) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: rows),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primaryTeal, size: 22),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            ":",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
