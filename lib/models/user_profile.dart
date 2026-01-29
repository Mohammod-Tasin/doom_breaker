class UserProfile {
  final String userId;
  final String displayName;
  final String email;

  // Academic/Professional Information
  final String institution; // University/School name
  final String country; // User's country
  final String institutionType; // "University", "School", "Workplace"
  final String major; // Field of study (optional)
  final int yearOfStudy; // 1-4 for university (optional)

  // Schedule & Goals
  final TimeRange studyHours;
  final TimeRange sleepHours;
  final TimeRange institutionHours;
  final int focusGoalMinutes; // Daily focus goal in minutes

  // Behavioral Preferences (for Decision Engine)
  final List<String> distractingApps; // Package names
  final String interventionStyle; // "Gentle", "Moderate", "Strict"
  final bool enableFocusMode; // Manual strict mode
  final int scrollThreshold; // 0-100 (higher = less sensitive)
  final int cooldownMinutes; // 5-60 minutes between interventions

  // Tracking & Metadata
  final DateTime createdAt;
  final DateTime lastModified; // For sync conflict resolution
  final DateTime lastSynced;
  final int daysUsed; // For ML weight adaptation

  // Adaptive thresholds (personalized)
  final double scrollSpeedThreshold;
  final double sessionDurationThreshold;

  UserProfile({
    required this.userId,
    required this.displayName,
    required this.email,

    // NEW: Academic/Professional
    required this.institution,
    required this.country,
    this.institutionType = "University",
    this.major = "",
    this.yearOfStudy = 1,

    // Schedule & Goals
    required this.studyHours,
    required this.sleepHours,
    required this.institutionHours,
    this.focusGoalMinutes = 360, // Default 6 hours
    // NEW: Behavioral Preferences
    this.distractingApps = const [],
    this.interventionStyle = "Moderate",
    this.enableFocusMode = false,
    this.scrollThreshold = 50,
    this.cooldownMinutes = 15,

    // Tracking
    DateTime? createdAt,
    DateTime? lastModified,
    DateTime? lastSynced,
    this.daysUsed = 0,

    // Adaptive thresholds
    this.scrollSpeedThreshold = 15.0,
    this.sessionDurationThreshold = 300.0, // 5 minutes
  }) : createdAt = createdAt ?? DateTime.now(),
       lastModified = lastModified ?? DateTime.now(),
       lastSynced = lastSynced ?? DateTime.now();

  // Cloud serialization (works with Supabase)
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'displayName': displayName,
    'email': email,

    // NEW: Academic/Professional
    'institution': institution,
    'country': country,
    'institutionType': institutionType,
    'major': major,
    'yearOfStudy': yearOfStudy,

    // Schedule & Goals
    'studyHours': studyHours.toJson(),
    'sleepHours': sleepHours.toJson(),
    'institutionHours': institutionHours.toJson(),
    'focusGoalMinutes': focusGoalMinutes,

    // NEW: Behavioral Preferences
    'distractingApps': distractingApps,
    'interventionStyle': interventionStyle,
    'enableFocusMode': enableFocusMode,
    'scrollThreshold': scrollThreshold,
    'cooldownMinutes': cooldownMinutes,

    // Tracking
    'createdAt': createdAt.toIso8601String(),
    'lastModified': lastModified.toIso8601String(),
    'lastSynced': lastSynced.toIso8601String(),
    'daysUsed': daysUsed,

    // Adaptive thresholds
    'scrollSpeedThreshold': scrollSpeedThreshold,
    'sessionDurationThreshold': sessionDurationThreshold,
  };

  // Local storage serialization (SharedPreferences)
  Map<String, dynamic> toLocalJson() => {
    'userId': userId,
    'displayName': displayName,
    'email': email,

    // Academic/Professional
    'institution': institution,
    'country': country,
    'institutionType': institutionType,
    'major': major,
    'yearOfStudy': yearOfStudy,

    // Schedule & Goals
    'studyHours': studyHours.toJson(),
    'sleepHours': sleepHours.toJson(),
    'institutionHours': institutionHours.toJson(),
    'focusGoalMinutes': focusGoalMinutes,

    // Behavioral Preferences
    'distractingApps': distractingApps,
    'interventionStyle': interventionStyle,
    'enableFocusMode': enableFocusMode,
    'scrollThreshold': scrollThreshold,
    'cooldownMinutes': cooldownMinutes,

    // Tracking (as milliseconds for local storage)
    'createdAt': createdAt.millisecondsSinceEpoch,
    'lastModified': lastModified.millisecondsSinceEpoch,
    'lastSynced': lastSynced.millisecondsSinceEpoch,
    'daysUsed': daysUsed,

    // Adaptive thresholds
    'scrollSpeedThreshold': scrollSpeedThreshold,
    'sessionDurationThreshold': sessionDurationThreshold,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    userId: json['userId'] as String,
    displayName: json['displayName'] as String,
    email: json['email'] as String,

    // Academic/Professional (with fallbacks for backward compatibility)
    institution: json['institution'] as String? ?? '',
    country: json['country'] as String? ?? '',
    institutionType: json['institutionType'] as String? ?? 'University',
    major: json['major'] as String? ?? '',
    yearOfStudy: json['yearOfStudy'] as int? ?? 1,

    // Schedule & Goals
    studyHours: TimeRange.fromJson(json['studyHours'] as Map<String, dynamic>),
    sleepHours: TimeRange.fromJson(json['sleepHours'] as Map<String, dynamic>),
    institutionHours: TimeRange.fromJson(
      json['institutionHours'] as Map<String, dynamic>,
    ),
    focusGoalMinutes: json['focusGoalMinutes'] as int? ?? 360,

    // Behavioral Preferences (with fallbacks)
    distractingApps: List<String>.from(json['distractingApps'] as List? ?? []),
    interventionStyle: json['interventionStyle'] as String? ?? 'Moderate',
    enableFocusMode: json['enableFocusMode'] as bool? ?? false,
    scrollThreshold: json['scrollThreshold'] as int? ?? 50,
    cooldownMinutes: json['cooldownMinutes'] as int? ?? 15,

    // Tracking
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
    lastModified: json['lastModified'] != null
        ? DateTime.parse(json['lastModified'] as String)
        : DateTime.now(),
    lastSynced: json['lastSynced'] != null
        ? DateTime.parse(json['lastSynced'] as String)
        : DateTime.now(),
    daysUsed: json['daysUsed'] as int? ?? 0,

    // Adaptive thresholds
    scrollSpeedThreshold: json['scrollSpeedThreshold'] as double? ?? 15.0,
    sessionDurationThreshold:
        json['sessionDurationThreshold'] as double? ?? 300.0,
  );

  factory UserProfile.fromLocalJson(Map<String, dynamic> json) => UserProfile(
    userId: json['userId'] as String,
    displayName: json['displayName'] as String,
    email: json['email'] as String,

    // Academic/Professional
    institution: json['institution'] as String? ?? '',
    country: json['country'] as String? ?? '',
    institutionType: json['institutionType'] as String? ?? 'University',
    major: json['major'] as String? ?? '',
    yearOfStudy: json['yearOfStudy'] as int? ?? 1,

    // Schedule & Goals
    studyHours: TimeRange.fromJson(json['studyHours'] as Map<String, dynamic>),
    sleepHours: TimeRange.fromJson(json['sleepHours'] as Map<String, dynamic>),
    institutionHours: TimeRange.fromJson(
      json['institutionHours'] as Map<String, dynamic>,
    ),
    focusGoalMinutes: json['focusGoalMinutes'] as int? ?? 360,

    // Behavioral Preferences
    distractingApps: List<String>.from(json['distractingApps'] as List? ?? []),
    interventionStyle: json['interventionStyle'] as String? ?? 'Moderate',
    enableFocusMode: json['enableFocusMode'] as bool? ?? false,
    scrollThreshold: json['scrollThreshold'] as int? ?? 50,
    cooldownMinutes: json['cooldownMinutes'] as int? ?? 15,

    // Tracking (from milliseconds)
    createdAt: json['createdAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
        : DateTime.now(),
    lastModified: json['lastModified'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['lastModified'] as int)
        : DateTime.now(),
    lastSynced: json['lastSynced'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['lastSynced'] as int)
        : DateTime.now(),
    daysUsed: json['daysUsed'] as int? ?? 0,

    // Adaptive thresholds
    scrollSpeedThreshold: json['scrollSpeedThreshold'] as double? ?? 15.0,
    sessionDurationThreshold:
        json['sessionDurationThreshold'] as double? ?? 300.0,
  );

  UserProfile copyWith({
    String? displayName,

    // Academic/Professional
    String? institution,
    String? country,
    String? institutionType,
    String? major,
    int? yearOfStudy,

    // Schedule & Goals
    TimeRange? studyHours,
    TimeRange? sleepHours,
    TimeRange? institutionHours,
    int? focusGoalMinutes,

    // Behavioral Preferences
    List<String>? distractingApps,
    String? interventionStyle,
    bool? enableFocusMode,
    int? scrollThreshold,
    int? cooldownMinutes,

    // Tracking
    int? daysUsed,

    // Adaptive thresholds
    double? scrollSpeedThreshold,
    double? sessionDurationThreshold,
  }) => UserProfile(
    userId: userId,
    displayName: displayName ?? this.displayName,
    email: email,

    // Academic/Professional
    institution: institution ?? this.institution,
    country: country ?? this.country,
    institutionType: institutionType ?? this.institutionType,
    major: major ?? this.major,
    yearOfStudy: yearOfStudy ?? this.yearOfStudy,

    // Schedule & Goals
    studyHours: studyHours ?? this.studyHours,
    sleepHours: sleepHours ?? this.sleepHours,
    institutionHours: institutionHours ?? this.institutionHours,
    focusGoalMinutes: focusGoalMinutes ?? this.focusGoalMinutes,

    // Behavioral Preferences
    distractingApps: distractingApps ?? this.distractingApps,
    interventionStyle: interventionStyle ?? this.interventionStyle,
    enableFocusMode: enableFocusMode ?? this.enableFocusMode,
    scrollThreshold: scrollThreshold ?? this.scrollThreshold,
    cooldownMinutes: cooldownMinutes ?? this.cooldownMinutes,

    // Tracking (auto-update lastModified)
    createdAt: createdAt,
    lastModified: DateTime.now(), // Always update modified time
    lastSynced: DateTime.now(),
    daysUsed: daysUsed ?? this.daysUsed,

    // Adaptive thresholds
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
