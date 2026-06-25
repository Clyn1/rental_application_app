import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/property_entity.dart';
import '../providers/property_provider.dart';

// WHY THIS SCREEN EXISTS:
// This is the screen a landlord uses to list a new property.
// It is a multi-step form broken into 3 simple steps:
//   Step 1 - Basic info (title, description, price, type)
//   Step 2 - Details (bedrooms, bathrooms, amenities)
//   Step 3 - Review and submit
//
// WHY MULTI-STEP?
// A single long form feels overwhelming. Breaking it into
// steps with a progress indicator makes the task feel
// manageable. Each step validates its own fields before
// allowing the user to proceed to the next one.
class AddPropertyScreen extends ConsumerStatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  ConsumerState<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends ConsumerState<AddPropertyScreen> {
  // Tracks which step (0, 1, or 2) the user is currently on.
  int _currentStep = 0;

  // Form keys - one per step so we only validate the
  // fields visible on the current step, not all fields at once.
  final _step0Key = GlobalKey<FormState>();
  final _step1Key = GlobalKey<FormState>();

  // Text controllers for fields that need free typing.
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _sqftController = TextEditingController();

  // Available amenities to pick from.
  final List<String> _allAmenities = [
    'WiFi', 'Parking', 'Swimming Pool', 'Security',
    'Gym', 'Generator', 'Water 24/7', 'CCTV',
    'Garden', 'Elevator', 'Furnished', 'Air Conditioning',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _sqftController.dispose();
    super.dispose();
  }

  // Called when user taps "Next" or "Submit".
  void _handleStepContinue() {
    // Validate whichever step's form is currently active.
    final isValid = _currentStep == 0
        ? _step0Key.currentState!.validate()
        : _currentStep == 1
            ? _step1Key.currentState!.validate()
            : true;

    if (!isValid) return;

    if (_currentStep < 2) {
      // Move to the next step.
      setState(() => _currentStep++);
    } else {
      // Final step - submit the form.
      _handleSubmit();
    }
  }

