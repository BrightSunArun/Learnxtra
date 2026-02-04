import 'package:LearnXtraAdmin/constants/app_colors.dart';
import 'package:LearnXtraAdmin/services/api_services.dart';
import 'package:flutter/material.dart';

class PolicyPage extends StatefulWidget {
  const PolicyPage({super.key});

  @override
  State<PolicyPage> createState() => _PolicyPageState();
}

class _PolicyPageState extends State<PolicyPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Screen Time Controllers
  final _dailyUnlocksController = TextEditingController();
  final _unlockDurationController = TextEditingController();

  // Learning Gate Controllers
  final _quizQuestionsController = TextEditingController();
  final _minPassScoreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPolicies();
  }

  @override
  void dispose() {
    _dailyUnlocksController.dispose();
    _unlockDurationController.dispose();
    _quizQuestionsController.dispose();
    _minPassScoreController.dispose();
    super.dispose();
  }

  Future<void> _loadPolicies() async {
    setState(() => _isLoading = true);

    final screenTime = await ApiService().getScreenTimePolicy();
    final learningGate = await ApiService().getLearningGatePolicy();

    if (screenTime != null && mounted) {
      _dailyUnlocksController.text =
          (screenTime['defaultDailyUnlocks']?.toString() ?? '5');
      _unlockDurationController.text =
          (screenTime['defaultUnlockDuration']?.toString() ?? '30');
    }

    if (learningGate != null && mounted) {
      _quizQuestionsController.text =
          (learningGate['totalQuizQuestions']?.toString() ?? '10');
      _minPassScoreController.text =
          (learningGate['minQuizPassScore']?.toString() ?? '7');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePolicies() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // 1. Update Screen Time (only if you add the endpoint later)
      // Currently your ApiService doesn't have updateScreenTimePolicy yet
      // Uncomment / implement when backend supports it
      /*
      final screenTimeBody = {
        'defaultDailyUnlocks': int.tryParse(_dailyUnlocksController.text) ?? 5,
        'defaultUnlockDuration': int.tryParse(_unlockDurationController.text) ?? 30,
      };
      await ApiService().updateScreenTime(body: screenTimeBody); // ← add this method
      */

      // 2. Update Learning Gate (this one already exists in your ApiService)
      final quizQuestions = int.tryParse(_quizQuestionsController.text) ?? 10;
      final minPassScore = int.tryParse(_minPassScoreController.text) ?? 7;

      final response = await ApiService().updateScreenTimePolicy(
        totalQuizQuestions: quizQuestions,
        minQuizPassScore: minPassScore,
      );

      if (response != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Policies updated successfully")),
        );
      } else {
        throw Exception("Update failed");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to update policies: $e";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage ?? "Unknown error")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Policy Configurations",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 30),
          if (_errorMessage != null) ...[
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _policyBox("Screen-Time Settings", [
                  _inputField(
                    "Default Daily Unlocks",
                    controller: _dailyUnlocksController,
                    hint: "5",
                  ),
                  _inputField(
                    "Unlock Duration (mins)",
                    controller: _unlockDurationController,
                    hint: "30",
                  ),
                ]),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _policyBox("Learning Gate Rules", [
                  _inputField(
                    "Quiz Questions Count",
                    controller: _quizQuestionsController,
                    hint: "10",
                  ),
                  _inputField(
                    "Min. Pass Score",
                    controller: _minPassScoreController,
                    hint: "7",
                  ),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSaving ? null : _updatePolicies,
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      "UPDATE GLOBAL POLICIES",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _policyBox(String title, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gray200.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryTeal,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 20),
          ...items,
        ],
      ),
    );
  }

  Widget _inputField(
    String label, {
    required TextEditingController controller,
    required String hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.mutedTeal),
          hintText: hint,
          filled: true,
          fillColor: AppColors.gray100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
