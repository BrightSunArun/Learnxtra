import 'package:LearnXtraAdmin/constants/app_colors.dart';
import 'package:LearnXtraAdmin/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PolicyPage extends StatefulWidget {
  const PolicyPage({super.key});

  @override
  State<PolicyPage> createState() => _PolicyPageState();
}

class _PolicyPageState extends State<PolicyPage> {
  bool _isLoading = true;
  bool _isSavingScreenTime = false;
  bool _isSavingLearningGate = false;
  String? _errorMessage;

  // Screen Time Controllers
  final _dailyUnlocksController = TextEditingController();
  final _unlockDurationController = TextEditingController();

  // Learning Gate Controllers
  final _quizQuestionsController = TextEditingController();
  final _minPassScoreController = TextEditingController();

  // Store policy IDs
  String? _screenTimePolicyId;
  String? _learningGatePolicyId;

  @override
  void initState() {
    super.initState();
    _loadGlobalPolicies();
  }

  Future<void> _loadGlobalPolicies() async {
    try {
      final responseMap = await ApiService().getGlobalPolicies();
      if (responseMap == null || responseMap['success'] != true) {
        setState(() {
          _errorMessage = 'Failed to load policies: Invalid response';
        });
        return;
      }

      final List<dynamic> rawList = responseMap['data'] ?? [];
      final policies = rawList.cast<Map<String, dynamic>>();

      for (final policy in policies) {
        final id = policy['id'] as String?;
        final type = policy['type'] as String?;
        final data = policy['data'] as Map<String, dynamic>?;

        if (id == null || type == null || data == null) continue;

        if (type == 'screen_time') {
          _screenTimePolicyId = id;
          _dailyUnlocksController.text =
              (data['defaultDailyUnlocks'] ?? 10).toString();
          _unlockDurationController.text =
              (data['defaultUnlockDuration'] ?? 20).toString();
        } else if (type == 'learning_gate') {
          _learningGatePolicyId = id;
          _quizQuestionsController.text =
              (data['totalQuizQuestions'] ?? 10).toString();
          _minPassScoreController.text =
              (data['minQuizPassScore'] ?? 7).toString();
        }
      }

      if (_screenTimePolicyId == null && _learningGatePolicyId == null) {
        setState(() {
          _errorMessage = 'No policy configurations found';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load policies: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  static const int _maxDailyUnlocks = 10;
  static const int _maxUnlockDurationMinutes = 180;
  static const int _maxQuizQuestionsCount = 20;

  void _showValidationAlert(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(color: AppColors.primaryTeal),
        title: const Text(
          'Invalid value',
          style: TextStyle(
            color: AppColors.primaryTeal,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateScreenTimePolicy() async {
    if (_screenTimePolicyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Screen Time policy ID not found")),
      );
      return;
    }

    final dailyUnlocks = int.tryParse(_dailyUnlocksController.text);
    final unlockDuration = int.tryParse(_unlockDurationController.text);

    if (dailyUnlocks == null || dailyUnlocks > _maxDailyUnlocks) {
      _showValidationAlert(
        'Default Daily Unlocks must be at most $_maxDailyUnlocks.',
      );
      return;
    }
    if (unlockDuration == null || unlockDuration > _maxUnlockDurationMinutes) {
      _showValidationAlert(
        'Unlock Duration must be at most $_maxUnlockDurationMinutes minutes.',
      );
      return;
    }

    setState(() => _isSavingScreenTime = true);

    try {
      final success = await ApiService().updateGlobalPolicy(
        policyId: _screenTimePolicyId!,
        type: "screen_time",
        data: {
          "defaultDailyUnlocks": dailyUnlocks,
          "defaultUnlockDuration": unlockDuration,
        },
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Screen Time policy updated")),
        );
      } else {
        throw Exception("Update failed");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update Screen Time: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingScreenTime = false);
      }
    }
  }

  Future<void> _updateLearningGatePolicy() async {
    if (_learningGatePolicyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Learning Gate policy ID not found")),
      );
      return;
    }

    final quizQuestions = int.tryParse(_quizQuestionsController.text);
    final minPassScore = int.tryParse(_minPassScoreController.text);

    if (quizQuestions == null || quizQuestions > _maxQuizQuestionsCount) {
      _showValidationAlert(
        'Quiz Questions Count must be at most $_maxQuizQuestionsCount.',
      );
      return;
    }
    final maxMinPassScore = (quizQuestions * 70) ~/ 100;
    if (minPassScore == null || minPassScore > maxMinPassScore) {
      _showValidationAlert(
        'Minimum Pass Score must be at most 70% of Quiz Questions Count ($maxMinPassScore for $quizQuestions questions).',
      );
      return;
    }

    setState(() => _isSavingLearningGate = true);

    try {
      print("1. data being passed ");
      final success = await ApiService().updateGlobalPolicy(
        policyId: _learningGatePolicyId!,
        type: "learning_gate",
        data: {
          "totalQuizQuestions": quizQuestions,
          "minQuizPassScore": minPassScore,
        },
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Learning Gate policy updated")),
        );
      } else {
        throw Exception("Update failed");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update Learning Gate: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingLearningGate = false);
      }
    }
  }

  @override
  void dispose() {
    _dailyUnlocksController.dispose();
    _unlockDurationController.dispose();
    _quizQuestionsController.dispose();
    _minPassScoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(
        color: AppColors.primaryTeal,
      ));
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
                child: _policyBox(
                  title: "Screen-Time Settings",
                  children: [
                    _inputField(
                      "Default Daily Unlocks",
                      controller: _dailyUnlocksController,
                      hint: "10",
                    ),
                    _inputField(
                      "Unlock Duration (minutes)",
                      controller: _unlockDurationController,
                      hint: "20",
                      maxLength: 3,
                    ),
                  ],
                  buttonText: "Update Screen Time",
                  isSaving: _isSavingScreenTime,
                  onPressed: _updateScreenTimePolicy,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _policyBox(
                  title: "Learning Gate Rules",
                  children: [
                    _inputField(
                      "Quiz Questions Count",
                      controller: _quizQuestionsController,
                      hint: "10",
                    ),
                    _inputField(
                      "Minimum Pass Score",
                      controller: _minPassScoreController,
                      hint: "7",
                    ),
                  ],
                  buttonText: "Update Learning Gate",
                  isSaving: _isSavingLearningGate,
                  onPressed: _updateLearningGatePolicy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _policyBox({
    required String title,
    required List<Widget> children,
    required String buttonText,
    required bool isSaving,
    required VoidCallback onPressed,
  }) {
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
          ...children,
          const SizedBox(height: 24),
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
              onPressed: isSaving ? null : onPressed,
              child: isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      buttonText,
                      style: const TextStyle(
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

  Widget _inputField(
    String label, {
    required TextEditingController controller,
    required String hint,
    int? maxLength = 2,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(maxLength)
        ],
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
