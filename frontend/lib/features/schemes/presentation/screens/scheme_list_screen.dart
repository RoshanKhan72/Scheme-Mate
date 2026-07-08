import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/location_constants.dart';
import '../providers/eligibility_provider.dart';
import '../providers/scheme_provider.dart';
import '../providers/scheme_state.dart';
import 'scheme_detail_screen.dart';

class SchemeListScreen extends ConsumerStatefulWidget {
  const SchemeListScreen({super.key});

  @override
  ConsumerState<SchemeListScreen> createState() => _SchemeListScreenState();
}

class _SchemeListScreenState extends ConsumerState<SchemeListScreen> {
  final _searchController = TextEditingController();
  
  // Selection mode: 0 = Browse All, 1 = Matched Schemes
  int _matchingMode = 0;
  
  // Status filter for Matched mode
  String _selectedMatchStatus = 'All';

  // Filters for Browse All mode
  String _selectedState = 'All India';
  String _selectedCategory = 'All';
  String _selectedBeneficiary = 'All Citizens';

  final List<String> _categories = ['All', 'Agriculture', 'Education', 'Healthcare', 'Welfare', 'Business'];
  final List<String> _beneficiaries = ['All Citizens', 'Student', 'Farmer', 'Woman', 'Senior Citizen', 'Business Owner'];
  
