import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  });

  final UniteUser currentUser;
  final AuthRepository authRepository;
  final HostRepository hostRepository;
  final TrustRepository trustRepository;

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
            _ => 'Step 3: Address & Property',
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
        _ => _buildStep3(),
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
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () async {
            if (_exactAddressController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter the exact address')),
              );
              return;
            }

            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) =>
                  const Center(child: CircularProgressIndicator()),
            );

            try {
              await widget.hostRepository.saveHostProfile(
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
              );

              if (!mounted) {
                return;
              }
              Navigator.pop(context);

              showDialog<void>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Saved'),
                  content: const Text(
                    'Your host details have been saved for the pilot.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
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
                        });
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            } catch (error) {
              if (!mounted) {
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $error')),
              );
            }
          },
          child: const Text(
            'FINISH SETUP',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
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
    // Note: This key is already public in web/index.html for Maps JS.
    // Must match web/index.html Maps JS key (Geocoding API must be enabled for this project).
    const apiKey = 'AIzaSyCDg5YQit-hIdcB8eShUokfYPn-KkeHjOY';
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

