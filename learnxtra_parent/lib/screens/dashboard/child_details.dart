// ignore_for_file: use_build_context_synchronously, avoid_print, deprecated_member_use

import 'package:LearnXtraParent/screens/dashboard/add_child_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../utils/snackbar.dart';

class ChildDetailsScreen extends StatefulWidget {
  final String childId;

  const ChildDetailsScreen({
    super.key,
    required this.childId,
  });

  @override
  State<ChildDetailsScreen> createState() => _ChildDetailsScreenState();
}

class _ChildDetailsScreenState extends State<ChildDetailsScreen> {
  bool isLoading = true;
  bool isDeleting = false;
  Map<String, dynamic>? _childData;
  String? errorMessage;

  late final ApiService apiService;

  @override
  void initState() {
    super.initState();
    apiService = Get.find<ApiService>();
    _fetchChildDetails();
  }

  Future<void> _fetchChildDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await apiService.getChildDetails(widget.childId);

      if (response['success'] == true && response['child'] != null) {
        setState(() {
          _childData = response['child'];
        });
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      print("Error fetching child details: $e");
      setState(() {
        errorMessage = "Failed to load child details. Please try again.";
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

  Future<void> _deleteChild() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Child Profile"),
        content: const Text(
          "Are you sure you want to delete this child's profile?\n"
          "This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => isDeleting = true);

    try {
      final response = await apiService.deleteChild(widget.childId);

      if (response['success'] == true) {
        if (mounted) {
          getSnackbar(
            title: "Success",
            message: "Child profile deleted successfully",
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(response['message'] ?? 'Delete failed');
      }
    } catch (e) {
      print("Error deleting child: $e");
      if (mounted) {
        getSnackbar(
          title: "Error",
          message: "Failed to delete child profile. Please try again.",
        );
      }
    } finally {
      if (mounted) {
        setState(() => isDeleting = false);
      }
    }
  }

  Future<void> _goToEditScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddChildScreen(childId: widget.childId, isEdit: true),
      ),
    );

    if (result == true && mounted) {
      _fetchChildDetails();
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '—';
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd MMM yyyy • hh:mm a').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        title: const Text(
          "Child Details",
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
          if (!isLoading && _childData != null)
            PopupMenuButton<String>(
              color: Colors.white,
              icon: const Icon(Icons.more_vert, color: Colors.white),
              tooltip: "More options",
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _goToEditScreen();
                    break;
                  case 'delete':
                    _deleteChild();
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit,
                        size: 20,
                        color: Colors.black,
                      ),
                      SizedBox(width: 16),
                      Text(
                        "Edit Details",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: Colors.redAccent.shade700,
                      ),
                      SizedBox(width: 16),
                      Text(
                        "Delete Child",
                        style: TextStyle(
                          color: Colors.redAccent.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
        // actions: [
        //   if (!_isLoading && _childData != null) ...[
        //     IconButton(
        //       icon: const Icon(Icons.edit),
        //       tooltip: "Edit Details",
        //       onPressed: () {
        //         getSnackbar(
        //           title: "Error",
        //           message: "Failed to delete child profile. Please try again.",
        //         );
        //       },
        //       // onPressed: _isDeleting ? null : _goToEditScreen,
        //     ),
        //     IconButton(
        //       icon: _isDeleting
        //           ? const SizedBox(
        //               width: 20,
        //               height: 20,
        //               child: CircularProgressIndicator(
        //                 strokeWidth: 2.5,
        //                 color: Colors.white,
        //               ),
        //             )
        //           : const Icon(Icons.delete_outline),
        //       tooltip: "Delete Child",
        //       color: Colors.white,
        //       onPressed: () {
        //         getSnackbar(
        //           title: "Error",
        //           message: "Failed to delete child profile. Please try again.",
        //         );
        //       },
        //       // onPressed: (_isLoading || _isDeleting) ? null : _deleteChild,
        //     ),
        //   ],
        // ],
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
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: _fetchChildDetails,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Retry"),
                        ),
                      ],
                    ),
                  )
                : _childData == null
                    ? const Center(child: Text("No data available"))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header / Name
                            Center(
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor:
                                        AppColors.primaryTeal.withOpacity(0.15),
                                    child: Text(
                                      _childData!['name']
                                          .toString()
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryTeal,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _childData!['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            _buildInfoCard(
                              title: "Basic Information",
                              children: [
                                _buildDetailRow(
                                    "Grade", _childData!['grade'] ?? "—"),
                                _buildDetailRow(
                                    "Board", _childData!['board'] ?? "—"),
                                _buildDetailRow(
                                    "Age", _childData!['age'] ?? "—"),
                              ],
                            ),

                            const SizedBox(height: 24),

                            _buildInfoCard(
                              title: "School Details",
                              children: [
                                _buildDetailRow(
                                    "School", _childData!['schoolName'] ?? "—"),
                                _buildDetailRow("Location",
                                    _childData!['schoolAddress'] ?? "—"),
                                _buildDetailRow(
                                    "State", _childData!['state'] ?? "—"),
                              ],
                            ),

                            const SizedBox(height: 24),

                            _buildInfoCard(
                              title: "Other Information",
                              children: [
                                _buildDetailRow(
                                    "Subjects",
                                    _childData!['subjects'] != null
                                        ? (_childData!['subjects'] as List)
                                            .join(", ")
                                        : "Not specified"),
                                _buildDetailRow(
                                  "Added On",
                                  _formatDate(_childData!['createdAt']),
                                ),
                              ],
                            ),

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
            color: Colors.black.withOpacity(0.35),
            blurRadius: 8,
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
      padding: const EdgeInsets.symmetric(vertical: 8),
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
