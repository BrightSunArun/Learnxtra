// ignore_for_file: deprecated_member_use

import 'package:LearnXtraAdmin/constants/app_colors.dart';
import 'package:LearnXtraAdmin/services/api_services.dart';
import 'package:flutter/material.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  bool _isLoading = true;
  List<dynamic> _parents = [];
  String? _errorMessage;

  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadParents();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> get _filteredParents {
    final term = _searchController.text.trim().toLowerCase();
    if (term.isEmpty) return _parents;
    return _parents.where((p) {
      final map = p as Map<String, dynamic>;
      final name = (map['full_name'] as String?)?.toLowerCase() ?? '';
      final phone = (map['mobile_number']?.toString() ?? '')
          .replaceAll(RegExp(r'\s'), '');
      final termDigits = term.replaceAll(RegExp(r'\D'), '');
      return name.contains(term) ||
          phone.contains(term) ||
          (termDigits.isNotEmpty && phone.contains(termDigits));
    }).toList();
  }

  Future<void> _loadParents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getParentsChildDetail();

      if (response != null && response['success'] == true) {
        setState(() {
          _parents = response['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load parent accounts';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  String _getSubtitle(Map<String, dynamic> parent) {
    final mobile = parent['mobile_number'] ?? '—';
    final childrenCount = parent['children_count'] ?? 0;
    return '+91 $mobile • $childrenCount Children Linked';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gray200.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: CircularProgressIndicator(
            color: AppColors.primaryTeal,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 18, color: Colors.redAccent),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _loadParents,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_parents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: Text(
            'No parent accounts found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or phone number',
              prefixIcon:
                  const Icon(Icons.search, color: AppColors.primaryTeal),
              filled: true,
              fillColor: AppColors.gray200,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (_filteredParents.isEmpty)
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'No accounts match your search',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _filteredParents.length,
              itemBuilder: (context, index) {
                final parent = _filteredParents[index] as Map<String, dynamic>;

                final fullName =
                    (parent['full_name'] as String?)?.trim() ?? '—';
                final displayName =
                    fullName.isNotEmpty ? fullName : 'Parent User';

                final hasPin =
                    parent['parent_pin'] != null && parent['parent_pin'] != '';
                final statusText = hasPin ? 'Active' : 'Pending Setup';
                final statusColor = hasPin ? AppColors.success : Colors.orange;

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.backgroundCream,
                    radius: 28,
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primaryTeal,
                      size: 32,
                    ),
                  ),
                  title: Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    _getSubtitle(parent),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  onTap: () {
                    // Optional: navigate to detail screen in future
                    // Navigator.push(...);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
