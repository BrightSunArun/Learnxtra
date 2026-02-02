import 'package:flutter/material.dart';
import 'package:LearnXtraChild/src/utils/app_colors.dart';

class EmergencyCallScreen extends StatelessWidget {
  const EmergencyCallScreen({super.key});

  // Temporary static data — later replace with API + controller
  static final List<Map<String, dynamic>> _emergencyContacts = [
    {
      'name': 'Mom',
      'phone': '+91 98765 43210',
      'relation': 'Mother',
    },
    {
      'name': 'Dad',
      'phone': '+91 91234 56789',
      'relation': 'Father',
    },
    {
      'name': 'Aunty Priya',
      'phone': '+91 99887 76655',
      'relation': 'Aunt',
    },
    {
      'name': 'Emergency - 112',
      'phone': '112',
      'relation': 'National Emergency',
    },
  ];

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
      body: ListView(
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
          // Contact List
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

          // Emergency Numbers (non-editable)
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
          contact['name'] as String,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              contact['phone'] as String,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
            ),
            if (contact['relation'] != null)
              Text(
                contact['relation'] as String,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.call, color: AppColors.primaryTeal, size: 24),
          onPressed: () {
            // TODO: show add contact bottom sheet / dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add contact feature coming soon')),
            );
          },
        ),
      ),
    );
  }

  Widget _quickEmergencyTile(String label, String number) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.emergency, color: Colors.red),
        title: Text(label),
        trailing: Text(
          number,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
            fontSize: 17,
          ),
        ),
      ),
    );
  }
}
