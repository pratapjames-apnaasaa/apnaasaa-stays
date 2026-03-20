import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:unite_india_app/config/maps_config.dart';
import 'package:unite_india_app/core/domain/host_listing_snapshot.dart';
import 'package:unite_india_app/core/domain/user.dart';
import 'package:unite_india_app/core/domain/verification_status.dart';
import 'package:unite_india_app/core/repositories/auth_repository.dart';
import 'package:unite_india_app/core/repositories/host_repository.dart';
import 'package:unite_india_app/core/repositories/trust_repository.dart';
import 'package:unite_india_app/services/geocoding/web_geocoder.dart';

enum _PropertyType {
  entireHome,
  privateRoom,
  sharedRoom,
}

class HostOnboardingPage extends StatefulWidget {
  const HostOnboardingPage({
    super.key,
    required this.currentUser,
    required this.authRepository,
    required this.hostRepository,
    required this.trustRepository,
    this.initialListing,
  });

  final UniteUser currentUser;
  final AuthRepository authRepository;
  final HostRepository hostRepository;
  final TrustRepository trustRepository;

  /// When set, form fields are filled from a saved draft or existing listing.
  final HostListingSnapshot? initialListing;

  @override
  State<HostOnboardingPage> createState() => _HostOnboardingPageState();
}

class _HostOnboardingPageState extends State<HostOnboardingPage> {
  int step = 1;
  final List<int> selectedSectors = <int>[];

  late GoogleMapController mapController;
  final LatLng _center = const LatLng(17.3850, 78.4867);
  LatLng? _resolvedCenter;
  bool _isGeocoding = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  String? _selectedState;

  final TextEditingController _exactAddressController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();

  _PropertyType _propertyType = _PropertyType.privateRoom;
  int _maxGuests = 1;
  int _bedrooms = 1;
  int _beds = 1;
  int _bathrooms = 1;
  bool _initializedTrust = false;

  // Step 4 — house rules
  bool _ruleNoLateEntryAfter9 = false;
  bool _ruleNoSmokingInside = false;
  bool _ruleNoCooking = false;
  bool _ruleNoOutsideGuests = false;
  bool _ruleNoPets = false;
  final TextEditingController _otherHouseRulesController =
      TextEditingController();

  // Step 5 — safety
  bool _safetyOnlyQueerOrAllies = false;
  bool _safetyNoOutingDiscretion = false;
  bool _safetyBuildingSecurity24x7 = false;
  bool _safetySeparateEntry = false;
  final TextEditingController _safetyNotesController = TextEditingController();

  // Step 6 — pricing
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  bool _longStayDiscountOffered = false;
  final TextEditingController _cleaningFeeController = TextEditingController();
  final TextEditingController _extraGuestFeeController =
      TextEditingController();
  final TextEditingController _otherChargesController =
      TextEditingController();

  // Step 7 — KYC (mock)
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  int _kycAttempts = 0;
  bool _kycBlocked = false;
  bool _kycVerified = false;

  @override
  void initState() {
    super.initState();
    final s = widget.initialListing;
    if (s != null) {
      _applyListingSnapshot(s);
    }
  }

