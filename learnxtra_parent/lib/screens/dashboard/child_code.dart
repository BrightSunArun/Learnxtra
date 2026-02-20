import 'package:LearnXtraParent/screens/main_navigation.dart';
import 'package:LearnXtraParent/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';

class ChildConnectionCodeScreen extends StatefulWidget {
  final String childId;
  final String childName;

  const ChildConnectionCodeScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ChildConnectionCodeScreen> createState() =>
      _ChildConnectionCodeScreenState();
}

class _ChildConnectionCodeScreenState extends State<ChildConnectionCodeScreen> {
  String? _connectionCode;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchConnectionCode();
  }

  Future<void> _fetchConnectionCode() async {
    try {
      final api = Get.find<ApiService>();

      final response = await api.generateChildCode(
        childId: widget.childId,
      );

      final codeFromServer = response['childLinkCode']?.toString();

      if (codeFromServer == null || codeFromServer.isEmpty) {
        throw Exception("No code returned from server");
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("isCodeGenerated", true);

      setState(() {
        _connectionCode = codeFromServer;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 0,
        leading: SizedBox.shrink(),
        title: Text(
          "Connection Code",
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text("Generating connection code..."),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              "Failed to generate code",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: _fetchConnectionCode,
              child: const Text("Try Again"),
            ),
          ],
        ),
      );
    }

    final code = _connectionCode!;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        Text(
          "Share this code with your child",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryTeal,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                code,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: AppColors.primaryTeal,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(
                  Icons.copy,
                  color: AppColors.primaryTeal,
                ),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: code),
                  );
                  getSnackbar(
                    title: "Success",
                    message: "Code copied!",
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Text(
          "This code is unique and can be used only once",
          style: TextStyle(
            fontSize: 14,
            color: AppColors.gray600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(
              Icons.share,
              color: AppColors.primaryTeal,
              size: 24,
            ),
            label: const Text(
              "Share Code",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryTeal,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: 16,
              ),
              side: const BorderSide(
                color: AppColors.primaryTeal,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Share.share(
                "Use this code to connect your child: $_connectionCode",
                subject: "Connect your child",
              );
            },
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainNavigation(),
                ),
                (route) => false,
              );
            },
            child: const Text(
              "Done",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