  void _handleStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleSubmit() async {
    final form = ref.read(propertyFormProvider);

    // Quick sanity check before calling Firebase.
    if (form.location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid address and city.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await ref.read(propertyFormSubmitProvider.notifier).submit();

    if (!mounted) return;

    final submitState = ref.read(propertyFormSubmitProvider);
    submitState.whenOrNull(
      data: (_) {
        // Success - go back and show a confirmation message.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Property submitted for review! '
                'It will appear once approved by an admin.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop();
      },
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the submit state so the button shows a spinner
    // while Firebase is saving.
    final submitState = ref.watch(propertyFormSubmitProvider);
    final isLoading = submitState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Property'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: isLoading ? null : _handleStepContinue,
        onStepCancel: isLoading ? null : _handleStepCancel,
        controlsBuilder: (context, details) {
          // Custom buttons so we can show a spinner on the
          // last step while submitting.
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: isLoading ? null : details.onStepContinue,
                  child: isLoading && _currentStep == 2
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_currentStep == 2 ? 'Submit' : 'Next'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: isLoading ? null : details.onStepCancel,
                  child: Text(_currentStep == 0 ? 'Cancel' : 'Back'),
                ),
              ],
            ),
          );
        },
        steps: [
          // ─────────────────────────────────────────
          // STEP 1: Basic Information
          // ─────────────────────────────────────────
          Step(
            title: const Text('Basic Info'),
            subtitle: const Text('Title, price and type'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0
                ? StepState.complete
                : StepState.indexed,
            content: Form(
              key: _step0Key,
              child: Column(
                children: [
                  // Title field
                  TextFormField(
                    controller: _titleController,
                    decoration: _inputDecoration(
                      'Property Title',
                      'e.g. Modern 2-Bedroom in Nyali',
                      Icons.title,
                    ),
                    onChanged: (v) =>
                        ref.read(propertyFormProvider.notifier).setTitle(v),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description field
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: _inputDecoration(
                      'Description',
                      'Describe the property...',
                      Icons.description_outlined,
                    ),
                    onChanged: (v) => ref
                        .read(propertyFormProvider.notifier)
                        .setDescription(v),
                    validator: (v) {
                      if (v == null || v.trim().length < 20) {
                        return 'Please write at least 20 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Price field
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      'Monthly Rent (KES)',
                      'e.g. 45000',
                      Icons.payments_outlined,
                    ),
                    onChanged: (v) {
                      final price = double.tryParse(v);
                      if (price != null) {
                        ref
                            .read(propertyFormProvider.notifier)
                            .setPrice(price);
                      }
                    },
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter a price';
                      if (double.tryParse(v) == null) {
                        return 'Enter a valid number';
                      }
                      if (double.parse(v) <= 0) {
                        return 'Price must be greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Property type dropdown
                  _PropertyTypeDropdown(),
                  const SizedBox(height: 16),

                  // Address fields
                  TextFormField(
                    controller: _addressController,
                    decoration: _inputDecoration(
                      'Street Address',
                      'e.g. Nyali Road, Plot 45',
                      Icons.location_on_outlined,
                    ),
                    onChanged: (_) => _updateLocation(),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter the address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _cityController,
                    decoration: _inputDecoration(
                      'City',
                      'e.g. Mombasa',
                      Icons.location_city_outlined,
                    ),
                    onChanged: (_) => _updateLocation(),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter the city';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),

          // ─────────────────────────────────────────
          // STEP 2: Property Details
          // ─────────────────────────────────────────
          Step(
            title: const Text('Details'),
            subtitle: const Text('Rooms and amenities'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1
                ? StepState.complete
                : StepState.indexed,
            content: Form(
              key: _step1Key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bedrooms and bathrooms side by side
                  Row(
                    children: [
                      Expanded(child: _RoomCounter(label: 'Bedrooms', isBedroom: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _RoomCounter(label: 'Bathrooms', isBedroom: false)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Square footage
                  TextFormField(
                    controller: _sqftController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      'Square Footage',
                      'e.g. 950',
                      Icons.square_foot_outlined,
                    ),
                    onChanged: (v) {
                      final sqft = double.tryParse(v);
                      if (sqft != null) {
                        ref
                            .read(propertyFormProvider.notifier)
                            .setSquareFootage(sqft);
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Amenities
                  Text(
                    'Amenities',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to select what this property offers:',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  _AmenitiesGrid(allAmenities: _allAmenities),
                ],
              ),
            ),
          ),

          // ─────────────────────────────────────────
          // STEP 3: Review & Submit
          // ─────────────────────────────────────────
          Step(
            title: const Text('Review'),
            subtitle: const Text('Confirm and submit'),
            isActive: _currentStep >= 2,
            state: StepState.indexed,
            content: _ReviewSummary(),
          ),
        ],
      ),
    );
  }

  // Updates the location in the form provider whenever
  // address or city fields change. We use placeholder
  // lat/lng of 0,0 for now — in a real build this would
  // use the Google Maps geocoding API to convert the
  // typed address into real coordinates automatically.
  void _updateLocation() {
    if (_addressController.text.isNotEmpty &&
        _cityController.text.isNotEmpty) {
      ref.read(propertyFormProvider.notifier).setLocation(
            PropertyLocation(
              address: _addressController.text.trim(),
              city: _cityController.text.trim(),
              latitude: 0,
              longitude: 0,
            ),
          );
    }
  }

  // Reusable input decoration so all fields look consistent.
  InputDecoration _inputDecoration(
      String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
    );
  }
}

// ─────────────────────────────────────────────────────
// SMALL SUB-WIDGETS
// These are defined below the main screen class.
// WHY SEPARATE WIDGETS INSTEAD OF METHODS?
// Flutter recommends building small reusable widgets rather
// than helper methods that return Widget. This gives better
// performance (Flutter can skip rebuilding a sub-widget if
// its inputs haven't changed) and makes each piece easier
// to read and reason about independently.
// ─────────────────────────────────────────────────────

class _PropertyTypeDropdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(propertyFormProvider);

    return DropdownButtonFormField<PropertyType>(
      value: form.propertyType,
      decoration: InputDecoration(
        labelText: 'Property Type',
        prefixIcon: const Icon(Icons.home_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      items: PropertyType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          // .name gives us "apartment", .split + capitalize gives "Apartment"
          child: Text(
            type.name[0].toUpperCase() + type.name.substring(1),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          ref.read(propertyFormProvider.notifier).setPropertyType(value);
        }
      },
    );
  }
}

class _RoomCounter extends ConsumerWidget {
  final String label;
  final bool isBedroom;

  const _RoomCounter({required this.label, required this.isBedroom});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(propertyFormProvider);
    final count = isBedroom ? form.bedrooms : form.bathrooms;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: count > 0
                    ? () {
                        isBedroom
                            ? ref
                                .read(propertyFormProvider.notifier)
                                .setBedrooms(count - 1)
                            : ref
                                .read(propertyFormProvider.notifier)
                                .setBathrooms(count - 1);
                      }
                    : null,
              ),
              Text(
                '$count',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  isBedroom
                      ? ref
                          .read(propertyFormProvider.notifier)
                          .setBedrooms(count + 1)
                      : ref
                          .read(propertyFormProvider.notifier)
                          .setBathrooms(count + 1);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmenitiesGrid extends ConsumerWidget {
  final List<String> allAmenities;

  const _AmenitiesGrid({required this.allAmenities});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAmenities = ref.watch(propertyFormProvider).amenities;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allAmenities.map((amenity) {
        final isSelected = selectedAmenities.contains(amenity);
        return FilterChip(
          label: Text(amenity),
          selected: isSelected,
          onSelected: (_) {
            ref
                .read(propertyFormProvider.notifier)
                .toggleAmenity(amenity);
          },
        );
      }).toList(),
    );
  }
}

class _ReviewSummary extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(propertyFormProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _reviewRow('Title', form.title),
        _reviewRow('Price', 'KES ${form.price ?? 0}/month'),
        _reviewRow('Type',
            form.propertyType.name[0].toUpperCase() +
                form.propertyType.name.substring(1)),
        _reviewRow('Bedrooms', '${form.bedrooms}'),
        _reviewRow('Bathrooms', '${form.bathrooms}'),
        _reviewRow('Address', form.location?.address ?? 'Not set'),
        _reviewRow('City', form.location?.city ?? 'Not set'),
        if (form.amenities.isNotEmpty)
          _reviewRow('Amenities', form.amenities.join(', ')),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            border: Border.all(color: Colors.amber),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your listing will be reviewed by an admin '
                  'before appearing publicly.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
