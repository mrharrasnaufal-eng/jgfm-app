class User {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final bool isVip;
  final String? currentPlanName;

  User({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.isVip = false,
    this.currentPlanName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      photoURL: json['photoURL'],
      isVip: json['isVip'] == 1 || json['isVip'] == true,
      currentPlanName: json['currentPlanName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'isVip': isVip,
      'currentPlanName': currentPlanName,
    };
  }
}
