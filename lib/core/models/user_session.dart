class UserSession {
  final String? token;
  final String? userId;
  final String? userName;
  final DateTime? loginTime;
  final DateTime? lastActivity;

  UserSession({
    this.token,
    this.userId,
    this.userName,
    this.loginTime,
    this.lastActivity,
  });

  bool get isValid => token != null && userId != null;
  
  bool get isExpired {
    if (lastActivity == null) return true;
    // Check if session is older than X hours (e.g., 24 hours)
    return DateTime.now().difference(lastActivity!).inHours > 24;
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'userId': userId,
      'userName': userName,
      'loginTime': loginTime?.toIso8601String(),
      'lastActivity': lastActivity?.toIso8601String(),
    };
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      token: json['token'],
      userId: json['userId'],
      userName: json['userName'],
      loginTime: json['loginTime'] != null 
          ? DateTime.parse(json['loginTime']) 
          : null,
      lastActivity: json['lastActivity'] != null 
          ? DateTime.parse(json['lastActivity']) 
          : null,
    );
  }

  UserSession copyWith({
    String? token,
    String? userId,
    String? userName,
    DateTime? loginTime,
    DateTime? lastActivity,
  }) {
    return UserSession(
      token: token ?? this.token,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      loginTime: loginTime ?? this.loginTime,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }
}