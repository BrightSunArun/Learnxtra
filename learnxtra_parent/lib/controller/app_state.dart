import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/child.dart';

class AppStateController extends GetxController {
  final RxList<Child> _children = <Child>[].obs;
  List<Child> get children => List.unmodifiable(_children);
  final RxBool isAuthenticated = false.obs;
  final RxBool hasCompletedProfile = false.obs;
  final token = RxnString();
  final currentParentId = RxnString();
  final currentMobileNumber = RxnString();

  @override
  void onInit() {
    super.onInit();
    initialize();
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    isAuthenticated.value = prefs.getBool('isLoggedIn') ?? false;
    hasCompletedProfile.value = prefs.getBool('hasCompletedProfile') ?? false;

    currentParentId.value = prefs.getString('parentId');
    token.value = prefs.getString('auth_token');

    if (_children.isEmpty) {
      final parentId = currentParentId.value ?? "demo_parent";

      _children.addAll([
        Child(
          id: "1",
          parentId: parentId,
          name: "Arjun",
          grade: "Grade 6",
          createdAt: DateTime(2024, 8, 15),
        ),
        Child(
          id: "2",
          parentId: parentId,
          name: "Sanya",
          grade: "Grade 3",
          createdAt: DateTime(2024, 9, 3),
        ),
      ]);
    }
  }

  Future<void> login({
    required String tokenValue,
    String? parentId,
    bool isNewUser = false,
    bool markProfileCompleted = false,
    required String mobileNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('auth_token', tokenValue);
    token.value = tokenValue;

    await prefs.setBool('isLoggedIn', true);
    isAuthenticated.value = true;

    if (parentId != null) {
      await prefs.setString('parentId', parentId);
      currentParentId.value = parentId;
    }

    await prefs.setString('mobileNumber', mobileNumber);
    currentMobileNumber.value = mobileNumber;

    if (markProfileCompleted) {
      await completeProfile(silent: true);
    }
  }

  Future<void> completeProfile({bool silent = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedProfile', true);
    hasCompletedProfile.value = true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();
    isAuthenticated.value = false;
    hasCompletedProfile.value = false;
    currentParentId.value = null;
    token.value = null;
  }

  void addChild(Child child) {
    if (_children.any((c) => c.id == child.id)) {
      debugPrint("Warning: Child with id ${child.id} already exists");
      return;
    }
    _children.add(child);
  }

  void updateChild(String childId, Child updatedChild) {
    final index = _children.indexWhere((c) => c.id == childId);
    if (index != -1) {
      _children[index] = updatedChild;
    }
  }

  void removeChild(String childId) {
    _children.removeWhere((c) => c.id == childId);
  }

  Child? getChildById(String id) {
    try {
      return _children.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  String getTokenOrEmpty() => token.value ?? '';
  String getParentIdOrDefault() => currentParentId.value ?? 'demo_parent';
}
