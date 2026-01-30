import 'package:flutter/material.dart';
import 'package:doom_breaker/UI/Widgets/app_text.dart';
import 'package:doom_breaker/models/user_profile.dart';
import 'package:doom_breaker/services/storage_service.dart';
import 'package:doom_breaker/services/sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'permission_guide_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static const String name = '/onboarding';

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Form data
  TimeOfDay _studyStart = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _studyEnd = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _sleepStart = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _sleepEnd = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _institutionStart = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _institutionEnd = const TimeOfDay(hour: 14, minute: 0);
  int _focusGoalMinutes = 360; // 6 hours

  // NEW: Institution & Country form data
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _majorController = TextEditingController();
  String _selectedCountry = 'Bangladesh';
  String _institutionType = 'University';
  int _yearOfStudy = 1;

  final List<String> _countries = [
    'Afghanistan',
    'Albania',
    'Algeria',
    'Argentina',
    'Australia',
    'Austria',
    'Bangladesh',
    'Belgium',
    'Brazil',
    'Canada',
    'China',
    'Denmark',
    'Egypt',
    'Finland',
    'France',
    'Germany',
    'Greece',
    'India',
    'Indonesia',
    'Iran',
    'Iraq',
    'Ireland',
    'Israel',
    'Italy',
    'Japan',
    'Kenya',
    'Malaysia',
    'Mexico',
    'Netherlands',
    'New Zealand',
    'Nigeria',
    'Norway',
    'Pakistan',
    'Philippines',
    'Poland',
    'Portugal',
    'Russia',
    'Saudi Arabia',
    'Singapore',
    'South Africa',
    'South Korea',
    'Spain',
    'Sweden',
    'Switzerland',
    'Thailand',
    'Turkey',
    'Ukraine',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'Vietnam',
    'Other',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _institutionController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _completeOnboarding() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final storage = StorageService();
    await storage.init();

    // Create user profile
    final profile = UserProfile(
      userId: user.id,
      displayName: user.email?.split('@').first ?? 'User',
      email: user.email ?? '',

      // Academic info (from institution page)
      institution: _institutionController.text.trim(),
      country: _selectedCountry,
      institutionType: _institutionType,
      major: _majorController.text.trim(),
      yearOfStudy: _yearOfStudy,
      // Schedule
      studyHours: TimeRange(
        start: _formatTimeOfDay(_studyStart),
        end: _formatTimeOfDay(_studyEnd),
      ),
      sleepHours: TimeRange(
        start: _formatTimeOfDay(_sleepStart),
        end: _formatTimeOfDay(_sleepEnd),
      ),
      institutionHours: TimeRange(
        start: _formatTimeOfDay(_institutionStart),
        end: _formatTimeOfDay(_institutionEnd),
      ),
      focusGoalMinutes: _focusGoalMinutes,
    );

    await storage.saveUserProfile(profile);
    await storage.setOnboardingComplete(true);

    // Sync to cloud
    SyncService().setUserId(user.id);
    await SyncService().syncUserProfile(profile);

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(PermissionGuidePage.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: List.generate(4, (index) {
                  // Changed from 3 to 4
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(
                        right: index < 3 ? 8 : 0,
                      ), // Changed from 2 to 3
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? const Color(0xFF1976D2)
                            : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(),
                  _buildInstitutionPage(), // NEW: Institution & Country page
                  _buildSchedulePage(),
                  _buildGoalPage(),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const AppText.action(
                        'Back',
                        color: Color(0xFF546E7A),
                      ),
                    )
                  else
                    const SizedBox(width: 80),

                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < 3) {
                        // Changed from 2 to 3
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: Colors.blue.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: AppText.action(
                      _currentPage < 3
                          ? 'Next'
                          : 'Get Started', // Changed from 2 to 3
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  size: 80,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 32),
              const AppText.hero(
                'Welcome to Doom Breaker',
                textAlign: TextAlign.center,
                color: Color(0xFF0D47A1),
              ),
              const SizedBox(height: 16),
              AppText.body(
                'Your AI-powered focus companion that helps you stay productive and avoid digital distractions.',
                textAlign: TextAlign.center,
                color: const Color(0xFF546E7A),
              ),
              const SizedBox(height: 48),
              _buildFeatureItem(
                Icons.rocket_launch_rounded,
                'Smart Detection',
                'Detects infinite scrolling and reels automatically',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                Icons.trending_up_rounded,
                'Track Progress',
                'See your productivity improve over time',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                Icons.emoji_events_rounded,
                'Compete & Improve',
                'Join the leaderboard and stay motivated',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstitutionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),

          // Header
          const AppText.hero(
            'Tell us about yourself',
            color: Color(0xFF0D47A1),
          ),
          const SizedBox(height: 8),
          AppText.body(
            'This helps us personalize your experience',
            color: const Color(0xFF546E7A),
          ),
          const SizedBox(height: 40),

          // Institution Name Field
          TextFormField(
            controller: _institutionController,
            decoration: const InputDecoration(
              labelText: 'Institution Name',
              hintText: 'e.g., Dhaka University',
              prefixIcon: Icon(Icons.school, color: Color(0xFF1976D2)),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),

          // Country Dropdown
          DropdownButtonFormField<String>(
            value: _selectedCountry,
            decoration: const InputDecoration(
              labelText: 'Country',
              prefixIcon: Icon(Icons.public, color: Color(0xFF1976D2)),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            items: _countries.map((country) {
              return DropdownMenuItem(value: country, child: Text(country));
            }).toList(),
            onChanged: (value) => setState(() => _selectedCountry = value!),
          ),
          const SizedBox(height: 20),

          // Institution Type
          DropdownButtonFormField<String>(
            value: _institutionType,
            decoration: const InputDecoration(
              labelText: 'Institution Type',
              prefixIcon: Icon(Icons.category, color: Color(0xFF1976D2)),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            items: ['University', 'School', 'Workplace', 'Other']
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) => setState(() => _institutionType = value!),
          ),
          const SizedBox(height: 20),

          // Major (Optional)
          TextFormField(
            controller: _majorController,
            decoration: const InputDecoration(
              labelText: 'Major / Field of Study (Optional)',
              hintText: 'e.g., Computer Science',
              prefixIcon: Icon(Icons.book, color: Color(0xFF1976D2)),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),

          // Year of Study (if University)
          if (_institutionType == 'University')
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText.action('Year of Study', color: Color(0xFF0D47A1)),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('1st')),
                    ButtonSegment(value: 2, label: Text('2nd')),
                    ButtonSegment(value: 3, label: Text('3rd')),
                    ButtonSegment(value: 4, label: Text('4th+')),
                  ],
                  selected: {_yearOfStudy},
                  onSelectionChanged: (Set<int> selection) {
                    setState(() => _yearOfStudy = selection.first);
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>((
                      states,
                    ) {
                      if (states.contains(MaterialState.selected)) {
                        return const Color(0xFF1976D2);
                      }
                      return Colors.white;
                    }),
                    foregroundColor: MaterialStateProperty.resolveWith<Color>((
                      states,
                    ) {
                      if (states.contains(MaterialState.selected)) {
                        return Colors.white;
                      }
                      return const Color(0xFF1976D2);
                    }),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF1976D2)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.action(title, color: const Color(0xFF0D47A1)),
              const SizedBox(height: 4),
              AppText.bodySmall(description, color: const Color(0xFF546E7A)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSchedulePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const AppText.hero('Set Your Schedule', color: Color(0xFF0D47A1)),
          const SizedBox(height: 8),
          AppText.body(
            'When do you usually study and sleep? This helps us provide better reminders.',
            color: const Color(0xFF546E7A),
          ),
          const SizedBox(height: 40),

          // Study hours
          AppText.action('Study Hours', color: const Color(0xFF1976D2)),
          const SizedBox(height: 16),
          _buildTimeRangePicker(
            'Start',
            _studyStart,
            (time) => setState(() => _studyStart = time),
          ),
          const SizedBox(height: 12),
          _buildTimeRangePicker(
            'End',
            _studyEnd,
            (time) => setState(() => _studyEnd = time),
          ),
          const SizedBox(height: 32),

          // Sleep hours
          AppText.action('Sleep Hours', color: const Color(0xFF1976D2)),
          const SizedBox(height: 16),
          _buildTimeRangePicker(
            'Bedtime',
            _sleepStart,
            (time) => setState(() => _sleepStart = time),
          ),
          const SizedBox(height: 12),
          _buildTimeRangePicker(
            'Wake Up',
            _sleepEnd,
            (time) => setState(() => _sleepEnd = time),
          ),
          const SizedBox(height: 32),

          // Institution hours
          AppText.action('Institution Hours', color: const Color(0xFF1976D2)),
          const SizedBox(height: 16),
          _buildTimeRangePicker(
            'Start',
            _institutionStart,
            (time) => setState(() => _institutionStart = time),
          ),
          const SizedBox(height: 12),
          _buildTimeRangePicker(
            'End',
            _institutionEnd,
            (time) => setState(() => _institutionEnd = time),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangePicker(
    String label,
    TimeOfDay time,
    Function(TimeOfDay) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF1976D2),
                  onPrimary: Colors.white,
                  onSurface: Color(0xFF0D47A1),
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.1)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText.body(label, color: const Color(0xFF546E7A)),
            Row(
              children: [
                AppText.action(
                  time.format(context),
                  color: const Color(0xFF0D47A1),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF1976D2)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalPage() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events_outlined,
                size: 80,
                color: Color(0xFF1976D2),
              ),
              const SizedBox(height: 32),
              const AppText.hero('Daily Focus Goal', color: Color(0xFF0D47A1)),
              const SizedBox(height: 16),
              AppText.body(
                'How many hours do you want to focus each day?',
                textAlign: TextAlign.center,
                color: const Color(0xFF546E7A),
              ),
              const SizedBox(height: 48),

              AppText.hero(
                '${(_focusGoalMinutes / 60).toStringAsFixed(1)} hours',
                color: const Color(0xFF1976D2),
              ),
              const SizedBox(height: 24),

              Slider(
                value: _focusGoalMinutes.toDouble(),
                min: 60,
                max: 720,
                divisions: 22,
                activeColor: const Color(0xFF1976D2),
                thumbColor: const Color(0xFF1976D2),
                inactiveColor: const Color(0xFF1976D2).withOpacity(0.2),
                label: '${(_focusGoalMinutes / 60).toStringAsFixed(1)} hrs',
                onChanged: (value) {
                  setState(() => _focusGoalMinutes = value.round());
                },
              ),

              const SizedBox(height: 24),
              AppText.bodySmall(
                '${_focusGoalMinutes} minutes per day',
                color: const Color(0xFF546E7A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
