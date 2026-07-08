import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/dashboard/domain/entities/dashboard_summary.dart';
import '../../../../features/dashboard/presentation/providers/dashboard_provider.dart';
import '../../../../features/schemes/domain/entities/scheme.dart';
import '../../../../features/schemes/presentation/providers/saved_provider.dart';
import '../../../../features/schemes/presentation/screens/scheme_detail_screen.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/presentation/screens/profile_edit_screen.dart';
import '../../../schemes/presentation/screens/admin_schemes_screen.dart';
import '../../../schemes/presentation/screens/scheme_list_screen.dart';
import '../providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../notifications/presentation/screens/notification_list_screen.dart';
import '../../../profile/presentation/widgets/feedback_dialog.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _currentIndex = 0;

  // Sorting & Filtering variables for the Saved Tab
  String _savedSort = 'Recently Saved';
  String _savedFilter = 'All';

  final List<String> _sortOptions = ['Recently Saved', 'Closing Soon', 'Eligible First', 'Alphabetically'];
  final List<String> _filterOptions = ['All', 'Eligible', 'Partially Eligible', 'Not Eligible', 'Open', 'Closing Soon'];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAdmin = user?.role == 'admin';

    // Bottom Navigation Bar config supporting "Saved" Tab
    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.search_outlined),
        activeIcon: Icon(Icons.search),
        label: 'Browse',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.bookmark_outline),
        activeIcon: Icon(Icons.bookmark),
        label: 'Saved',
      ),
    ];

    if (isAdmin) {
      navItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings_outlined),
          activeIcon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      );
    }

    Widget bodyWidget;
    if (_currentIndex == 0) {
      bodyWidget = _buildPersonalizedDashboard(context, user);
    } else if (_currentIndex == 1) {
      bodyWidget = const SchemeListScreen();
    } else if (_currentIndex == 2) {
      bodyWidget = _buildSavedSchemesTab(context);
    } else if (isAdmin && _currentIndex == 3) {
      bodyWidget = const AdminSchemesScreen();
    } else {
      bodyWidget = _buildPersonalizedDashboard(context, user);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0
            ? 'Scheme Mate'
            : (_currentIndex == 1
                ? 'Browse Schemes'
                : (_currentIndex == 2 ? 'Saved Bookmarks' : 'Admin Panel'))),
        actions: [
          _buildNotificationBadge(context, ref),
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            tooltip: 'Report Issue / Feedback',
            onPressed: () {
              FeedbackDialog.show(
                context,
                defaultScreen: _currentIndex == 0
                    ? 'Dashboard Feed'
                    : (_currentIndex == 1 ? 'Browse Schemes Screen' : 'Saved Schemes Screen'),
                defaultType: 'bug',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: bodyWidget,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: navItems,
      ),
    );
  }

  Widget _buildPersonalizedDashboard(BuildContext context, dynamic user) {
    final dashboardState = ref.watch(dashboardProvider);
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;

    if (dashboardState.status == DashboardStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dashboardState.status == DashboardStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dashboardState.errorMessage ?? 'Failed to load dashboard metrics.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(dashboardProvider.notifier).fetchDashboardSummary();
                  ref.read(profileProvider.notifier).fetchProfile();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final summary = dashboardState.summary;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(dashboardProvider.notifier).fetchDashboardSummary();
        await ref.read(profileProvider.notifier).fetchProfile();
        ref.read(savedSchemesProvider.notifier).fetchSavedSchemes();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWelcomeHeader(context, user?.name),
            const SizedBox(height: 16),

            if (summary == null || profile == null) ...[
              _buildEmptyStateBanner(context),
            ] else ...[
              _buildPriorityActionCard(context, summary),
              const SizedBox(height: 20),
              _buildQuickStatsMetrics(context, summary),
              const SizedBox(height: 20),
              _buildRecentlyViewedStrip(context, summary),
              const SizedBox(height: 20),
              _buildFeedSection(
                context,
                title: '🎯 Recommended for You',
                schemes: summary.recommended,
                showMatchTag: true,
              ),
              const SizedBox(height: 20),
              _buildFeedSection(
                context,
                title: '📢 New Schemes',
                schemes: summary.newSchemes,
              ),
              const SizedBox(height: 20),
              _buildFeedSection(
                context,
                title: '🔥 Trending Schemes',
                schemes: summary.trending,
              ),
              const SizedBox(height: 20),
              _buildClosingSoonFeedSection(context, summary.closingSoon),
              const SizedBox(height: 20),
              _buildMissingDocumentsActionCard(context, summary.missingDocuments),
              const SizedBox(height: 20),

              ExpansionTile(
                title: const Text(
                  'My Eligibility Profile Parameters',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  'Last Updated: ${_formatDate(summary.lastUpdated)}',
                  style: const TextStyle(fontSize: 11),
                ),
                leading: const Icon(Icons.person_pin_outlined, color: Colors.teal),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildEligibilityDetailsCard(context, profile),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedSchemesTab(BuildContext context) {
    final savedState = ref.watch(savedSchemesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (savedState.status == SavedStatus.loading && savedState.schemes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (savedState.status == SavedStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                savedState.errorMessage ?? 'Failed to load bookmarks.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(savedSchemesProvider.notifier).fetchSavedSchemes(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Process lists filters locally
    var filteredList = savedState.schemes;

    if (_savedFilter != 'All') {
      filteredList = filteredList.where((scheme) {
        final res = scheme.eligibilityResult;
        if (_savedFilter == 'Eligible') return res?.status == 'Eligible';
        if (_savedFilter == 'Partially Eligible') return res?.status == 'Partially Eligible';
        if (_savedFilter == 'Not Eligible') return res?.status == 'Not Eligible';
        if (_savedFilter == 'Open') return scheme.status == 'Open';
        if (_savedFilter == 'Closing Soon') {
          if (scheme.endDate == null) return false;
          final today = DateTime.now();
          final diff = scheme.endDate!.difference(DateTime(today.year, today.month, today.day)).inDays;
          return diff >= 0 && diff <= 30;
        }
        return true;
      }).toList();
    }

    // Process sorting locally
    filteredList.sort((a, b) {
      if (_savedSort == 'Alphabetically') {
        return a.name.compareTo(b.name);
      }
      if (_savedSort == 'Closing Soon') {
        if (a.endDate == null && b.endDate == null) return 0;
        if (a.endDate == null) return 1;
        if (b.endDate == null) return -1;
        return a.endDate!.compareTo(b.endDate!);
      }
      if (_savedSort == 'Eligible First') {
        final priority = {'Eligible': 0, 'Partially Eligible': 1, 'Unknown': 2, 'Not Eligible': 3};
        final aPriority = priority[a.eligibilityResult?.status] ?? 4;
        final bPriority = priority[b.eligibilityResult?.status] ?? 4;
        return aPriority.compareTo(bPriority);
      }
      // Default: Recently Saved
      if (a.savedAt == null && b.savedAt == null) return 0;
      if (a.savedAt == null) return 1;
      if (b.savedAt == null) return -1;
      return b.savedAt!.compareTo(a.savedAt!);
    });

    return SafeArea(
      child: Column(
        children: [
          // Offline Banner Indicator (as requested!)
          if (savedState.isOffline)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.amber.withValues(alpha: 0.15),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_outlined, color: Colors.orange, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Offline Mode: Cached from ${_formatDate(savedState.cachedAt)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),

          // Filters and Sorting Selector row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _savedFilter,
                    decoration: const InputDecoration(labelText: 'Filter', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black),
                    items: _filterOptions.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _savedFilter = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _savedSort,
                    decoration: const InputDecoration(labelText: 'Sort by', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black),
                    items: _sortOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _savedSort = val);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main list display
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(savedSchemesProvider.notifier).fetchSavedSchemes(),
              child: filteredList.isEmpty
                  ? const Center(
                      child: Text('No bookmarked schemes found.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredList.length,
                      itemBuilder: (context, idx) {
                        final scheme = filteredList[idx];
                        
                        // Compute warnings deadline if closing soon (closes in <7 days)
                        int closingDays = -1;
                        if (scheme.endDate != null) {
                          final today = DateTime.now();
                          closingDays = scheme.endDate!.difference(DateTime(today.year, today.month, today.day)).inDays;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => SchemeDetailScreen(schemeId: scheme.id),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Card Header: Match Badges and Save timestamps
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (scheme.eligibilityResult != null)
                                        _buildMiniStatusBadge(scheme.eligibilityResult!.status)
                                      else
                                        const SizedBox(),
                                      Text(
                                        'Saved on: ${_formatDate(scheme.savedAt)}',
                                        style: TextStyle(fontSize: 11, color: isDark ? Colors.blueGrey[400] : Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Name and department
                                  Text(
                                    scheme.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    scheme.officialDepartment,
                                    style: TextStyle(fontSize: 12, color: isDark ? Colors.blueGrey[300] : Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 12),

                                  // Private note display
                                  if (scheme.privateNote != null && scheme.privateNote!.isNotEmpty) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
                                      ),
                                      child: Text(
                                        '📝 Note: "${scheme.privateNote}"',
                                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],

                                  // Deadline Warnings (as requested!)
                                  if (closingDays >= 0 && closingDays <= 7) ...[
                                    Row(
                                      children: [
                                        const Icon(Icons.alarm, size: 14, color: Colors.red),
                                        const SizedBox(width: 6),
                                        Text(
                                          closingDays == 0
                                              ? '⏰ Closes today - Apply now!'
                                              : (closingDays == 1 ? '⏰ Closes tomorrow!' : '⏰ Closes in $closingDays days!'),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                  ],

                                  // Card Actions Buttons (Notes edit, Unsave)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_note_outlined, color: Colors.teal, size: 20),
                                        tooltip: 'Edit Note',
                                        onPressed: () => _showEditNoteDialog(context, scheme),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.bookmark_remove_outlined, color: Colors.redAccent, size: 20),
                                        tooltip: 'Unsave Bookmark',
                                        onPressed: () => _confirmUnsave(context, scheme.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatusBadge(String status) {
    Color c = Colors.grey;
    if (status == 'Eligible') c = Colors.green;
    if (status == 'Partially Eligible') c = Colors.orange;
    if (status == 'Not Eligible') c = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c),
      ),
    );
  }

  void _showEditNoteDialog(BuildContext context, Scheme scheme) {
    final controller = TextEditingController(text: scheme.privateNote ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Private Note'),
        content: TextField(
          controller: controller,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'Enter save notes... (e.g. need income cert first)'),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () {
              ref.read(savedSchemesProvider.notifier).editBookmarkNote(scheme.id, controller.text.trim());
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _confirmUnsave(BuildContext context, String schemeId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Bookmark?'),
        content: const Text('Remove this scheme from Saved?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
            onPressed: () {
              ref.read(savedSchemesProvider.notifier).removeBookmark(schemeId);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, String? name) {
    final today = DateTime.now();
    String greeting = 'Welcome';
    if (today.hour < 12) {
      greeting = 'Good Morning';
    } else if (today.hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, ${name ?? "User"} 👋',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const Text(
          'Your personalized government benefit matching feed.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildEmptyStateBanner(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Icon(Icons.spa_outlined, size: 56, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Welcome to Scheme Mate!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete your socioeconomic profile details to discover government schemes matched to your eligibility criteria.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileEditScreen(),
                  ),
                );
              },
              child: const Text('Setup Eligibility Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityActionCard(BuildContext context, DashboardSummary summary) {
    final completion = summary.profileCompletion;
    final eligible = summary.eligibleCount;
    final partially = summary.partiallyEligibleCount;
    final missingDocs = summary.missingDocumentsCount;

    String text = '';
    String buttonText = '';
    VoidCallback action = () {};
    IconData icon = Icons.info_outline;
    Color color = Colors.blue;

    if (completion < 50) {
      text = 'Complete your socio-economic profile details to check eligibility rules matching.';
      buttonText = 'Complete Profile';
      icon = Icons.warning_amber_rounded;
      color = Colors.orange;
      action = () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ProfileEditScreen(),
          ),
        );
      };
    } else if (missingDocs > 0) {
      text = 'Submit $missingDocs missing documents to unlock $partially partially eligible government schemes.';
      buttonText = 'Submit Documents';
      icon = Icons.description_outlined;
      color = Colors.orange;
      action = () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ProfileEditScreen(),
          ),
        );
      };
    } else if (eligible > 0) {
      text = '🎉 Verified match! You are fully eligible for $eligible government schemes.';
      buttonText = 'View Eligible Schemes';
      icon = Icons.verified_user_outlined;
      color = Colors.green;
      action = () {
        setState(() {
          _currentIndex = 1;
        });
      };
    } else {
      text = 'Add qualifications, occupations or check lists in profile to discover matching schemes.';
      buttonText = 'Modify Profile';
      action = () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ProfileEditScreen(),
          ),
        );
      };
    }

    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: action,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsMetrics(BuildContext context, DashboardSummary summary) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            label: 'Eligible',
            count: summary.eligibleCount,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            context,
            label: 'Partial Match',
            count: summary.partiallyEligibleCount,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            context,
            label: 'Missing Docs',
            count: summary.missingDocumentsCount,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, {required String label, required int count, required Color color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.blueGrey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Scheme> _getRecentlyViewedSchemes(DashboardSummary summary) {
    final prefs = ref.read(sharedPreferencesProvider);
    final ids = prefs.getStringList('recently_viewed_ids') ?? [];
    final allFeeds = [
      ...summary.recommended,
      ...summary.newSchemes,
      ...summary.trending,
      ...summary.closingSoon
    ];
    final List<Scheme> result = [];
    for (var id in ids) {
      try {
        final found = allFeeds.firstWhere((s) => s.id == id);
        if (!result.contains(found)) result.add(found);
      } catch (_) {}
    }
    return result;
  }

  Widget _buildRecentlyViewedStrip(BuildContext context, DashboardSummary summary) {
    final recentlyViewed = _getRecentlyViewedSchemes(summary);
    if (recentlyViewed.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recently Viewed',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentlyViewed.length,
            itemBuilder: (context, index) {
              final scheme = recentlyViewed[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SchemeDetailScreen(schemeId: scheme.id),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scheme.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            scheme.officialDepartment,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeedSection(
    BuildContext context, {
    required String title,
    required List<Scheme> schemes,
    bool showMatchTag = false,
  }) {
    if (schemes.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentIndex = 1;
                });
              },
              child: const Text('View All', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        ...schemes.map((scheme) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                scheme.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Text(
                scheme.officialDepartment,
                style: const TextStyle(fontSize: 11),
              ),
              trailing: showMatchTag && scheme.eligibilityResult != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${scheme.eligibilityResult!.matchScore}% Match',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    )
                  : const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SchemeDetailScreen(schemeId: scheme.id),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  String _formatDeadline(DateTime endDate) {
    final today = DateTime.now();
    final difference = endDate.difference(DateTime(today.year, today.month, today.day)).inDays;
    if (difference == 0) return 'Ends today';
    if (difference == 1) return 'Ends tomorrow';
    return 'Ends in $difference days';
  }

  Widget _buildClosingSoonFeedSection(BuildContext context, List<Scheme> schemes) {
    if (schemes.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '⏰ Closing Soon',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentIndex = 1;
                });
              },
              child: const Text('View All', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        ...schemes.map((scheme) {
          final deadlineStr = scheme.endDate != null ? _formatDeadline(scheme.endDate!) : 'Closing soon';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                scheme.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Text(
                scheme.officialDepartment,
                style: const TextStyle(fontSize: 11),
              ),
              trailing: Text(
                deadlineStr,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SchemeDetailScreen(schemeId: scheme.id),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMissingDocumentsActionCard(BuildContext context, List<String> docs) {
    if (docs.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.description, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Missing Documents List',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
                ),
              ],
            ),
            const Divider(height: 20),
            const Text(
              'Aadhaar, income certificates, and cast credentials are key matching variables. Get these documents to complete matches:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: docs.map((doc) {
                return Chip(
                  avatar: const Icon(Icons.warning, size: 14, color: Colors.orange),
                  label: Text(
                    doc,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Never';
    final List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Widget _buildEligibilityDetailsCard(BuildContext context, UserProfile p) {
    final formattedIncome = '₹${p.annualIncome.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(context, 'Date of Birth / Age', '${p.dob.day}/${p.dob.month}/${p.dob.year} (${p.age} years old)'),
            _buildDetailRow(context, 'Gender', p.gender),
            _buildDetailRow(context, 'Marital Status', p.maritalStatus),
            _buildDetailRow(context, 'Social Category', p.category),
            _buildDetailRow(context, 'Ration Card Class', p.bplAplStatus == 'None' ? 'No Ration Card' : '${p.bplAplStatus} Card'),
            _buildDetailRow(context, 'Annual Family Income', formattedIncome),
            _buildDetailRow(context, 'Education', p.education),
            _buildDetailRow(context, 'Occupation', p.occupation),
            _buildDetailRow(context, 'Address Location', '${p.villageCity}, ${p.taluk != null ? "${p.taluk}, " : ""}${p.district}, ${p.state}'),
            
            const Divider(height: 24),
            const Text(
              'Eligibility Attributes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBadge(context, 'Student', p.isStudent),
                _buildBadge(context, 'Farmer', p.isFarmer),
                _buildBadge(context, 'Business Owner', p.isBusinessOwner),
                _buildBadge(context, 'Disability Status', p.disabilityStatus),
                _buildBadge(context, 'Minority Community', p.minorityStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.blueGrey[400] : Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String label, bool active) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
            : (isDark ? Colors.blueGrey[800] : Colors.grey[200]),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: active
              ? Theme.of(context).colorScheme.primary
              : (isDark ? Colors.blueGrey[300] : Colors.grey[700]),
        ),
      ),
    );
  }

  Widget _buildNotificationBadge(BuildContext context, WidgetRef ref) {
    final count = ref.read(notificationProvider.notifier).unreadCount;
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const NotificationListScreen(),
              ),
            );
          },
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
