class Child {
  final String id;
  final String parentId;
  final String name;
  final String grade;
  final int? age;
  final String? state;
  final String? board;
  final String? schoolName;
  final String? schoolAddress;
  final List<String>? strongSubjects;
  final List<String>? weakSubjects;
  final DateTime createdAt;

  // For future features (progress tracking)
  final int dailyUnlockCount;
  final int usedUnlocksToday;
  final double overallQuizScore;

  Child({
    required this.id,
    required this.parentId,
    required this.name,
    required this.grade,
    this.age,
    this.state,
    this.board,
    this.schoolName,
    this.schoolAddress,
    this.strongSubjects,
    this.weakSubjects,
    required this.createdAt,
    this.dailyUnlockCount = 5,
    this.usedUnlocksToday = 0,
    this.overallQuizScore = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'name': name,
      'grade': grade,
      'age': age,
      'state': state,
      'board': board,
      'schoolName': schoolName,
      'schoolAddress': schoolAddress,
      'strongSubjects': strongSubjects,
      'weakSubjects': weakSubjects,
      'createdAt': createdAt.toIso8601String(),
      'dailyUnlockCount': dailyUnlockCount,
      'usedUnlocksToday': usedUnlocksToday,
      'overallQuizScore': overallQuizScore,
    };
  }
}
