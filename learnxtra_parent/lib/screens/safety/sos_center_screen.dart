// ignore_for_file: deprecated_member_use, avoid_print

import 'package:LearnXtraParent/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';

class SOSCenterScreen extends StatefulWidget {
  final String calledFrom;

  const SOSCenterScreen({
    super.key,
    required this.calledFrom,
  });

  @override
  State<SOSCenterScreen> createState() => _SOSCenterScreenState();
}

class _SOSCenterScreenState extends State<SOSCenterScreen> {
  final ApiService _apiService = Get.find<ApiService>();

  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _approvedRequests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSosRequests();
  }

  Future<void> _fetchSosRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requests = await _apiService.getSosRequests();
      final allRequests = (requests).cast<Map<String, dynamic>>().toList();

      print(" \n\n\n This is the sos request: $allRequests");

      final pending = allRequests
          .where((req) => req['status']?.toString().toLowerCase() == 'pending')
          .toList();

      final approved = allRequests
          .where((req) => req['status']?.toString().toLowerCase() == 'approved')
          .toList();

      setState(() {
        _pendingRequests = pending;
        _approvedRequests = approved;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '').trim();
      });
    }
  }

  Future<void> _approveRequest(String requestId) async {
    try {
      final response = await _apiService.approveSosRequest(requestId);
      print(" \n\n\n This is the sos request approve: $response");
      getSnackbar(
        title: "Success",
        message: 'Request approved',
      );
      _fetchSosRequests();
    } catch (e) {
      getSnackbar(
        title: "Error",
        message: 'Failed to approve',
      );
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      final response = await _apiService.rejectSosRequest(requestId);
      print(" \n\n\n This is the sos request reject: $response");
      getSnackbar(
        title: "Success",
        message: 'Request rejected',
      );
      _fetchSosRequests();
    } catch (e) {
      getSnackbar(
        title: "Error",
        message: 'Failed to reject',
      );
    }
  }

  String _formatTimeAgoIST(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'just now';

    try {
      DateTime utcTime = DateTime.parse(dateStr).toUtc();

      DateTime istTime = utcTime.add(
        const Duration(hours: 5, minutes: 30),
      );

      final nowIST = DateTime.now();

      final diff = nowIST.difference(istTime);

      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
      if (diff.inHours < 24) return '${diff.inHours} hrs ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';

      return '${istTime.day}/${istTime.month}/${istTime.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildRequestCard(Map<String, dynamic> req, {bool isPending = true}) {
    final childDisplay = req['child']['name'].toString();
    final createdAt = req['created_at']?.toString() ?? '';
    final approvedAt = req['approved_at']?.toString() ?? createdAt;
    final requestId = req['id']?.toString() ?? '';

    final displayTime = isPending ? createdAt : approvedAt;

    return FadeInUp(
      child: Container(
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
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isPending ? Icons.person : Icons.check_circle,
                    color: isPending ? Colors.teal : Colors.green,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      childDisplay,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isPending
                            ? Colors.teal.shade800
                            : Colors.green.shade800,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPending
                          ? Colors.orange.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isPending ? "PENDING" : "APPROVED",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isPending
                            ? Colors.orange.shade900
                            : Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isPending
                    ? "Requested ${_formatTimeAgoIST(displayTime)}"
                    : "Approved ${_formatTimeAgoIST(displayTime)}",
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
              if (isPending) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveRequest(requestId),
                        icon: const Icon(
                          Icons.check_circle_outline,
                          size: 20,
                          color: Colors.white,
                        ),
                        label: const Text("Approve"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectRequest(requestId),
                        icon: Icon(
                          Icons.cancel_outlined,
                          size: 20,
                          color: Colors.redAccent.shade700,
                        ),
                        label: Text(
                          "Reject",
                          style: TextStyle(color: Colors.redAccent.shade700),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.redAccent.shade700),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        title: const Text(
          "SOS Emergency Requests",
          style: TextStyle(
            wordSpacing: 1.6,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildContent(),
            ),
            if (widget.calledFrom == "settings")
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Go Back",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(
                "Error",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Try Again"),
                onPressed: _fetchSosRequests,
              ),
            ],
          ),
        ),
      );
    }

    final hasPending = _pendingRequests.isNotEmpty;
    final hasApproved = _approvedRequests.isNotEmpty;

    if (!hasPending && !hasApproved) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInDown(
                child: Icon(
                  Icons.warning_amber_rounded,
                  size: 100,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "No SOS Requests",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "Emergency or approved requests from your children will appear here.",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSosRequests,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          if (hasPending) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              child: Text(
                "Pending Requests",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            ..._pendingRequests.map(
              (req) => _buildRequestCard(
                req,
                isPending: true,
              ),
            ),
          ],
          if (hasApproved) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(8, hasPending ? 32 : 16, 8, 8),
              child: Text(
                "Approved Requests",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            ..._approvedRequests.map(
              (req) => _buildRequestCard(
                req,
                isPending: false,
              ),
            ),
          ],
          // Extra bottom padding so content doesn't get hidden under the button
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