  void _applyListingSnapshot(HostListingSnapshot s) {
    _nameController.text = s.displayName ?? '';
    _locationController.text = s.areaLabel ?? '';
    _cityController.text = s.city ?? '';
    _selectedState = s.state;
    _exactAddressController.text = s.exactAddress ?? '';
    _landmarkController.text = s.landmark ?? '';
    if (s.lat != null && s.lng != null) {
      _resolvedCenter = LatLng(s.lat!, s.lng!);
    }
    selectedSectors
      ..clear()
      ..addAll(s.sectors ?? <int>[]);
    if (s.propertyType != null) {
      _propertyType = _parsePropertyType(s.propertyType);
    }
    if (s.maxGuests != null) _maxGuests = s.maxGuests!.clamp(1, 50);
    if (s.bedrooms != null) _bedrooms = s.bedrooms!.clamp(1, 50);
    if (s.beds != null) _beds = s.beds!.clamp(1, 50);
    if (s.bathrooms != null) _bathrooms = s.bathrooms!.clamp(1, 50);
    _ruleNoLateEntryAfter9 = s.ruleNoLateEntryAfter9 ?? false;
    _ruleNoSmokingInside = s.ruleNoSmokingInside ?? false;
    _ruleNoCooking = s.ruleNoCooking ?? false;
    _ruleNoOutsideGuests = s.ruleNoOutsideGuests ?? false;
    _ruleNoPets = s.ruleNoPets ?? false;
    _otherHouseRulesController.text = s.otherHouseRules ?? '';
    _safetyOnlyQueerOrAllies = s.safetyOnlyQueerOrAllies ?? false;
    _safetyNoOutingDiscretion = s.safetyNoOutingDiscretion ?? false;
    _safetyBuildingSecurity24x7 = s.safetyBuildingSecurity24x7 ?? false;
    _safetySeparateEntry = s.safetySeparateEntry ?? false;
    _safetyNotesController.text = s.safetyNotesForQueerGuests ?? '';
    if (s.minNightlyPriceInr != null) {
      _minPriceController.text = '${s.minNightlyPriceInr}';
    }
    if (s.maxNightlyPriceInr != null) {
      _maxPriceController.text = '${s.maxNightlyPriceInr}';
    }
    _longStayDiscountOffered = s.longStayDiscountOffered ?? false;
    if (s.cleaningFeeInr != null) {
      _cleaningFeeController.text = '${s.cleaningFeeInr}';
    }
    if (s.extraGuestFeeInr != null) {
      _extraGuestFeeController.text = '${s.extraGuestFeeInr}';
    }
    _otherChargesController.text = s.otherChargesNote ?? '';
    _kycVerified = s.kycVerifiedPilot ?? false;
    _kycAttempts = s.kycFailedAttempts ?? 0;
    _kycBlocked = s.kycBlockedPilot ?? false;
  }

  _PropertyType _parsePropertyType(String? name) {
    switch (name) {
      case 'entireHome':
        return _PropertyType.entireHome;
      case 'sharedRoom':
        return _PropertyType.sharedRoom;
      case 'privateRoom':
      default:
        return _PropertyType.privateRoom;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedTrust) {
      _initializedTrust = true;
      _ensureBasicTrustProfile();
    }
  }

