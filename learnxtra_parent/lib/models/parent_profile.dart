// class ParentProfile {
//   final String parentId;
//   final String fullName;
//   final String? email;
//   final String? profileImageUrl;
//   final String address;
//   final String pinCode;
//   final DateTime updatedAt;

//   ParentProfile({
//     required this.parentId,
//     required this.fullName,
//     this.email,
//     this.profileImageUrl,
//     required this.address,
//     required this.pinCode,
//     required this.updatedAt,
//   });

//   Map<String, dynamic> toJson() {
//     return {
//       'parentId': parentId,
//       'fullName': fullName,
//       'email': email,
//       'profileImageUrl': profileImageUrl,
//       'address': address,
//       'pinCode': pinCode,
//       'updatedAt': updatedAt.toIso8601String(),
//     };
//   }

//   factory ParentProfile.fromJson(Map<String, dynamic> json) {
//     return ParentProfile(
//       parentId: json['parentId'] as String,
//       fullName: json['fullName'] as String,
//       email: json['email'] as String?,
//       profileImageUrl: json['profileImageUrl'] as String?,
//       address: json['address'] as String,
//       pinCode: json['pinCode'] as String,
//       updatedAt: DateTime.parse(json['updatedAt'] as String),
//     );
//   }
// }
