import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/location_constants.dart';
import '../../domain/entities/scheme.dart';
import '../providers/scheme_provider.dart';
import '../providers/scheme_state.dart';

class AdminSchemesScreen extends ConsumerStatefulWidget {
  const AdminSchemesScreen({super.key});

  @override
  ConsumerState<AdminSchemesScreen> createState() => _AdminSchemesScreenState();
}

class _AdminSchemesScreenState extends ConsumerState<AdminSchemesScreen> {
  @override
  Widget build(BuildContext context) {
    final schemeState = ref.watch(schemesProvider);

    // Listen for state status triggers
    ref.listen<SchemeState>(schemesProvider, (previous, next) {
      if (next.status == SchemeStatus.saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scheme configuration saved successfully.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next.status == SchemeStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel - Manage Schemes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Scheme',
            onPressed: () => _openSchemeFormDialog(null),
          ),
        ],
      ),
      body: SafeArea(
        child: schemeState.status == SchemeStatus.loading
            ? const Center(child: CircularProgressIndicator())
            : schemeState.schemes.isEmpty
                ? const Center(
                    child: Text('No government schemes found. Add one to start.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: schemeState.schemes.length,
                    itemBuilder: (context, index) {
                      final scheme = schemeState.schemes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            scheme.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${scheme.category} | Version ${scheme.versionNumber} | State: ${scheme.state}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                onPressed: () => _openSchemeFormDialog(scheme),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _confirmDelete(scheme),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  void _confirmDelete(Scheme scheme) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Scheme?'),
        content: Text('Are you sure you want to delete "${scheme.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
            onPressed: () {
              ref.read(schemesProvider.notifier).removeScheme(scheme.id);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _openSchemeFormDialog(Scheme? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SchemeFormBottomSheet(existing: existing, ref: ref),
    );
  }
}

class _SchemeFormBottomSheet extends StatefulWidget {
  final Scheme? existing;
  final WidgetRef ref;

  const _SchemeFormBottomSheet({this.existing, required this.ref});

  @override
  State<_SchemeFormBottomSheet> createState() => _SchemeFormBottomSheetState();
}

class _SchemeFormBottomSheetState extends State<_SchemeFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _benefitsController = TextEditingController();
  final _deptController = TextEditingController();
  final _websiteController = TextEditingController();
  final _appLinkController = TextEditingController();
  final _pdfLinkController = TextEditingController();
  
  // Rule-based parameters controllers
  final _minAgeController = TextEditingController();
  final _maxAgeController = TextEditingController();
  final _maxIncomeController = TextEditingController();
  
  // Compulsory logs reason controller
  final _changeLogController = TextEditingController();

  String _state = 'All India';
  String _category = 'Education';
  String _appMode = 'Online';
  String _status = 'Open';
  String _sourceType = 'Central Government';
  String _genderRule = 'All';

  bool _isStudent = false;
  bool _isFarmer = false;
  bool _isBusinessOwner = false;

  final List<String> _categories = ['Education', 'Agriculture', 'Healthcare', 'Welfare', 'Business'];
  final List<String> _appModes = ['Online', 'Offline', 'Both'];
  final List<String> _statuses = ['Upcoming', 'Open', 'Closed', 'Suspended', 'Archived'];
  final List<String> _sourceTypes = ['Central Government', 'State Government'];
  final List<String> _genders = ['All', 'Male', 'Female', 'Other'];

  // Categories checklist maps
  final Map<String, bool> _educationRules = {
    'SSLC': false,
    'PUC': false,
    'Diploma': false,
    'ITI': false,
    'Undergraduate': false,
    'Postgraduate': false,
    'PhD': false,
  };

  final Map<String, bool> _categoryRules = {
    'General': false,
    'OBC': false,
    'SC': false,
    'ST': false,
    'EWS': false,
  };

  // Documents checklist text controllers
  final List<String> _documents = [];
  final _newDocController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final s = widget.existing!;
      _nameController.text = s.name;
      _descController.text = s.description;
      _benefitsController.text = s.benefits;
      _deptController.text = s.officialDepartment;
      _websiteController.text = s.officialWebsite ?? '';
      _appLinkController.text = s.applicationLink ?? '';
      _pdfLinkController.text = s.pdfNotificationLink ?? '';
      
      _state = s.state;
      _category = _categories.contains(s.category) ? s.category : _categories.first;
      _appMode = _appModes.contains(s.applicationMode) ? s.applicationMode : _appModes.first;
      _status = _statuses.contains(s.status) ? s.status : _statuses.first;
      _sourceType = _sourceTypes.contains(s.sourceType) ? s.sourceType : _sourceTypes.first;
      
      // Parse structured rules
      final rules = s.eligibilityRules;
      _minAgeController.text = rules['minAge']?.toString() ?? '';
      _maxAgeController.text = rules['maxAge']?.toString() ?? '';
      _maxIncomeController.text = rules['maxIncome']?.toString() ?? '';
      _genderRule = _genders.contains(rules['gender']) ? rules['gender'] : _genders.first;
      
      _isStudent = rules['isStudent'] ?? false;
      _isFarmer = rules['isFarmer'] ?? false;
      _isBusinessOwner = rules['isBusinessOwner'] ?? false;

      if (rules['education'] != null) {
        final List edu = rules['education'] as List;
        for (var e in edu) {
          if (_educationRules.containsKey(e)) _educationRules[e] = true;
        }
      }

      if (rules['category'] != null) {
        final List cat = rules['category'] as List;
        for (var c in cat) {
          if (_categoryRules.containsKey(c)) _categoryRules[c] = true;
        }
      }

      _documents.addAll(s.requiredDocuments);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _benefitsController.dispose();
    _deptController.dispose();
    _websiteController.dispose();
    _appLinkController.dispose();
    _pdfLinkController.dispose();
    _minAgeController.dispose();
    _maxAgeController.dispose();
    _maxIncomeController.dispose();
    _changeLogController.dispose();
    _newDocController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // 1. Build structured rules map
      final Map<String, dynamic> rules = {};
      rules['state'] = _state;
      if (_minAgeController.text.isNotEmpty) rules['minAge'] = int.tryParse(_minAgeController.text);
      if (_maxAgeController.text.isNotEmpty) rules['maxAge'] = int.tryParse(_maxAgeController.text);
      if (_maxIncomeController.text.isNotEmpty) rules['maxIncome'] = double.tryParse(_maxIncomeController.text);
      rules['gender'] = _genderRule;
      rules['isStudent'] = _isStudent;
      rules['isFarmer'] = _isFarmer;
      rules['isBusinessOwner'] = _isBusinessOwner;

      final List<String> activeEdus = _educationRules.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();
      if (activeEdus.isNotEmpty) rules['education'] = activeEdus;

      final List<String> activeCats = _categoryRules.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();
      if (activeCats.isNotEmpty) rules['category'] = activeCats;

      // 2. Build Scheme payload
      final scheme = Scheme(
        id: widget.existing?.id ?? '',
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        state: _state,
        category: _category,
        eligibilityRules: rules,
        requiredDocuments: _documents,
        benefits: _benefitsController.text.trim(),
        officialWebsite: _websiteController.text.isEmpty ? null : _websiteController.text.trim(),
        applicationLink: _appLinkController.text.isEmpty ? null : _appLinkController.text.trim(),
        pdfNotificationLink: _pdfLinkController.text.isEmpty ? null : _pdfLinkController.text.trim(),
        applicationMode: _appMode,
        status: _status,
        sourceType: _sourceType,
        officialDepartment: _deptController.text.trim(),
        lastVerifiedDate: DateTime.now(),
        viewsCount: widget.existing?.viewsCount ?? 0,
        savesCount: widget.existing?.savesCount ?? 0,
        beneficiaryTypes: _isStudent ? ['Student'] : (_isFarmer ? ['Farmer'] : []), // Simple mapping
        tags: _category.toLowerCase().split(' '),
        versionNumber: widget.existing?.versionNumber ?? 1,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 3. Trigger Riverpod saving
      if (widget.existing == null) {
        widget.ref.read(schemesProvider.notifier).addScheme(scheme);
      } else {
        widget.ref.read(schemesProvider.notifier).editScheme(
              widget.existing!.id,
              scheme,
              _changeLogController.text.trim(),
            );
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.existing == null ? 'Add New Scheme' : 'Edit Scheme Details',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Divider(height: 24),

              // Inputs list
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Scheme Name *'),
                validator: (val) => val == null || val.isEmpty ? 'Scheme name required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description *'),
                validator: (val) => val == null || val.isEmpty ? 'Description required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _benefitsController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Benefits Details *'),
                validator: (val) => val == null || val.isEmpty ? 'Benefits required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _deptController,
                decoration: const InputDecoration(labelText: 'Official Department *'),
                validator: (val) => val == null || val.isEmpty ? 'Department required' : null,
              ),
              const SizedBox(height: 16),

              // Dropdown items
              DropdownButtonFormField<String>(
                initialValue: _state,
                decoration: const InputDecoration(labelText: 'State Availability *'),
                items: ['All India', 'Karnataka', ...LocationConstants.statesAndUTs.where((s) => s != 'Karnataka')].map((s) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _state = val);
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category *'),
                items: _categories.map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _appMode,
                decoration: const InputDecoration(labelText: 'Application Mode *'),
                items: _appModes.map((m) {
                  return DropdownMenuItem(value: m, child: Text(m));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _appMode = val);
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status *'),
                items: _statuses.map((st) {
                  return DropdownMenuItem(value: st, child: Text(st));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _sourceType,
                decoration: const InputDecoration(labelText: 'Source Type *'),
                items: _sourceTypes.map((st) {
                  return DropdownMenuItem(value: st, child: Text(st));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _sourceType = val);
                },
              ),
              const SizedBox(height: 16),

              // Links
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(labelText: 'Official Website URL'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _appLinkController,
                decoration: const InputDecoration(labelText: 'Application Portal URL'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pdfLinkController,
                decoration: const InputDecoration(labelText: 'Notification PDF Link'),
              ),
              const SizedBox(height: 24),

              // Rules Section
              const Text('Structured Eligibility Rules Configuration', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
              const Divider(color: Colors.teal),

              TextFormField(
                controller: _minAgeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Minimum Age (e.g. 18)'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _maxAgeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Maximum Age (e.g. 60)'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _maxIncomeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Maximum Household Income (₹)'),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _genderRule,
                decoration: const InputDecoration(labelText: 'Gender Restriction'),
                items: _genders.map((g) {
                  return DropdownMenuItem(value: g, child: Text(g));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _genderRule = val);
                },
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Is Student status required?'),
                value: _isStudent,
                onChanged: (val) => setState(() => _isStudent = val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Is Farmer status required?'),
                value: _isFarmer,
                onChanged: (val) => setState(() => _isFarmer = val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Is Business Owner status required?'),
                value: _isBusinessOwner,
                onChanged: (val) => setState(() => _isBusinessOwner = val),
              ),

              const SizedBox(height: 16),
              const Text('Allowed Caste Categories:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._categoryRules.keys.map((catKey) {
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(catKey),
                  value: _categoryRules[catKey],
                  onChanged: (val) => setState(() => _categoryRules[catKey] = val ?? false),
                );
              }),

              const SizedBox(height: 16),
              const Text('Allowed Educational qualifications:', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._educationRules.keys.map((eduKey) {
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(eduKey),
                  value: _educationRules[eduKey],
                  onChanged: (val) => setState(() => _educationRules[eduKey] = val ?? false),
                );
              }),

              const Divider(height: 32),
              const Text('Required Documents Checklist', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _newDocController,
                      decoration: const InputDecoration(hintText: 'Add document name (e.g. PAN Card)'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.teal),
                    onPressed: () {
                      if (_newDocController.text.trim().isNotEmpty) {
                        setState(() {
                          _documents.add(_newDocController.text.trim());
                          _newDocController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _documents.map((doc) {
                  return Chip(
                    label: Text(doc),
                    deleteIcon: const Icon(Icons.cancel, size: 16),
                    onDeleted: () {
                      setState(() {
                        _documents.remove(doc);
                      });
                    },
                  );
                }).toList(),
              ),

              if (widget.existing != null) ...[
                const Divider(height: 32),
                TextFormField(
                  controller: _changeLogController,
                  decoration: const InputDecoration(
                    labelText: 'Change Summary (Required) *',
                    helperText: 'Describe details of edits for version tracking.',
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Please summarize changes' : null,
                ),
              ],

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Save Scheme'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
