import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profile/presentation/widgets/feedback_dialog.dart';
import '../providers/eligibility_provider.dart';
import '../providers/saved_provider.dart';
import '../providers/scheme_provider.dart';
import '../providers/scheme_state.dart';

class SchemeDetailScreen extends ConsumerStatefulWidget {
  final String schemeId;

  const SchemeDetailScreen({super.key, required this.schemeId});

  @override
  ConsumerState<SchemeDetailScreen> createState() => _SchemeDetailScreenState();
}

class _SchemeDetailScreenState extends ConsumerState<SchemeDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(schemesProvider.notifier).fetchSchemeDetails(widget.schemeId);
      _saveRecentlyViewed();
    });
  }

  void _saveRecentlyViewed() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final list = prefs.getStringList('recently_viewed_ids') ?? [];
      list.remove(widget.schemeId);
      list.insert(0, widget.schemeId);
      if (list.length > 5) list.removeLast();
      prefs.setStringList('recently_viewed_ids', list);
    } catch (e) {
      debugPrint('Failed to cache recently viewed: $e');
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schemeState = ref.watch(schemesProvider);
    final rawScheme = schemeState.selectedScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final eligibilityState = ref.watch(eligibilityProvider);
    dynamic scheme = rawScheme;
    if (rawScheme != null && eligibilityState.status == SchemeStatus.loaded) {
      try {
        scheme = eligibilityState.schemes.firstWhere((s) => s.id == widget.schemeId);
      } catch (_) {
        // Fallback to raw details if not in matches list
      }
    }

    final eligibilityResult = scheme?.eligibilityResult;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scheme Details'),
        actions: scheme != null
            ? [
                _buildBookmarkButton(context, scheme),
              ]
            : null,
      ),
      body: schemeState.status == SchemeStatus.detailsLoading
          ? const Center(child: CircularProgressIndicator())
          : scheme == null
              ? const Center(child: Text('Failed to load scheme details.'))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Trust & Verification Badge Card
                        _buildTrustHeader(context, scheme),
                        const SizedBox(height: 20),

                        // Private Note Box (If Bookmarked) (NEW!)
                        if (ref.watch(savedSchemesProvider.notifier).isSaved(scheme.id)) ...[
                          _buildPrivateNoteBox(context, scheme),
                          const SizedBox(height: 20),
                        ],

                        // Rule Engine Matching Checklist Panel
                        if (eligibilityResult != null) ...[
                          _buildEligibilityEngineChecklist(context, eligibilityResult),
                          const SizedBox(height: 20),
                        ],

                        // General Information
                        Text(
                          scheme.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          scheme.officialDepartment,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.blueGrey[300] : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          scheme.description,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                        const SizedBox(height: 24),

                        // Benefits Box
                        _buildBenefitsCard(context, scheme.benefits),
                        const SizedBox(height: 24),

                        // Strict eligibility specs
                        _buildEligibilityRulesCard(context, scheme.eligibilityRules),
                        const SizedBox(height: 24),

                        // Required Documents Checklist
                        _buildDocumentsCard(context, scheme.requiredDocuments),
                        const SizedBox(height: 24),

                        // Actions Links
                        _buildOfficialLinksSection(context, scheme),
                        const SizedBox(height: 24),

                        // Report Incorrect Info Button
                        _buildReportInfoCard(context, scheme),
                        const SizedBox(height: 24),

                        // Version metadata footer
                        _buildVersionFooter(context, scheme),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildBookmarkButton(BuildContext context, dynamic scheme) {
    final isBookmarked = ref.watch(savedSchemesProvider.notifier).isSaved(scheme.id);
    return IconButton(
      icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
      onPressed: () {
        if (isBookmarked) {
          _confirmUnsaveDetail(context, scheme.id);
        } else {
          ref.read(savedSchemesProvider.notifier).addBookmark(scheme);
        }
      },
    );
  }

  Widget _buildPrivateNoteBox(BuildContext context, dynamic scheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final note = ref.watch(savedSchemesProvider.notifier).getNote(scheme.id);
    
    return Card(
      elevation: 0,
      color: Colors.teal.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.teal.withValues(alpha: 0.2), width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showEditNoteDialog(context, scheme),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.edit_note, color: Colors.teal, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'My Private Note',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal),
                      ),
                    ],
                  ),
                  Icon(Icons.chevron_right, size: 18, color: Colors.teal.withValues(alpha: 0.6)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                note.isNotEmpty ? '"$note"' : 'Add a private note to this scheme...',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: note.isNotEmpty ? FontStyle.italic : FontStyle.normal,
                  color: note.isNotEmpty 
                      ? (isDark ? Colors.blueGrey[200] : Colors.blueGrey[800])
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditNoteDialog(BuildContext context, dynamic scheme) {
    final note = ref.read(savedSchemesProvider.notifier).getNote(scheme.id);
    final controller = TextEditingController(text: note);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Private Note'),
        content: TextField(
          controller: controller,
          maxLines: 2,
          decoration: const InputDecoration(hintText: 'Enter note details...'),
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

  void _confirmUnsaveDetail(BuildContext context, String schemeId) {
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

  Widget _buildEligibilityEngineChecklist(BuildContext context, dynamic res) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = res.status;
    final score = res.matchScore;
    final confidence = res.confidence;

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;
    if (status == 'Eligible') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (status == 'Partially Eligible') {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber_rounded;
    } else if (status == 'Not Eligible') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eligibility: $status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        'Score: $score% Match  |  Confidence: $confidence%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.blueGrey[300] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              'Profile Rule Evaluation Checks:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ...res.checks.map<Widget>((check) {
              IconData checkIcon = Icons.help_outline;
              Color checkColor = Colors.grey;
              
              if (check.passed == true) {
                checkIcon = Icons.check_circle_outline;
                checkColor = Colors.green;
              } else if (check.passed == false) {
                checkIcon = Icons.cancel_outlined;
                checkColor = Colors.red;
              } else {
                checkIcon = Icons.info_outline;
                checkColor = Colors.orange;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(checkIcon, color: checkColor, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: checkColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  check.ruleId,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    color: checkColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            check.message,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.blueGrey[300] : Colors.blueGrey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustHeader(BuildContext context, dynamic scheme) {
    final isCentral = scheme.sourceType == 'Central Government';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    String verifiedDateStr = 'Not verified';
    if (scheme.lastVerifiedDate != null) {
      final List<String> months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      final d = scheme.lastVerifiedDate!;
      verifiedDateStr = '${d.day} ${months[d.month - 1]} ${d.year}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCentral
            ? Colors.indigo.withValues(alpha: 0.08)
            : Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCentral
              ? Colors.indigo.withValues(alpha: 0.2)
              : Colors.orange.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified,
            color: isCentral ? Colors.indigo : Colors.orange[800],
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCentral ? Colors.indigo : Colors.orange[800],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        scheme.sourceType.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'TRUSTED SOURCE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Last Verified: $verifiedDateStr',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.blueGrey[300] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard(BuildContext context, String benefits) {
    return Card(
      elevation: 0,
      color: Colors.green.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.monetization_on_outlined, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Scheme Benefits',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.green),
            Text(
              benefits,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEligibilityRulesCard(BuildContext context, Map<String, dynamic> rules) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final List<String> ruleTexts = [];
    if (rules.containsKey('state')) {
      ruleTexts.add('Resident State: ${rules["state"]}');
    }
    if (rules.containsKey('minAge')) {
      ruleTexts.add('Minimum Age: ${rules["minAge"]} years');
    }
    if (rules.containsKey('maxAge')) {
      ruleTexts.add('Maximum Age: ${rules["maxAge"]} years');
    }
    if (rules.containsKey('maxIncome')) {
      final income = rules["maxIncome"];
      ruleTexts.add('Annual Family Income: Below ₹$income');
    }
    if (rules.containsKey('gender') && rules['gender'] != 'All') {
      ruleTexts.add('Gender Restriction: ${rules["gender"]}');
    }
    if (rules.containsKey('isStudent') && rules['isStudent'] == true) {
      ruleTexts.add('Candidate must be a Student');
    }
    if (rules.containsKey('isFarmer') && rules['isFarmer'] == true) {
      ruleTexts.add('Candidate must be a Farmer');
    }
    if (rules.containsKey('isBusinessOwner') && rules['isBusinessOwner'] == true) {
      ruleTexts.add('Candidate must own a small Business');
    }
    if (rules.containsKey('education')) {
      final List eduList = rules['education'] as List;
      ruleTexts.add('Education qualifications: ${eduList.join(", ")}');
    }
    if (rules.containsKey('category')) {
      final List catList = rules['category'] as List;
      ruleTexts.add('Caste Categories allowed: ${catList.join(", ")}');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Strict Eligibility Criteria',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 24),
            if (ruleTexts.isEmpty)
              Text(
                'Open to all citizens matching general category bounds.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.blueGrey[400] : Colors.grey[600],
                ),
              )
            else
              ...ruleTexts.map((rule) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.teal),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rule,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsCard(BuildContext context, List<String> docs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Required Documents Checklist',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 24),
            if (docs.isEmpty)
              Text(
                'No standard documents are specified. Self-declaration may apply.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.blueGrey[400] : Colors.grey[600],
                ),
              )
            else
              ...docs.map((doc) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_box_outlined, size: 18, color: Colors.teal),
                      const SizedBox(width: 12),
                      Text(
                        doc,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficialLinksSection(BuildContext context, dynamic scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Official Application Actions',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 12),
        if (scheme.applicationLink != null) ...[
          ElevatedButton.icon(
            onPressed: () => _copyToClipboard(scheme.applicationLink!, 'Application link'),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Copy Application Link'),
          ),
          const SizedBox(height: 8),
        ],
        if (scheme.officialWebsite != null) ...[
          OutlinedButton.icon(
            onPressed: () => _copyToClipboard(scheme.officialWebsite!, 'Official website URL'),
            icon: const Icon(Icons.language),
            label: const Text('Copy Official Website'),
          ),
          const SizedBox(height: 8),
        ],
        if (scheme.pdfNotificationLink != null)
          OutlinedButton.icon(
            onPressed: () => _copyToClipboard(scheme.pdfNotificationLink!, 'PDF notification link'),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Copy Notification PDF Link'),
          ),
      ],
    );
  }

  Widget _buildVersionFooter(BuildContext context, dynamic scheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scheme Database ID',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.blueGrey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SelectableText(
                    scheme.id,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Verification Status',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.blueGrey[400] : Colors.grey[600],
                ),
              ),
              Text(
                'Active (Version ${scheme.versionNumber})',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildReportInfoCard(BuildContext context, dynamic scheme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          FeedbackDialog.show(
            context,
            defaultScreen: 'Scheme Detail: ${scheme.name}',
            defaultType: 'incorrect_scheme',
            targetId: scheme.id,
          );
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            children: [
              Icon(Icons.report_problem_outlined, color: Colors.redAccent),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Report incorrect scheme details or parameters',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.redAccent, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
