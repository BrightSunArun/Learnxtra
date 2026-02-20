import 'package:LearnXtraChild/src/services/api_service.dart';
// import 'package:LearnXtraChild/src/services/kiosk_mode.dart';
import 'package:flutter/material.dart';
import 'package:LearnXtraChild/src/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart'; // ← NEW IMPORT

class EmergencyCallScreen extends StatefulWidget {
  const EmergencyCallScreen({super.key});

  @override
  State<EmergencyCallScreen> createState() => _EmergencyCallScreenState();
}

class _EmergencyCallScreenState extends State<EmergencyCallScreen> {
  List<Map<String, dynamic>> _emergencyContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    getEmergencyContacts();
  }

  Future<void> getEmergencyContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final parentId = prefs.getString('parentId');

      if (parentId == null || parentId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Parent ID not found. Please login again.'),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final response =
          await ApiService().getEmergencyContacts(parentId: parentId);

      print("response: $response");

      if (mounted) {
        setState(() {
          _emergencyContacts = List<Map<String, dynamic>>.from(
            response['EmergencyContact'] ?? [],
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load contacts: $e')),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    // await KioskService.disableKiosk();
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber.trim(),
    );

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch phone dialer')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching call: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: AppColors.primaryTeal,
        title: const Text(
          'LearnXtra',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            height: 1.2,
            fontStyle: FontStyle.italic,
          ),
        ),
        centerTitle: true,
        elevation: 16,
        surfaceTintColor: AppColors.primaryTeal,
        shadowColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        scrolledUnderElevation: 16,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
              children: [
                const SizedBox(height: 16),
                Text(
                  'Emergency Contacts',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 28),
                if (_emergencyContacts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No emergency contacts added yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                else
                  ..._emergencyContacts.map((contact) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _contactCard(
                        context: context,
                        contact: contact,
                      ),
                    );
                  }).toList(),
                const SizedBox(height: 16),
                const Divider(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Quick Emergency Numbers (India)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _quickEmergencyTile('Police', '100 / 112'),
                _quickEmergencyTile('Ambulance', '108'),
                _quickEmergencyTile('Women Helpline', '181 / 1091'),
              ],
            ),
    );
  }

  Widget _contactCard({
    required BuildContext context,
    required Map<String, dynamic> contact,
  }) {
    final name = contact['name']?.toString() ?? 'Unknown';
    final phone = contact['phone_number']?.toString() ?? '—';
    final relation = contact['relation']?.toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryTeal,
          radius: 28,
          child: const Icon(Icons.person, color: Colors.white, size: 28),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              phone,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
            ),
            if (relation != null && relation.isNotEmpty)
              Text(
                relation,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.call, color: AppColors.primaryTeal, size: 28),
          onPressed: phone != '—' && phone.isNotEmpty
              ? () => _makePhoneCall(phone) // ← NOW CALLS
              : null,
        ),
      ),
    );
  }

  Widget _quickEmergencyTile(String label, String number) {
    // Extract first number (before /) for calling
    final callNumber = number.split('/').first.trim();

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.emergency_share_rounded, color: Colors.red),
        title: Text(label),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              number,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: 17,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.call, color: Colors.red),
              onPressed: () => _makePhoneCall(callNumber),
            ),
          ],
        ),
      ),
    );
  }
}