  final List<String> _matchStatuses = ['All', 'Eligible', 'Partially Eligible', 'Unknown', 'Not Eligible'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyBrowseFilters() {
    ref.read(schemesProvider.notifier).fetchSchemes(
          search: _searchController.text.trim(),
          selectedState: _selectedState,
          category: _selectedCategory,
          beneficiaryType: _selectedBeneficiary,
        );
  }

  @override
  Widget build(BuildContext context) {
    final browseState = ref.watch(schemesProvider);
    final matchState = ref.watch(eligibilityProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. Selector Segment (Browse All vs Matched Schemes)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(
                        child: Text(
                          'Database Browse',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      selected: _matchingMode == 0,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _matchingMode = 0);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(
                        child: Text(
                          'Eligibility Matching',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      selected: _matchingMode == 1,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _matchingMode = 1);
                          ref.read(eligibilityProvider.notifier).fetchMatchingSchemes();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 2. Conditional Filter Menus
            if (_matchingMode == 0) ...[
              // Search Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search matching schemes...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applyBrowseFilters();
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (_) => _applyBrowseFilters(),
                  onChanged: (text) => setState(() {}),
                ),
              ),
              const SizedBox(height: 8),
              
              // Dropdowns scrollbar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    _buildFilterDropdown(
                      label: 'State: $_selectedState',
                      icon: Icons.map_outlined,
                      items: ['All India', 'Karnataka', ...LocationConstants.statesAndUTs.where((s) => s != 'Karnataka')],
                      selectedValue: _selectedState,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedState = val);
                          _applyBrowseFilters();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterDropdown(
                      label: 'Category: $_selectedCategory',
                      icon: Icons.category_outlined,
                      items: _categories,
                      selectedValue: _selectedCategory,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                          _applyBrowseFilters();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildFilterDropdown(
                      label: 'For: $_selectedBeneficiary',
                      icon: Icons.person_outline,
                      items: _beneficiaries,
                      selectedValue: _selectedBeneficiary,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedBeneficiary = val);
                          _applyBrowseFilters();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Matched Filter dropdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.filter_alt_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Filter Match Status:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.blueGrey[300] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedMatchStatus,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.blueGrey[800],
                        ),
                        items: _matchStatuses.map((st) {
                          return DropdownMenuItem(value: st, child: Text(st));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedMatchStatus = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 16),

            // 3. Matched warning checklist / List output resolve
            Expanded(
              child: _matchingMode == 0
                  ? _resolveSchemesList(browseState, false)
                  : _resolveSchemesList(matchState, true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required IconData icon,
    required List<String> items,
    required String selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          DropdownButton<String>(
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, size: 18),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.blueGrey[800],
            ),
            value: selectedValue,
            items: items.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _resolveSchemesList(SchemeState state, bool isMatchMode) {
    if (state.status == SchemeStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == SchemeStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            state.errorMessage ?? 'Failed to load schemes.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    var list = state.schemes;

    // Apply front-end status filters if matching mode is active
    if (isMatchMode) {
      if (_selectedMatchStatus != 'All') {
        list = list.where((scheme) {
          return scheme.eligibilityResult?.status == _selectedMatchStatus;
        }).toList();
      }
    }

    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No matching government schemes found.\nTry updating search inputs or your profile details.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    // Accumulate all missing profile fields across matched list to prompt user (as suggested!)
    final List<String> missingFieldsPrompt = [];
    if (isMatchMode) {
      for (var s in list) {
        final res = s.eligibilityResult;
        if (res != null && res.status == 'Unknown') {
          for (var field in res.missingFields) {
            if (!missingFieldsPrompt.contains(field)) {
              missingFieldsPrompt.add(field);
            }
          }
        }
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: list.length + (missingFieldsPrompt.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        // If we have missing profile elements, render a reminder alert card at the top
        if (missingFieldsPrompt.isNotEmpty && index == 0) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Card(
            margin: const EdgeInsets.only(bottom: 16, top: 4),
            color: Colors.orange.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Complete Profile to Verify Eligibility',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The engine matches parameters dynamically. Please supply details for:',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.blueGrey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: missingFieldsPrompt.map((field) {
                      return Chip(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          field,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.orange.withValues(alpha: 0.12),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }

        // Adjust index pointer if offset by missingFields alert card
        final schemeIndex = missingFieldsPrompt.isNotEmpty ? index - 1 : index;
        final scheme = list[schemeIndex];
        final isDark = Theme.of(context).brightness == Brightness.dark;

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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: scheme.state == 'Karnataka'
                              ? Colors.orange.withValues(alpha: 0.12)
                              : Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          scheme.state,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: scheme.state == 'Karnataka' ? Colors.orange[800] : Colors.blue[800],
                          ),
                        ),
                      ),
                      
                      // Render matching status badges if matching mode is active (as requested!)
                      if (isMatchMode && scheme.eligibilityResult != null)
                        _buildEligibilityStatusBadge(context, scheme.eligibilityResult!),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    scheme.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scheme.officialDepartment,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.blueGrey[300] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    scheme.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.blueGrey[400] : Colors.grey[500],
                    ),
                  ),

                  // If matched, show eligibility explanations snippet below card
                  if (isMatchMode && scheme.eligibilityResult != null) ...[
                    const Divider(height: 24),
                    _buildMatchingExplanationsSnippet(context, scheme.eligibilityResult!),
                  ] else ...[
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.devices_outlined, size: 14, color: Colors.teal),
                            const SizedBox(width: 4),
                            Text(
                              '${scheme.applicationMode} Mode',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Version ${scheme.versionNumber}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.blueGrey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEligibilityStatusBadge(BuildContext context, dynamic res) {
    final status = res.status;
    final matchScore = res.matchScore;
    
    Color color = Colors.grey;
    if (status == 'Eligible') color = Colors.green;
    if (status == 'Partially Eligible') color = Colors.orange;
    if (status == 'Not Eligible') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$status ($matchScore% Match)',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMatchingExplanationsSnippet(BuildContext context, dynamic res) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Find failed checklist rule checks to show reasons
    final failedChecks = res.checks.where((c) => c.passed == false).toList();
    final missingParams = res.checks.where((c) => c.passed == null).toList();

    if (res.status == 'Eligible') {
      return const Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
          SizedBox(width: 8),
          Text(
            'Eligible: You match all requirements.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ],
      );
    }

    if (res.status == 'Partially Eligible') {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Partially Eligible: Matches demographics, missing required documents.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.orange[300] : Colors.orange[800],
              ),
            ),
          ),
        ],
      );
    }

    // Fail reasons snippets
    final List<String> snippets = [];
    for (var c in failedChecks) {
      snippets.add(c.message);
    }
    for (var c in missingParams) {
      snippets.add(c.message);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              res.status == 'Unknown' ? Icons.help_outline : Icons.cancel_outlined,
              color: res.status == 'Unknown' ? Colors.grey : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              res.status == 'Unknown' ? 'Unknown Eligibility: Complete Profile' : 'Not Eligible Mismatch Reasons:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: res.status == 'Unknown' ? Colors.grey[600] : Colors.red[800],
              ),
            ),
          ],
        ),
        if (snippets.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: Text(
              snippets.take(2).join('\n'), // Limit to 2 lines for card summary clean look
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.blueGrey[300] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
