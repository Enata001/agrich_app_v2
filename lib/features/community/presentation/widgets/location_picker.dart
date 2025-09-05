import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';


class LocationPicker extends StatefulWidget {
  final Function(Map<String, dynamic>?) onLocationSelected;
  final Map<String, dynamic>? initialLocation;

  const LocationPicker({
    super.key,
    required this.onLocationSelected,
    this.initialLocation,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  Map<String, dynamic>? _selectedLocation;
  bool _isLoadingCurrentLocation = false;
  final TextEditingController _searchController = TextEditingController();

  // Predefined locations in Ghana
  final List<Map<String, dynamic>> _predefinedLocations = [
    {
      'name': 'Accra',
      'address': 'Accra, Greater Accra Region, Ghana',
      'latitude': 5.6037,
      'longitude': -0.1870,
    },
    {
      'name': 'Kumasi',
      'address': 'Kumasi, Ashanti Region, Ghana',
      'latitude': 6.6885,
      'longitude': -1.6244,
    },
    {
      'name': 'Tamale',
      'address': 'Tamale, Northern Region, Ghana',
      'latitude': 9.4034,
      'longitude': -0.8424,
    },
    {
      'name': 'Cape Coast',
      'address': 'Cape Coast, Central Region, Ghana',
      'latitude': 5.1053,
      'longitude': -1.2466,
    },
    {
      'name': 'Takoradi',
      'address': 'Takoradi, Western Region, Ghana',
      'latitude': 4.8845,
      'longitude': -1.7554,
    },
    {
      'name': 'Ho',
      'address': 'Ho, Volta Region, Ghana',
      'latitude': 6.6050,
      'longitude': 0.4712,
    },
    {
      'name': 'Koforidua',
      'address': 'Koforidua, Eastern Region, Ghana',
      'latitude': 6.0942,
      'longitude': -0.2560,
    },
    {
      'name': 'Sunyani',
      'address': 'Sunyani, Bono Region, Ghana',
      'latitude': 7.3395,
      'longitude': -2.3266,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Search bar
          _buildSearchBar(),

          // Current location option
          _buildCurrentLocationTile(),

          const Divider(),

          // Predefined locations
          Expanded(
            child: _buildLocationsList(),
          ),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(
            Icons.location_on,
            color: AppColors.primaryGreen,
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            'Select Location',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search for a location...',
          prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
              });
            },
            icon: const Icon(Icons.clear),
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryGreen),
          ),
        ),
        onChanged: (value) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildCurrentLocationTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.my_location,
            color: AppColors.primaryGreen,
            size: 20,
          ),
        ),
        title: const Text(
          'Use Current Location',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: const Text('Get your precise location'),
        trailing: _isLoadingCurrentLocation
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
          ),
        )
            : const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _isLoadingCurrentLocation ? null : _getCurrentLocation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildLocationsList() {
    final filteredLocations = _predefinedLocations.where((location) {
      final query = _searchController.text.toLowerCase();
      return location['name'].toString().toLowerCase().contains(query) ||
          location['address'].toString().toLowerCase().contains(query);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredLocations.length,
      itemBuilder: (context, index) {
        final location = filteredLocations[index];
        final isSelected = _selectedLocation != null &&
            _selectedLocation!['name'] == location['name'];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: isSelected ? AppColors.primaryGreen.withValues(alpha: 0.1) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? AppColors.primaryGreen
                  : Colors.grey.shade300,
            ),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGreen
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.location_city,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
            ),
            title: Text(
              location['name'],
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primaryGreen : null,
              ),
            ),
            subtitle: Text(
              location['address'],
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            trailing: isSelected
                ? const Icon(
              Icons.check_circle,
              color: AppColors.primaryGreen,
            )
                : null,
            onTap: () => _selectLocation(location),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                widget.onLocationSelected(null);
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Clear Location'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _selectedLocation != null
                  ? () {
                widget.onLocationSelected(_selectedLocation);
                Navigator.pop(context);
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Confirm Location'),
            ),
          ),
        ],
      ),
    );
  }

  void _selectLocation(Map<String, dynamic> location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingCurrentLocation = true;
    });

    try {
      final permissionResult = await LocationService.requestLocationPermission();

      switch (permissionResult) {
        case LocationPermissionResult.serviceDisabled:
          if (mounted) {
            await LocationService.showLocationServiceDialog(context);
          }
          return;
        case LocationPermissionResult.denied:
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission is required to use this feature'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        case LocationPermissionResult.deniedForever:
          if (mounted) {
            await LocationService.showLocationPermissionDialog(context);
          }
          return;
        case LocationPermissionResult.error:
          throw Exception('Failed to request location permission');
        case LocationPermissionResult.granted:
          break;
      }

      // Get current position
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // Create location data
      final currentLocation = {
        'name': 'Current Location',
        'address': 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}',
        'latitude': position.latitude,
        'longitude': position.longitude,
      };

      setState(() {
        _selectedLocation = currentLocation;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current location obtained successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get current location: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCurrentLocation = false;
        });
      }
    }
  }
}