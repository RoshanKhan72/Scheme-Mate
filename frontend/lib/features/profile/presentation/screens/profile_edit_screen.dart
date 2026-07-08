import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/responsive_layout.dart';

import '../../../../core/constants/location_constants.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_provider.dart';
import '../providers/profile_state.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  final UserProfile? existingProfile;

  const ProfileEditScreen({super.key, this.existingProfile});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // State parameters
  DateTime? _dob;
  String _gender = 'Male';
  String _state = 'Karnataka';
  String _district = '';
  String? _taluk;
  final _villageCityController = TextEditingController();
  String _occupation = 'Student';
  String _education = 'Undergraduate';
  final _incomeController = TextEditingController();
  String _maritalStatus = 'Single';
  String _category = 'General';
  bool _minorityStatus = false;
  bool _disabilityStatus = false;
  bool _isStudent = false;
  bool _isFarmer = false;
  bool _isBusinessOwner = false;
  String _bplAplStatus = 'None';

  // Documents state JSON mapping
  final Map<String, dynamic> _localDocuments = {
    'Aadhaar': <String, dynamic>{'exists': false, 'expiryDate': null},
    'PAN': <String, dynamic>{'exists': false, 'expiryDate': null},
    'Income Certificate': <String, dynamic>{'exists': false, 'expiryDate': null},
    'Caste Certificate': <String, dynamic>{'exists': false, 'expiryDate': null},
  };

  // Location data loaded from assets
  Map<String, List<String>> _karnatakaLocations = {};
  bool _isLoadingLocations = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  
  final List<String> _occupations = [
    'Student',
    'Farmer',
    'Government Employee',
    'Private Employee',
    'Self Employed',
    'Business Owner',
    'Labourer',
    'Homemaker',
    'Unemployed',
    'Retired',
    'Other'
  ];

  final List<String> _educations = [
    'No Formal Education',
    'Primary',
    'SSLC',
    'PUC',
    'Diploma',
    'ITI',
    'Undergraduate',
    'Postgraduate',
    'PhD',
    'Other'
  ];

  final List<String> _maritalStatuses = ['Single', 'Married', 'Divorced', 'Widowed'];
  final List<String> _categories = ['General', 'OBC', 'SC', 'ST', 'EWS', 'Other'];
  final List<String> _bplAplOptions = ['None', 'APL', 'BPL'];

  @override
  void initState() {
    super.initState();
    _loadKarnatakaLocations();
    _prefillFields();
  }

  @override
  void dispose() {
    _villageCityController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  void _prefillFields() {
    final p = widget.existingProfile;
    if (p != null) {
      _dob = p.dob;
      _gender = _genders.contains(p.gender) ? p.gender : _genders.first;
      _state = LocationConstants.statesAndUTs.contains(p.state) ? p.state : _state;
      _district = p.district;
      _taluk = p.taluk;
      _villageCityController.text = p.villageCity;
      _occupation = _occupations.contains(p.occupation) ? p.occupation : _occupations.first;
      _education = _educations.contains(p.education) ? p.education : _educations.first;
      _incomeController.text = p.annualIncome.toStringAsFixed(0);
      _maritalStatus = _maritalStatuses.contains(p.maritalStatus) ? p.maritalStatus : _maritalStatuses.first;
      _category = _categories.contains(p.category) ? p.category : _categories.first;
      _minorityStatus = p.minorityStatus;
      _disabilityStatus = p.disabilityStatus;
      _isStudent = p.isStudent;
      _isFarmer = p.isFarmer;
      _isBusinessOwner = p.isBusinessOwner;
      _bplAplStatus = _bplAplOptions.contains(p.bplAplStatus) ? p.bplAplStatus : _bplAplOptions.first;
      
      // Merge documents checklist mapping
      p.documents.forEach((key, value) {
        if (_localDocuments.containsKey(key)) {
          _localDocuments[key] = Map<String, dynamic>.from(value as Map);
        }
      });
    }
  }

  Future<void> _loadKarnatakaLocations() async {
    setState(() {
      _isLoadingLocations = true;
    });
    try {
      final jsonStr = await DefaultAssetBundle.of(context)
          .loadString('assets/locations/karnataka.json');
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      final districtsMap = data['districts'] as Map<String, dynamic>;

      final Map<String, List<String>> temp = {};
      districtsMap.forEach((key, value) {
        temp[key] = List<String>.from(value as List);
      });

      setState(() {
        _karnatakaLocations = temp;
        _isLoadingLocations = false;
        
        // If pre-filled district is not valid in Karnataka, reset it
        if (_state == 'Karnataka' && _district.isNotEmpty && !_karnatakaLocations.containsKey(_district)) {
          _district = '';
          _taluk = null;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingLocations = false;
      });
      debugPrint('Error loading locations configuration: $e');
    }
  }

  void _selectDateOfBirth() async {
    final initialDate = _dob ?? DateTime.now().subtract(const Duration(days: 365 * 18));
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        _dob = selectedDate;
      });
    }
  }

  void _selectDocumentExpiryDate(String docName) async {
    final initialDate = DateTime.now().add(const Duration(days: 365));
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (selectedDate != null) {
      setState(() {
        _localDocuments[docName]['expiryDate'] =
            selectedDate.toIso8601String().substring(0, 10);
      });
    }
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _submit() {
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your Date of Birth.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final double income = double.tryParse(_incomeController.text) ?? 0.0;
      
      final profile = UserProfile(
        id: widget.existingProfile?.id ?? '', // Upsert queries override empty string IDs
        userId: widget.existingProfile?.userId ?? '',
        dob: _dob!,
        gender: _gender,
        state: _state,
        district: _district.trim(),
        taluk: _taluk,
        villageCity: _villageCityController.text.trim(),
        occupation: _occupation,
        education: _education,
        annualIncome: income,
        maritalStatus: _maritalStatus,
        category: _category,
        minorityStatus: _minorityStatus,
        disabilityStatus: _disabilityStatus,
        isStudent: _isStudent,
        isFarmer: _isFarmer,
        isBusinessOwner: _isBusinessOwner,
        bplAplStatus: _bplAplStatus,
        documents: _localDocuments,
        extraEligibility: widget.existingProfile?.extraEligibility ?? {},
        createdAt: widget.existingProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(profileProvider.notifier).saveProfile(profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ProfileState>(profileProvider, (previous, next) {
      if (next.status == ProfileStatus.saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      } else if (next.status == ProfileStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final profileState = ref.watch(profileProvider);
    final isKarnataka = _state == 'Karnataka';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile Details'),
      ),
      body: _isLoadingLocations
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ResponsiveLayout(
                maxWidth: 900,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section 1: Demographics
                      _buildSectionHeader('Demographics & Identity'),
                      const SizedBox(height: 16),

                      // DOB Datepicker field
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        tileColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: Text(
                          _dob == null
                              ? 'Select Date of Birth *'
                              : 'DOB: ${_dob!.day}/${_dob!.month}/${_dob!.year}',
                        ),
                        trailing: _dob != null
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Age: ${_calculateAge(_dob!)} yrs',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              )
                            : null,
                        onTap: _selectDateOfBirth,
                      ),
                      const SizedBox(height: 16),

                      // Gender Dropdown
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Gender *',
                          prefixIcon: Icon(Icons.people_outline),
                        ),
                        items: _genders.map((g) {
                          return DropdownMenuItem(value: g, child: Text(g));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _gender = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Marital Status Dropdown
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _maritalStatus,
                        decoration: const InputDecoration(
                          labelText: 'Marital Status *',
                          prefixIcon: Icon(Icons.favorite_border),
                        ),
                        items: _maritalStatuses.map((m) {
                          return DropdownMenuItem(value: m, child: Text(m));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _maritalStatus = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'Social Category *',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        items: _categories.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),
                      const SizedBox(height: 32),

                      // Section 2: Residential Location
                      _buildSectionHeader('Residential Information'),
                      const SizedBox(height: 16),

                      // State dropdown
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _state,
                        decoration: const InputDecoration(
                          labelText: 'State / Union Territory *',
                          prefixIcon: Icon(Icons.map_outlined),
                        ),
                        items: LocationConstants.statesAndUTs.map((s) {
                          return DropdownMenuItem(value: s, child: Text(s));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _state = val;
                              _district = '';
                              _taluk = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // District Selection (Dropdown for Karnataka, Text Field for fallback)
                      isKarnataka
                          ? DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: (_district.isNotEmpty && _karnatakaLocations.containsKey(_district)) ? _district : null,
                              decoration: const InputDecoration(
                                labelText: 'District *',
                                prefixIcon: Icon(Icons.location_city_outlined),
                              ),
                              items: _karnatakaLocations.keys.map((d) {
                                return DropdownMenuItem(value: d, child: Text(d));
                              }).toList(),
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'Please select a district' : null,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _district = val;
                                    _taluk = null;
                                  });
                                }
                              },
                            )
                          : TextFormField(
                              controller: TextEditingController(text: _district),
                              decoration: const InputDecoration(
                                labelText: 'District *',
                                prefixIcon: Icon(Icons.location_city_outlined),
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'District is required' : null,
                              onChanged: (val) => _district = val,
                            ),
                      const SizedBox(height: 16),

                      // Taluk Selection (Dropdown for Karnataka, Text Field for fallback)
                      isKarnataka
                          ? DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: (_taluk != null && _district.isNotEmpty && _karnatakaLocations.containsKey(_district) && (_karnatakaLocations[_district] ?? []).contains(_taluk)) ? _taluk : null,
                              decoration: const InputDecoration(
                                labelText: 'Taluk / Sub-district',
                                prefixIcon: Icon(Icons.nature_people_outlined),
                              ),
                              items: _district.isNotEmpty
                                  ? (_karnatakaLocations[_district] ?? []).map((t) {
                                      return DropdownMenuItem(value: t, child: Text(t));
                                    }).toList()
                                  : [],
                              onChanged: (val) {
                                setState(() {
                                  _taluk = val;
                                });
                              },
                            )
                          : TextFormField(
                              controller: TextEditingController(text: _taluk ?? ''),
                              decoration: const InputDecoration(
                                labelText: 'Taluk / Sub-district',
                                prefixIcon: Icon(Icons.nature_people_outlined),
                              ),
                              onChanged: (val) => _taluk = val.trim().isEmpty ? null : val,
                            ),
                      const SizedBox(height: 16),

                      // Village / City text field
                      TextFormField(
                        controller: _villageCityController,
                        decoration: const InputDecoration(
                          labelText: 'Village / Town / City *',
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your village, town, or city';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // Section 3: Socio-Economic Params
                      _buildSectionHeader('Socio-Economic Profile'),
                      const SizedBox(height: 16),

                      // Occupation Dropdown
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _occupation,
                        decoration: const InputDecoration(
                          labelText: 'Occupation *',
                          prefixIcon: Icon(Icons.work_outline),
                        ),
                        items: _occupations.map((o) {
                          return DropdownMenuItem(value: o, child: Text(o));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _occupation = val;
                              if (val == 'Student') _isStudent = true;
                              if (val == 'Farmer') _isFarmer = true;
                              if (val == 'Business Owner') _isBusinessOwner = true;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Education Dropdown
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _education,
                        decoration: const InputDecoration(
                          labelText: 'Highest Education Level *',
                          prefixIcon: Icon(Icons.school_outlined),
                        ),
                        items: _educations.map((e) {
                          return DropdownMenuItem(value: e, child: Text(e));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _education = val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Annual Income field
                      TextFormField(
                        controller: _incomeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Annual Family Income (₹) *',
                          prefixIcon: Icon(Icons.currency_rupee_outlined),
                          helperText: 'Provide the exact numeric value (e.g. 240000)',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your family annual income';
                          }
                          final parsed = double.tryParse(value);
                          if (parsed == null || parsed < 0) {
                            return 'Please enter a valid positive number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // BPL/APL status Dropdown
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _bplAplStatus,
                        decoration: const InputDecoration(
                          labelText: 'Ration Card Status (APL/BPL) *',
                          prefixIcon: Icon(Icons.wallet_membership_outlined),
                        ),
                        items: _bplAplOptions.map((opt) {
                          return DropdownMenuItem(
                            value: opt,
                            child: Text(opt == 'None' ? 'No Ration Card (None)' : '$opt Card'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _bplAplStatus = val);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Binary check switches
                      SwitchListTile(
                        title: const Text('Are you a Student?'),
                        subtitle: const Text('Active enrolment in a school or college'),
                        value: _isStudent,
                        onChanged: (val) => setState(() => _isStudent = val),
                      ),
                      SwitchListTile(
                        title: const Text('Are you a Farmer?'),
                        subtitle: const Text('Owns agricultural land or engaged in farming'),
                        value: _isFarmer,
                        onChanged: (val) => setState(() => _isFarmer = val),
                      ),
                      SwitchListTile(
                        title: const Text('Are you a Business Owner?'),
                        subtitle: const Text('Owns or runs a registered micro/small enterprise'),
                        value: _isBusinessOwner,
                        onChanged: (val) => setState(() => _isBusinessOwner = val),
                      ),
                      SwitchListTile(
                        title: const Text('Disability Status'),
                        subtitle: const Text('Check if you have a physical/mental disability'),
                        value: _disabilityStatus,
                        onChanged: (val) => setState(() => _disabilityStatus = val),
                      ),
                      SwitchListTile(
                        title: const Text('Minority Community Status'),
                        subtitle: const Text('Belong to a notified religious/linguistic minority'),
                        value: _minorityStatus,
                        onChanged: (val) => setState(() => _minorityStatus = val),
                      ),
                      const SizedBox(height: 32),

                      // Section 4: Documents Checklist & Expiry Dates
                      _buildSectionHeader('Existing Documents & Certificates'),
                      const SizedBox(height: 8),
                      Text(
                        'Select the documents you currently hold. Provide expiry dates for dynamic validation.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.blueGrey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),

                      ..._localDocuments.keys.map((docName) {
                        final bool hasDoc = _localDocuments[docName]['exists'] as bool;
                        final String? expiryStr = _localDocuments[docName]['expiryDate'] as String?;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(docName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  value: hasDoc,
                                  onChanged: (val) {
                                    setState(() {
                                      _localDocuments[docName]['exists'] = val ?? false;
                                      if (val == false) {
                                        _localDocuments[docName]['expiryDate'] = null;
                                      }
                                    });
                                  },
                                ),
                                if (hasDoc && (docName == 'Income Certificate' || docName == 'Caste Certificate' || docName == 'PAN'))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0, left: 16.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          expiryStr == null
                                              ? 'No expiry date set'
                                              : 'Expires: ${expiryStr.split('-').reversed.join('/')}',
                                          style: TextStyle(
                                            color: expiryStr == null
                                                ? (isDark ? Colors.blueGrey[400] : Colors.grey[600])
                                                : Theme.of(context).colorScheme.primary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        TextButton.icon(
                                          icon: const Icon(Icons.date_range, size: 16),
                                          label: Text(expiryStr == null ? 'Set Date' : 'Change'),
                                          onPressed: () => _selectDocumentExpiryDate(docName),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 40),

                      // Save profile parameters action
                      ElevatedButton(
                        onPressed: profileState.status == ProfileStatus.saving
                            ? null
                            : _submit,
                        child: profileState.status == ProfileStatus.saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Save Eligibility Parameters'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 3,
          width: 60,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
