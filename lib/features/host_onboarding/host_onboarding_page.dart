import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:unite_india_app/core/domain/user.dart';
import 'package:unite_india_app/core/domain/verification_status.dart';
import 'package:unite_india_app/core/repositories/auth_repository.dart';
import 'package:unite_india_app/core/repositories/host_repository.dart';
import 'package:unite_india_app/core/repositories/trust_repository.dart';

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

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          step == 1 ? 'Step 1: Host Details' : 'Step 2: Map Sectors',
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
      body: step == 1 ? _buildStep1() : _buildStep2(),
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Area / Neighborhood',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() => _locationController.text = 'Detecting...');
                  debugPrint('GPS Locate Triggered');
                },
                icon: const Icon(
                  Icons.my_location,
                  color: Colors.orange,
                  size: 30,
                ),
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              backgroundColor: Colors.orange,
            ),
            onPressed: () {
              if (_nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please share a name the community can see'),
                  ),
                );
                return;
              }
              setState(() => step = 2);
            },
            child: const Text(
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
          initialCameraPosition: CameraPosition(target: _center, zoom: 14.0),
          onMapCreated: (GoogleMapController controller) {
            mapController = controller;
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
            _buildBottomButtons(),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
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
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
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
                  selectedSectors: List<int>.from(selectedSectors),
                );

                if (!mounted) {
                  return;
                }
                Navigator.pop(context);

                showDialog<void>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text('Thank you'),
                    content: const Text(
                      'Your willingness to host has been recorded for Unite India.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            step = 1;
                            _nameController.clear();
                            _locationController.clear();
                            selectedSectors.clear();
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
      ),
    );
  }
}

