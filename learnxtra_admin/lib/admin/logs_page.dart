import 'package:LearnXtraAdmin/constants/app_colors.dart';
import 'package:LearnXtraAdmin/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  List<dynamic> _sosRequests = [];
  bool _isLoading = true;
  String? _errorMessage;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadSosRequests();
  }

  Future<void> _loadSosRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _apiService.getSosRequests();

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response != null &&
          response['status'] == true &&
          response['data'] is List) {
        _sosRequests = response['data'] as List;
      } else {
        _errorMessage =
            response?['message'] as String? ?? 'Failed to load SOS requests';
      }
    });
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.coralRed;
      default:
        return Colors.orange;
    }
  }

  String _orDash(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '—';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "SOS requests & Reports",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                    color: AppColors.primaryTeal,
                  ))
                : _errorMessage != null
                    ? _buildError()
                    : _sosRequests.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: _loadSosRequests,
                            child: ListView.builder(
                              itemCount: _sosRequests.length,
                              itemBuilder: (context, index) {
                                final item =
                                    _sosRequests[index] as Map<String, dynamic>;
                                return _buildSosCard(item);
                              },
                            ),
                          ),
          )
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.circleExclamation,
            color: AppColors.coralRed,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.gray800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _loadSosRequests,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        'No SOS requests yet',
        style: TextStyle(
          color: AppColors.gray800,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSosCard(Map<String, dynamic> item) {
    final status = item['status'] as String?;
    final childName = _orDash(item['child_name']);
    final parentName = _orDash(item['parent_name']);
    final parentPhone = _orDash(item['parent_phone']);
    final approvedBy = _orDash(item['approved_by']);
    final approvedAt = _orDash(item['approved_at']);
    final createdAt = item['created_at'] as String? ?? '—';

    String subtitle = 'Parent: $parentName • $parentPhone';
    if (status == 'approved' && approvedBy != '—') {
      subtitle = 'Approved by $approvedBy • $approvedAt';
    } else if (status == 'rejected') {
      subtitle = 'Rejected';
    }

    return Card(
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: AppColors.gray200.withOpacity(0.5)),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        leading: Icon(
          FontAwesomeIcons.circleExclamation,
          color: _statusColor(status),
        ),
        title: Text('SOS Request • $childName'),
        subtitle: Text(subtitle),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatDate(createdAt),
              style: const TextStyle(
                color: AppColors.gray600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status ?? 'pending',
                style: TextStyle(
                  color: _statusColor(status),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String value) {
    if (value == '—') return value;
    try {
      final dt = DateTime.tryParse(value);
      if (dt != null) {
        return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}
    return value;
  }
}
