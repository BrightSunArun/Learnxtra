// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print

import 'package:LearnXtraParent/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../utils/api_exception.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;

  final ApiService _apiService = Get.find<ApiService>();

  static const int maxContacts = 10;

  bool get _canAddMore => _contacts.length < maxContacts;

  @override
  void initState() {
    super.initState();
    _fetchEmergencyContacts();
  }

  Future<void> _fetchEmergencyContacts() async {
    setState(() => _isLoading = true);

    try {
      final List<dynamic> rawList = await _apiService.getEmergencyContacts();

      setState(() {
        _contacts = rawList.map((item) {
          final id = item['id']?.toString() ?? '';
          final name = item['name']?.toString() ?? 'Unknown';
          final relation = item['relation']?.toString() ?? '';
          final phone = item['phone_number']?.toString() ?? '';

          final isActiveRaw = item['is_active'];
          final isActive = isActiveRaw is bool
              ? isActiveRaw
              : (isActiveRaw?.toString().toLowerCase() == 'true');

          final displayName = relation.isNotEmpty ? '$name ($relation)' : name;
          final displayPhone = phone.startsWith('+') ? phone : '+91 $phone';

          return {
            'id': id,
            'name': displayName,
            'rawName': name,
            'relation': relation,
            'phone': displayPhone,
            'rawPhone': phone,
            'isActive': isActive,
          };
        }).toList();

        _isLoading = false;
      });
    } on ApiException catch (e) {
      print("Fetch emergency contacts error: $e");
      setState(() => _isLoading = false);
      getSnackbar(
        title: "Error",
        message: "Failed to load contacts. Please try again.",
      );
    } catch (e, stack) {
      setState(() => _isLoading = false);
      print("Fetch emergency contacts error: $e");
      print("Stack: $stack");
      getSnackbar(
        title: "Error",
        message: "Failed to load contacts. Please try again.",
      );
    }
  }

  Future<void> _showAddContactDialog() async {
    final nameController = TextEditingController();
    final relationController = TextEditingController();
    final phoneController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Add Emergency Contact",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTeal,
              fontSize: 20,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: nameController,
                  label: "Full Name",
                  hint: "e.g. Anita Sharma",
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: relationController,
                  label: "Relation",
                  hint: "e.g. Mother, Uncle, Guardian",
                  icon: Icons.people,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: phoneController,
                  label: "Phone Number",
                  hint: "e.g. 9123456789",
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                final relation = relationController.text.trim();
                final phone = phoneController.text.trim();

                if (name.isEmpty || relation.isEmpty || phone.isEmpty) {
                  Get.snackbar(
                    "Required",
                    "All fields are required",
                    backgroundColor: Colors.red[100],
                  );
                  return;
                }

                // NEW: Limit check before proceeding
                if (!_canAddMore) {
                  Get.snackbar(
                    "Limit Reached",
                    "You can add a maximum of $maxContacts emergency contacts.\nPlease delete one to add a new one.",
                    backgroundColor: Colors.orange[100],
                    duration: const Duration(seconds: 5),
                  );
                  return;
                }

                if (phone.length < 10 ||
                    !RegExp(r'^[0-9+ ]+$').hasMatch(phone)) {
                  Get.snackbar(
                    "Invalid Phone",
                    "Please enter a valid number",
                    backgroundColor: Colors.orange[100],
                  );
                  return;
                }

                Get.dialog(
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                  barrierDismissible: false,
                );

                try {
                  await _apiService.addEmergencyContact(
                    name: name,
                    relation: relation,
                    phoneNumber: phone,
                  );

                  Get.back();
                  Navigator.pop(dialogContext);

                  _fetchEmergencyContacts();

                  getSnackbar(
                    title: "Success",
                    message: "Contact added successfully",
                  );
                } on ApiException catch (e) {
                  print("Add emergency contact error: $e");
                  Get.back();
                  getSnackbar(
                    title: "Error",
                    message: "Failed to add contact. Please try again.",
                  );
                } catch (_) {
                  Get.back();
                  getSnackbar(
                    title: "Error",
                    message: "Something went wrong",
                  );
                }
              },
              child: Text(
                "Add Contact",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditContactDialog(Map<String, dynamic> contact) async {
    final nameController =
        TextEditingController(text: contact['rawName'] ?? '');
    final relationController =
        TextEditingController(text: contact['relation'] ?? '');
    final phoneController =
        TextEditingController(text: contact['rawPhone'] ?? '');

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Edit Emergency Contact",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTeal,
              fontSize: 20,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: nameController,
                  label: "Full Name",
                  hint: "e.g. Anita Sharma",
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: relationController,
                  label: "Relation",
                  hint: "e.g. Mother, Uncle, Guardian",
                  icon: Icons.people,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: phoneController,
                  label: "Phone Number",
                  hint: "e.g. 9123456789",
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                final relation = relationController.text.trim();
                final phone = phoneController.text.trim();

                if (name.isEmpty || relation.isEmpty || phone.isEmpty) {
                  Get.snackbar("Required", "All fields are required",
                      backgroundColor: Colors.red[100]);
                  return;
                }

                if (phone.length < 10 ||
                    !RegExp(r'^[0-9+ ]+$').hasMatch(phone)) {
                  Get.snackbar(
                    "Invalid Phone",
                    "Please enter a valid number",
                    backgroundColor: Colors.orange[100],
                  );
                  return;
                }

                Get.dialog(
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                  barrierDismissible: false,
                );

                try {
                  await _apiService.updateEmergencyContact(
                    id: contact['id'],
                    name: name,
                    relation: relation,
                    phoneNumber: phone,
                    isActive: contact['isActive'] ?? true,
                  );

                  Get.back();
                  Navigator.pop(dialogContext);

                  _fetchEmergencyContacts();

                  getSnackbar(
                    title: "Success",
                    message: "Contact updated successfully",
                  );
                } on ApiException catch (e) {
                  print("Update emergency contact error: $e");
                  Get.back();
                  getSnackbar(
                    title: "Error",
                    message: "Failed to update contact. Please try again.",
                  );
                } catch (_) {
                  Get.back();
                  getSnackbar(
                    title: "Error",
                    message: "Something went wrong",
                  );
                }
              },
              child: Text(
                "Update Contact",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Delete Contact",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.red[700],
            ),
          ),
          content: Text(
            "Are you sure you want to delete $name?",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                "Delete",
                style: TextStyle(
                  color: Colors.red[700],
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    Get.dialog(
      const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
    );

    try {
      await _apiService.deleteEmergencyContact(id);

      Get.back();
      _fetchEmergencyContacts();

      getSnackbar(
        title: "Success",
        message: "Contact deleted successfully",
      );
    } on ApiException catch (e) {
      print("Delete emergency contact error: $e");
      Get.back();
      getSnackbar(
        title: "Error",
        message: "Failed to delete contact. Please try again.",
      );
    } catch (_) {
      Get.back();
      getSnackbar(
        title: "Error",
        message: "Something went wrong",
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: AppColors.primaryTeal,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primaryTeal.withOpacity(0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryTeal,
            width: 2,
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
        centerTitle: false,
        title: const Text(
          "Emergency Contacts",
          style: TextStyle(
            wordSpacing: 1.6,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor:
                    _canAddMore ? AppColors.white : Colors.grey[300],
                foregroundColor:
                    _canAddMore ? AppColors.primaryTeal : Colors.grey[600],
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _canAddMore ? _showAddContactDialog : null,
              child: Row(
                children: [
                  Icon(
                    Icons.add,
                    size: 16,
                    color: _canAddMore ? null : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _canAddMore ? "Add Contact" : "Max 10 Reached",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // NEW: Show current count (nice UX)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Your Contacts",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          "${_contacts.length} / $maxContacts",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _contacts.length >= maxContacts
                                ? Colors.red[700]
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: _contacts.isEmpty
                          ? Center(
                              child: Text(
                                "No emergency contacts yet",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            )
                          : ListView(
                              children: [
                                ..._contacts.map(
                                  (contact) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _contactCard(
                                      contact: contact,
                                      onEdit: () =>
                                          _showEditContactDialog(contact),
                                      onDelete: () =>
                                          _showDeleteConfirmationDialog(
                                              contact['id'],
                                              contact['rawName'] ?? 'contact'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                  ],
                ),
              ),
            ),
    );
  }

  Widget _contactCard({
    required Map<String, dynamic> contact,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
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
      child: ListTile(
        contentPadding: EdgeInsets.only(left: 10, right: 8, top: 4, bottom: 4),
        leading: const CircleAvatar(
          backgroundColor: AppColors.primaryTeal,
          child: Icon(
            Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          contact['name']!,
          style: TextStyle(
            fontSize: 12,
          ),
        ),
        subtitle: Text(
          contact['phone']!,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
        trailing: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onEdit,
              child: Icon(
                size: 22,
                Icons.edit,
                color: AppColors.primaryTeal,
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: onDelete,
              child: Icon(
                size: 22,
                Icons.delete,
                color: Colors.red[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