  Future<void> _ensureBasicTrustProfile() async {
    final profile = TrustProfile(
      userId: widget.currentUser.id,
      trustLevel: TrustLevel.newAccount,
      verificationStatus: VerificationStatus(
        kycLevel: KycLevel.none,
        hasVerifiedPaymentMethod: false,
        lastKycAt: null,
        kycProvider: null,
        kycReferenceId: null,
      ),
      completedStays: 0,
      cancellations: 0,
      reportsCount: 0,
    );
    await widget.trustRepository.updateTrustProfile(profile);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _exactAddressController.dispose();
    _landmarkController.dispose();
    _otherHouseRulesController.dispose();
    _safetyNotesController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _cleaningFeeController.dispose();
    _extraGuestFeeController.dispose();
    _otherChargesController.dispose();
    _aadhaarController.dispose();
    _panController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          switch (step) {
            1 => 'Step 1: Host & Area',
            2 => 'Step 2: Comfort Sectors',
            3 => 'Step 3: Address & Property',
            4 => 'Step 4: House Rules',
            5 => 'Step 5: Safety & Comfort',
            6 => 'Step 6: Pricing & Extras',
            7 => 'Step 7: Identity (pilot)',
            _ => 'Step 8: Review & Publish',
          },
        ),
        backgroundColor: Colors.orange,
        actions: [
          TextButton(
            onPressed: () {
              widget.authRepository.signOut();
            },
            child: const Text(
              'Sign out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: switch (step) {
        1 => _buildStep1(),
        2 => _buildStep2(),
        3 => _buildStep3(),
        4 => _buildStep4(),
        5 => _buildStep5(),
        6 => _buildStep6(),
        7 => _buildStep7(),
        _ => _buildStep8(),
      },
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Signed in as ${widget.currentUser.phoneNumber.isEmpty ? 'phone verified user' : widget.currentUser.phoneNumber}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Text(
                'Unite India builds trust in layers.\n\n'
                'In this pilot, we are collecting only what is needed '
                'to understand where you can safely host. '
                'Later, you can choose to complete stronger verification '
                'to unlock a higher trust level.',
              ),
            ),
          ),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Preferred name (for community)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Area / Neighborhood',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Autocomplete<String>(
            initialValue: TextEditingValue(text: _cityController.text),
            optionsBuilder: (TextEditingValue value) {
              final q = value.text.trim().toLowerCase();
              if (q.isEmpty) return const Iterable<String>.empty();
              return _majorIndianCities
                  .where((c) => c.toLowerCase().contains(q))
                  .take(10);
            },
            onSelected: (city) {
              _cityController.text = city;
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmit) {
              controller.text = _cityController.text;
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'City (optional)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _cityController.text = v,
              );
            },
          ),
          const SizedBox(height: 12),
          Autocomplete<String>(
            initialValue:
                TextEditingValue(text: _selectedState ?? ''),
            optionsBuilder: (TextEditingValue value) {
              final q = value.text.trim().toLowerCase();
              if (q.isEmpty) return const Iterable<String>.empty();
              return _indianStatesAndUts
                  .where((s) => s.toLowerCase().contains(q))
                  .take(10);
            },
            onSelected: (state) {
              setState(() => _selectedState = state);
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmit) {
              controller.text = _selectedState ?? '';
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'State / UT (optional)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _selectedState = v),
              );
            },
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _resolvedCenter == null
                  ? 'Map target: not resolved yet'
                  : 'Map target: ${_resolvedCenter!.latitude.toStringAsFixed(5)}, ${_resolvedCenter!.longitude.toStringAsFixed(5)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              backgroundColor: Colors.orange,
            ),
            onPressed: _isGeocoding
                ? null
                : () async {
              if (_nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please share a name the community can see'),
                  ),
                );
                return;
              }
              await _resolveAreaToMapCenter();
              if (!mounted) {
                return;
              }
              setState(() => step = 2);
            },
            child: _isGeocoding
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'PROCEED TO MAP',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _resolvedCenter ?? _center,
            zoom: 14.0,
          ),
          onMapCreated: (GoogleMapController controller) {
            mapController = controller;
            final target = _resolvedCenter;
            if (target != null) {
              controller.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(target: target, zoom: 15.0),
                ),
              );
            }
          },
          myLocationEnabled: true,
          zoomControlsEnabled: false,
        ),
        Container(color: Colors.black.withValues(alpha: 0.3)),
        Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Select sectors where you are comfortable hosting'),
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 9,
                itemBuilder: (BuildContext ctx, int i) {
                  final bool isSelected = selectedSectors.contains(i);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedSectors.remove(i);
                        } else {
                          selectedSectors.add(i);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.orange.withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.white54,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'S${i + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildStep2Buttons(),
          ],
        ),
      ],
    );
  }

  Widget _buildStep2Buttons() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          TextButton(
            onPressed: () => setState(() => step = 1),
            child: const Text('BACK'),
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => setState(() => step = 3),
            child: const Text(
              'NEXT',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Exact address (private)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _exactAddressController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Exact address (shared only after confirmed booking)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _landmarkController,
            decoration: const InputDecoration(
              labelText: 'Landmark (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Property basics',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SegmentedButton<_PropertyType>(
            segments: const [
              ButtonSegment(
                value: _PropertyType.entireHome,
                label: Text('Entire home'),
              ),
              ButtonSegment(
                value: _PropertyType.privateRoom,
                label: Text('Private room'),
              ),
              ButtonSegment(
                value: _PropertyType.sharedRoom,
                label: Text('Shared room'),
              ),
            ],
            selected: <_PropertyType>{_propertyType},
            onSelectionChanged: (value) =>
                setState(() => _propertyType = value.first),
          ),
          const SizedBox(height: 12),
          _StepperRow(
            label: 'Max guests',
            value: _maxGuests,
            onChanged: (v) => setState(() => _maxGuests = v),
            min: 1,
            max: 20,
          ),
          _StepperRow(
            label: 'Bedrooms',
            value: _bedrooms,
            onChanged: (v) => setState(() => _bedrooms = v),
            min: 0,
            max: 20,
          ),
          _StepperRow(
            label: 'Beds',
            value: _beds,
            onChanged: (v) => setState(() => _beds = v),
            min: 1,
            max: 30,
          ),
          _StepperRow(
            label: 'Bathrooms',
            value: _bathrooms,
            onChanged: (v) => setState(() => _bathrooms = v),
            min: 0,
            max: 20,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Photos (coming next)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 6),
                Text(
                  'In the next step we will add photo upload and an AI check for genuineness.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildStep3Buttons(),
        ],
      ),
    );
  }

  Widget _buildStep3Buttons() {
    return Row(
      children: [
        TextButton(
          onPressed: () => setState(() => step = 2),
          child: const Text('BACK'),
        ),
        const Spacer(),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          onPressed: () {
            if (_exactAddressController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter the exact address')),
              );
              return;
            }
            setState(() => step = 4);
          },
          child: const Text(
            'NEXT',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'House rules',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Guests will be asked to agree to these before booking.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('No entry / exit after 9 PM'),
            value: _ruleNoLateEntryAfter9,
            onChanged: (v) => setState(() => _ruleNoLateEntryAfter9 = v),
          ),
          SwitchListTile(
            title: const Text('No smoking inside the room'),
            value: _ruleNoSmokingInside,
            onChanged: (v) => setState(() => _ruleNoSmokingInside = v),
          ),
          SwitchListTile(
            title: const Text('No cooking allowed'),
            value: _ruleNoCooking,
            onChanged: (v) => setState(() => _ruleNoCooking = v),
          ),
          SwitchListTile(
            title: const Text('No outside guests'),
            value: _ruleNoOutsideGuests,
            onChanged: (v) => setState(() => _ruleNoOutsideGuests = v),
          ),
          SwitchListTile(
            title: const Text('No pets'),
            value: _ruleNoPets,
            onChanged: (v) => setState(() => _ruleNoPets = v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _otherHouseRulesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Other house rules (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => step = 3),
                child: const Text('BACK'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => setState(() => step = 5),
                child: const Text('NEXT'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep5() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Safety & guest experience',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Only queer / allied guests'),
            value: _safetyOnlyQueerOrAllies,
            onChanged: (v) => setState(() => _safetyOnlyQueerOrAllies = v),
          ),
          SwitchListTile(
            title: const Text('No outing / discretion guaranteed'),
            value: _safetyNoOutingDiscretion,
            onChanged: (v) => setState(() => _safetyNoOutingDiscretion = v),
          ),
          SwitchListTile(
            title: const Text('24×7 building security'),
            value: _safetyBuildingSecurity24x7,
            onChanged: (v) => setState(() => _safetyBuildingSecurity24x7 = v),
          ),
          SwitchListTile(
            title: const Text('Separate entry available'),
            value: _safetySeparateEntry,
            onChanged: (v) => setState(() => _safetySeparateEntry = v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _safetyNotesController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText:
                  'Anything a queer guest should know before booking? (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => step = 4),
                child: const Text('BACK'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => setState(() => step = 6),
                child: const Text('NEXT'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep6() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Pricing & extras',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Min nightly (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max nightly (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('I offer long-stay discounts'),
            value: _longStayDiscountOffered,
            onChanged: (v) =>
                setState(() => _longStayDiscountOffered = v),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cleaningFeeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cleaning fee (₹, optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _extraGuestFeeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Extra guest fee (₹, optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _otherChargesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Other charges / notes (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => step = 5),
                child: const Text('BACK'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  final minP = int.tryParse(_minPriceController.text.trim());
                  final maxP = int.tryParse(_maxPriceController.text.trim());
                  if (minP == null || maxP == null || minP <= 0 || maxP <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter valid min and max nightly prices (₹)'),
                      ),
                    );
                    return;
                  }
                  if (minP > maxP) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Min price cannot be greater than max'),
                      ),
                    );
                    return;
                  }
                  setState(() => step = 7);
                },
                child: const Text('NEXT'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep7() {
    if (_kycBlocked) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.block, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Verification blocked',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Too many unsuccessful attempts. For the pilot, this session is blocked. '
              'A production build would record device and account signals server-side.',
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Identity verification (pilot)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Real KYC will go through regulated providers. For now we validate format only.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _aadhaarController,
            keyboardType: TextInputType.number,
            maxLength: 12,
            decoration: const InputDecoration(
              labelText: 'Aadhaar (12 digits)',
              counterText: '',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _panController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'PAN',
              hintText: 'ABCDE1234F',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Attempts: $_kycAttempts / 3',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          if (_kycVerified) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.verified, color: Colors.green),
                SizedBox(width: 8),
                Text('Format check passed (pilot mock)'),
              ],
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _kycVerified
                ? null
                : () {
                    final ok = _mockKycValid(
                      _aadhaarController.text,
                      _panController.text,
                    );
                    if (ok) {
                      setState(() {
                        _kycVerified = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Verification passed (pilot mock)'),
                        ),
                      );
                    } else {
                      setState(() {
                        _kycAttempts += 1;
                        if (_kycAttempts >= 3) {
                          _kycBlocked = true;
                        }
                      });
                      if (!_kycBlocked) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Could not verify. $_kycAttempts/3 attempts.',
                            ),
                          ),
                        );
                      }
                    }
                  },
            child: const Text('VERIFY'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => step = 6),
                child: const Text('BACK'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: !_kycVerified
                    ? null
                    : () => setState(() => step = 8),
                child: const Text('NEXT: REVIEW'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _mockKycValid(String aadhaar, String pan) {
    final a = aadhaar.replaceAll(RegExp(r'\s'), '');
    final p = pan.trim().toUpperCase();
    // Demo-friendly test pair
    if (a == '123456789012' && p == 'ABCDE1234F') {
      return true;
    }
    final aOk = RegExp(r'^\d{12}$').hasMatch(a);
    final pOk = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(p);
    return aOk && pOk;
  }

  Widget _buildStep8() {
    final areaLine = [
      _locationController.text.trim(),
      _cityController.text.trim(),
      _selectedState ?? '',
    ].where((e) => e.isNotEmpty).join(', ');

    final houseRulesSummary = [
      if (_ruleNoLateEntryAfter9) 'No entry/exit after 9 PM',
      if (_ruleNoSmokingInside) 'No smoking inside',
      if (_ruleNoCooking) 'No cooking',
      if (_ruleNoOutsideGuests) 'No outside guests',
      if (_ruleNoPets) 'No pets',
    ];
    final safetySummary = [
      if (_safetyOnlyQueerOrAllies) 'Queer/allied only',
      if (_safetyNoOutingDiscretion) 'Discretion',
      if (_safetyBuildingSecurity24x7) '24×7 security',
      if (_safetySeparateEntry) 'Separate entry',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Review & publish',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Location', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(areaLine.isEmpty ? '—' : areaLine),
                  const SizedBox(height: 8),
                  Text(
                    'Map: ${(_resolvedCenter ?? _center).latitude.toStringAsFixed(4)}, '
                    '${(_resolvedCenter ?? _center).longitude.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const Divider(height: 24),
                  const Text('Property', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('${_propertyType.name} · max guests $_maxGuests'),
                  Text('Beds $_beds · Baths $_bathrooms · Bedrooms $_bedrooms'),
                  const Divider(height: 24),
                  const Text('House rules', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    houseRulesSummary.isEmpty
                        ? '—'
                        : houseRulesSummary.join(' · '),
                  ),
                  const Divider(height: 24),
                  const Text('Safety', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    safetySummary.isEmpty ? '—' : safetySummary.join(' · '),
                  ),
                  const Divider(height: 24),
                  const Text('Pricing', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '₹${_minPriceController.text.trim()} – ${_maxPriceController.text.trim()} / night',
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(
                        _kycVerified ? Icons.verified : Icons.pending,
                        color: _kycVerified ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _kycVerified
                            ? 'Identity format verified (pilot)'
                            : 'Identity not verified',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => step = 7),
                child: const Text('BACK'),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _publishListing(status: 'draft'),
                child: const Text('Save draft'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _publishListing(status: 'published'),
                child: const Text('Confirm & publish to pilot'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _publishListing({required String status}) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await widget.hostRepository.saveHostProfile(
        userId: widget.currentUser.id,
        displayName: _nameController.text.trim(),
        areaLabel: _locationController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        state: _selectedState,
        lat: (_resolvedCenter ?? _center).latitude,
        lng: (_resolvedCenter ?? _center).longitude,
        exactAddress: _exactAddressController.text.trim(),
        landmark: _landmarkController.text.trim().isEmpty
            ? null
            : _landmarkController.text.trim(),
        propertyType: _propertyType.name,
        maxGuests: _maxGuests,
        bedrooms: _bedrooms,
        beds: _beds,
        bathrooms: _bathrooms,
        selectedSectors: List<int>.from(selectedSectors),
        ruleNoLateEntryAfter9: _ruleNoLateEntryAfter9,
        ruleNoSmokingInside: _ruleNoSmokingInside,
        ruleNoCooking: _ruleNoCooking,
        ruleNoOutsideGuests: _ruleNoOutsideGuests,
        ruleNoPets: _ruleNoPets,
        otherHouseRules: _otherHouseRulesController.text.trim().isEmpty
            ? null
            : _otherHouseRulesController.text.trim(),
        safetyOnlyQueerOrAllies: _safetyOnlyQueerOrAllies,
        safetyNoOutingDiscretion: _safetyNoOutingDiscretion,
        safetyBuildingSecurity24x7: _safetyBuildingSecurity24x7,
        safetySeparateEntry: _safetySeparateEntry,
        safetyNotesForQueerGuests: _safetyNotesController.text.trim().isEmpty
            ? null
            : _safetyNotesController.text.trim(),
        minNightlyPriceInr: int.tryParse(_minPriceController.text.trim()),
        maxNightlyPriceInr: int.tryParse(_maxPriceController.text.trim()),
        longStayDiscountOffered: _longStayDiscountOffered,
        cleaningFeeInr: int.tryParse(_cleaningFeeController.text.trim()),
        extraGuestFeeInr: int.tryParse(_extraGuestFeeController.text.trim()),
        otherChargesNote: _otherChargesController.text.trim().isEmpty
            ? null
            : _otherChargesController.text.trim(),
        kycVerifiedPilot: _kycVerified,
        kycFailedAttempts: _kycAttempts,
        kycBlockedPilot: _kycBlocked,
        kycBlockReason: _kycBlocked
            ? 'Too many failed KYC attempts (pilot)'
            : null,
        listingStatus: status,
      );

      if (!mounted) return;
      Navigator.pop(context);

      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(status == 'draft' ? 'Draft saved' : 'Published'),
          content: Text(
            status == 'draft'
                ? 'Your draft is saved. You can continue editing from the Host tab.'
                : 'Your listing has been saved to the pilot. Thank you for building ApnaaSaa Stays.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetWizard();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _resetWizard() {
    setState(() {
      step = 1;
      _nameController.clear();
      _locationController.clear();
      _cityController.clear();
      _selectedState = null;
      _exactAddressController.clear();
      _landmarkController.clear();
      selectedSectors.clear();
      _resolvedCenter = null;
      _propertyType = _PropertyType.privateRoom;
      _maxGuests = 1;
      _bedrooms = 1;
      _beds = 1;
      _bathrooms = 1;
      _ruleNoLateEntryAfter9 = false;
      _ruleNoSmokingInside = false;
      _ruleNoCooking = false;
      _ruleNoOutsideGuests = false;
      _ruleNoPets = false;
      _otherHouseRulesController.clear();
      _safetyOnlyQueerOrAllies = false;
      _safetyNoOutingDiscretion = false;
      _safetyBuildingSecurity24x7 = false;
      _safetySeparateEntry = false;
      _safetyNotesController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
      _longStayDiscountOffered = false;
      _cleaningFeeController.clear();
      _extraGuestFeeController.clear();
      _otherChargesController.clear();
      _aadhaarController.clear();
      _panController.clear();
      _kycAttempts = 0;
      _kycBlocked = false;
      _kycVerified = false;
    });
  }

  Future<void> _resolveAreaToMapCenter() async {
    final area = _locationController.text.trim();
    final city = _cityController.text.trim();
    final state = _selectedState?.trim() ?? '';

    if (area.isEmpty) {
      setState(() => _resolvedCenter = null);
      return;
    }

    final query = [
      area,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      'India',
    ].join(', ');

    setState(() {
      _isGeocoding = true;
    });

    try {
      LatLng? resolved;

      if (kIsWeb) {
        resolved = await webGeocodeAddress(query);
      }

      resolved ??= await _geocodeViaGeocodingPackage(query);
      resolved ??= await _geocodeViaGoogleMapsHttp(query);

      setState(() => _resolvedCenter = resolved);
    } finally {
      if (mounted) {
        setState(() => _isGeocoding = false);
      }
    }

    if (mounted && _resolvedCenter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not locate that area. The map will start from the default location.',
          ),
        ),
      );
    }
  }
}

Future<LatLng?> _geocodeViaGeocodingPackage(String query) async {
  try {
    final locations = await locationFromAddress(query);
    if (locations.isEmpty) return null;
    final first = locations.first;
    return LatLng(first.latitude, first.longitude);
  } catch (_) {
    return null;
  }
}

Future<LatLng?> _geocodeViaGoogleMapsHttp(String query) async {
  try {
    final apiKey = MapsConfig.googleMapsApiKey;
    if (apiKey.isEmpty) {
      return null;
    }
    // Same key as GOOGLE_MAPS_API_KEY (Geocoding API must be enabled).
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      <String, String>{
        'address': query,
        'key': apiKey,
      },
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      return null;
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final status = (json['status'] as String?) ?? '';
    if (status != 'OK') {
      return null;
    }
    final results = (json['results'] as List<dynamic>?) ?? const [];
    if (results.isEmpty) {
      return null;
    }
    final geometry = (results.first as Map<String, dynamic>)['geometry']
        as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final lat = (location?['lat'] as num?)?.toDouble();
    final lng = (location?['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) {
      return null;
    }
    return LatLng(lat, lng);
  } catch (_) {
    return null;
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            onPressed: value <= min ? null : () => onChanged(value - 1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w600)),
          IconButton(
            onPressed: value >= max ? null : () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

const List<String> _indianStatesAndUts = [
  'Andaman and Nicobar Islands',
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chandigarh',
  'Chhattisgarh',
  'Dadra and Nagar Haveli and Daman and Diu',
  'Delhi',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jammu and Kashmir',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Ladakh',
  'Lakshadweep',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Puducherry',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
];

const List<String> _majorIndianCities = [
  'Ahmedabad',
  'Bengaluru',
  'Bhopal',
  'Bhubaneswar',
  'Chandigarh',
  'Chennai',
  'Coimbatore',
  'Dehradun',
  'Delhi',
  'Gurugram',
  'Guwahati',
  'Hyderabad',
  'Indore',
  'Jaipur',
  'Jodhpur',
  'Kochi',
  'Kolkata',
  'Lucknow',
  'Mumbai',
  'Mysuru',
  'Nagpur',
  'Noida',
  'Patna',
  'Pune',
  'Raipur',
  'Ranchi',
  'Surat',
  'Thiruvananthapuram',
  'Udaipur',
  'Vadodara',
  'Varanasi',
  'Vijayawada',
  'Visakhapatnam',
];

