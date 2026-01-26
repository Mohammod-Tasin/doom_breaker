class UserProfile {
  final String userId;
  final String displayName;
  final String email;
  final TimeRange studyHours;
  final TimeRange sleepHours;
  final TimeRange institutionHours;
  final int focusGoalMinutes; // Daily focus goal in minutes
  final List<String> distractingApps; // Package names
  final DateTime createdAt;
  final DateTime lastSynced;

  // Adaptive thresholds (personalized)
  final double scrollSpeedThreshold;
  final double sessionDurationThreshold;

  UserProfile({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.studyHours,
    required this.sleepHours,
    required this.institutionHours,
    this.focusGoalMinutes = 360, // Default 6 hours
    this.distractingApps = const [],
    DateTime? createdAt,
    DateTime? lastSynced,
    this.scrollSpeedThreshold = 15.0,
    this.sessionDurationThreshold = 300.0, // 5 minutes
  }) : createdAt = createdAt ?? DateTime.now(),
       lastSynced = lastSynced ?? DateTime.now();

  // Cloud serialization (works with Supabase)
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'displayName': displayName,
    'email': email,
    'studyHours': studyHours.toJson(),
    'sleepHours': sleepHours.toJson(),
    'institutionHours': institutionHours.toJson(),
    'focusGoalMinutes': focusGoalMinutes,
    'distractingApps': distractingApps,
    'createdAt': createdAt.toIso8601String(),
    'lastSynced': lastSynced.toIso8601String(),
    'scrollSpeedThreshold': scrollSpeedThreshold,
    'sessionDurationThreshold': sessionDurationThreshold,
  };

  // Local storage serialization (SharedPreferences)
  Map<String, dynamic> toLocalJson() => {
    'userId': userId,
    'displayName': displayName,
    'email': email,
    'studyHours': studyHours.toJson(),
    'sleepHours': sleepHours.toJson(),
    'institutionHours': institutionHours.toJson(),
    'focusGoalMinutes': focusGoalMinutes,
    'distractingApps': distractingApps,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'lastSynced': lastSynced.millisecondsSinceEpoch,
    'scrollSpeedThreshold': scrollSpeedThreshold,
    'sessionDurationThreshold': sessionDurationThreshold,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    userId: json['userId'] as String,
    displayName: json['displayName'] as String,
    email: json['email'] as String,
    studyHours: TimeRange.fromJson(json['studyHours'] as Map<String, dynamic>),
    sleepHours: TimeRange.fromJson(json['sleepHours'] as Map<String, dynamic>),
    institutionHours: TimeRange.fromJson(
      json['institutionHours'] as Map<String, dynamic>,
    ),
    focusGoalMinutes: json['focusGoalMinutes'] as int? ?? 360,
    distractingApps: List<String>.from(json['distractingApps'] as List? ?? []),
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastSynced: DateTime.parse(json['lastSynced'] as String),
    scrollSpeedThreshold: json['scrollSpeedThreshold'] as double? ?? 15.0,
    sessionDurationThreshold:
        json['sessionDurationThreshold'] as double? ?? 300.0,
  );

  factory UserProfile.fromLocalJson(Map<String, dynamic> json) => UserProfile(
    userId: json['userId'] as String,
    displayName: json['displayName'] as String,
    email: json['email'] as String,
    studyHours: TimeRange.fromJson(json['studyHours'] as Map<String, dynamic>),
    sleepHours: TimeRange.fromJson(json['sleepHours'] as Map<String, dynamic>),
    institutionHours: TimeRange.fromJson(
      json['institutionHours'] as Map<String, dynamic>,
    ),
    focusGoalMinutes: json['focusGoalMinutes'] as int? ?? 360,
    distractingApps: List<String>.from(json['distractingApps'] as List? ?? []),
    createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    lastSynced: DateTime.fromMillisecondsSinceEpoch(json['lastSynced'] as int),
    scrollSpeedThreshold: json['scrollSpeedThreshold'] as double? ?? 15.0,
    sessionDurationThreshold:
        json['sessionDurationThreshold'] as double? ?? 300.0,
  );

  UserProfile copyWith({
    String? displayName,
    TimeRange? studyHours,
    TimeRange? sleepHours,
    TimeRange? institutionHours,
    int? focusGoalMinutes,
    List<String>? distractingApps,
    double? scrollSpeedThreshold,
    double? sessionDurationThreshold,
  }) => UserProfile(
    userId: userId,
    displayName: displayName ?? this.displayName,
    email: email,
    studyHours: studyHours ?? this.studyHours,
    sleepHours: sleepHours ?? this.sleepHours,
    institutionHours: institutionHours ?? this.institutionHours,
    focusGoalMinutes: focusGoalMinutes ?? this.focusGoalMinutes,
    distractingApps: distractingApps ?? this.distractingApps,
    createdAt: createdAt,
    lastSynced: DateTime.now(),
    scrollSpeedThreshold: scrollSpeedThreshold ?? this.scrollSpeedThreshold,
    sessionDurationThreshold:
        sessionDurationThreshold ?? this.sessionDurationThreshold,
  );
}

class TimeRange {
  final String start; // Format: "HH:mm" (24-hour)
  final String end;

  const TimeRange({required this.start, required this.end});

  Map<String, dynamic> toJson() => {'start': start, 'end': end};

  factory TimeRange.fromJson(Map<String, dynamic> json) =>
      TimeRange(start: json['start'] as String, end: json['end'] as String);

  // Check if current time is within this range
  bool isWithinRange(DateTime dateTime) {
    final now = dateTime;
    final startParts = start.split(':');
    final endParts = end.split(':');

    final startTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );

    final endTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );

    // Handle overnight ranges (e.g., 23:00 - 07:00)
    if (endTime.isBefore(startTime)) {
      return now.isAfter(startTime) || now.isBefore(endTime);
    }

    return now.isAfter(startTime) && now.isBefore(endTime);
  }
}
