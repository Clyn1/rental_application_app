import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/property_entity.dart';
import '../providers/property_provider.dart';

// This screen belongs to the LANDLORD role only.
// It is reached by tapping "Add Property" on LandlordDashboardScreen.
// A tenant never navigates here — the route exists in app.dart but
// the entry point (the FAB) only appears on the landlord's dashboard.
//
// The form uses Flutter's built-in Stepper widget to break a long
// form into 3 manageable steps:
//   Step 1 — Basic Info: title, description, price, type, address
//   Step 2 — Details: bedrooms, bathrooms, square footage, amenities
//   Step 3 — Review: summary of everything before submitting
class AddPropertyScreen extends ConsumerStatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  ConsumerState<AddPropertyScreen> createState() =>
      _AddPropertyScreenState();
}

class _AddPropertyScreenState extends ConsumerState<AddPropertyScreen> {
  int _currentStep = 0;

  // Separate form keys per step so validation only checks the
  // fields visible on the CURRENT step, not the entire form.
  // This means a user on Step 2 won't see Step 1 errors they
  // already fixed, and won't be blocked by Step 3 fields they
  // haven't filled in yet.
  final _step0Key = GlobalKey<FormState>();
  final _step1Key = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _sqftController = TextEditingController();

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

  void _handleStepContinue() {
    // Validate only the current step's form before advancing.
    final isValid = _currentStep == 0
        ? _step0Key.currentState!.validate()
        : _currentStep == 1
            ? _step1Key.currentState!.validate()
            : true; // Step 2 (Review) has no fields to validate

    if (!isValid) return;

    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _handleSubmit();
    }
  }

  void _handleStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      // On step 0, "Cancel" goes back to the previous screen
      // (the Landlord Dashboard).
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleSubmit() async {
    final form = ref.read(propertyFormProvider);

    // Location check — both address and city must be set.
    // This can't be in the Form validator because it's stored
    // in the Riverpod provider, not a TextEditingController.
    if (form.location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid address and city.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Tell the submit provider to save everything to Firestore.
    // The provider reads the current form state from
    // propertyFormProvider and handles the Firebase write.
    await ref.read(propertyFormSubmitProvider.notifier).submit();

    if (!mounted) return;

    final submitState = ref.read(propertyFormSubmitProvider);
    submitState.whenOrNull(
      data: (_) {
        // Success — navigate back to the dashboard and confirm.
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Property submitted for review! '
              'It will appear once approved by an admin.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      },
      error: (error, _) {
        // WHY failureMessage() HERE INSTEAD OF error.toString():
        // error.toString() on a ValidationFailure just prints
        // "Instance of 'ValidationFailure'" — completely useless
        // to the user. failureMessage() checks if the error is
        // one of our Failure types and returns its .message field
        // instead, which is the human-readable string we wrote
        // (e.g. "Please add at least one photo of the property.")
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failureMessage(error)),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed:
                      isLoading ? null : details.onStepContinue,
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
                  onPressed:
                      isLoading ? null : details.onStepCancel,
                  child: Text(
                    _currentStep == 0 ? 'Cancel' : 'Back',
                  ),
                ),
              ],
            ),
          );
        },
        steps: [
          _buildStep0(),
          _buildStep1(),
          _buildStep2(),
        ],
      ),
    );
  }

  // ── STEP 1: BASIC INFO ─────────────────────────────────────
  Step _buildStep0() {
    return Step(
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
            // TITLE
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration(
                'Property Title',
                'e.g. Modern 2-Bedroom in Nyali',
                Icons.title,
              ),
              onChanged: (v) => ref
                  .read(propertyFormProvider.notifier)
                  .setTitle(v),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // DESCRIPTION
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: _inputDecoration(
                'Description',
                'Describe the property in detail...',
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

            // PRICE
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
                if (v == null || v.isEmpty) {
                  return 'Enter a price';
                }
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

            // PROPERTY TYPE DROPDOWN
            _PropertyTypeDropdown(),
            const SizedBox(height: 16),

            // ADDRESS
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

            // CITY
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
    );
  }

  // ── STEP 2: DETAILS ────────────────────────────────────────
  Step _buildStep1() {
    return Step(
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
            Row(
              children: [
                Expanded(
                  child: _RoomCounter(
                    label: 'Bedrooms',
                    isBedroom: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _RoomCounter(
                    label: 'Bathrooms',
                    isBedroom: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // SQUARE FOOTAGE (optional — no validator)
            TextFormField(
              controller: _sqftController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(
                'Square Footage (optional)',
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

            Text(
              'Amenities',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap each one this property offers:',
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
    );
  }

  // ── STEP 3: REVIEW ─────────────────────────────────────────
  Step _buildStep2() {
    return Step(
      title: const Text('Review'),
      subtitle: const Text('Confirm and submit'),
      isActive: _currentStep >= 2,
      state: StepState.indexed,
      content: Column(
        children: [
          // WHY SHOW A NOTE ABOUT IMAGES HERE:
          // We haven't built the image picker yet.
          // This banner makes it clear to the landlord
          // that photos can be added later, so they
          // don't think their listing is broken without them.
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              border: Border.all(
                color: Colors.blue.withOpacity(0.4),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.blue, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Photo upload is coming soon. '
                    'You can submit your listing now and '
                    'add photos later.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          _ReviewSummary(),

          const SizedBox(height: 12),

          // Admin moderation notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              border: Border.all(
                color: Colors.amber.withOpacity(0.4),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_user_outlined,
                    color: Colors.amber, size: 18),
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
      ),
    );
  }

  void _updateLocation() {
    if (_addressController.text.isNotEmpty &&
        _cityController.text.isNotEmpty) {
      ref.read(propertyFormProvider.notifier).setLocation(
            PropertyLocation(
              address: _addressController.text.trim(),
              city: _cityController.text.trim(),
              // Placeholder coordinates — real implementation
              // would use Google Maps geocoding API to convert
              // the typed address into actual lat/lng values.
              latitude: 0,
              longitude: 0,
            ),
          );
    }
  }

  InputDecoration _inputDecoration(
    String label,
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
    );
  }
}

// ── PROPERTY TYPE DROPDOWN ──────────────────────────────────
class _PropertyTypeDropdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(propertyFormProvider);

    return DropdownButtonFormField<PropertyType>(
      value: form.propertyType,
      decoration: InputDecoration(
        labelText: 'Property Type',
        prefixIcon: const Icon(Icons.home_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      items: PropertyType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(
            type.name[0].toUpperCase() + type.name.substring(1),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          ref
              .read(propertyFormProvider.notifier)
              .setPropertyType(value);
        }
      },
    );
  }
}

// ── ROOM COUNTER ────────────────────────────────────────────
// Increment/decrement buttons for bedrooms and bathrooms.
// WHY NOT JUST A TEXT FIELD:
// A text field could accept invalid values like -5 or 999.
// A counter with min/max bounds (0 minimum here) makes it
// impossible to enter a nonsensical value, so we never need
// to validate this field at all.
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
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
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

// ── AMENITIES GRID ──────────────────────────────────────────
// Tappable chips for selecting what the property offers.
// WHY FilterChip INSTEAD OF CHECKBOXES:
// Chips use less vertical space and are easier to tap on
// a phone screen. The landlord can see all options at once
// and toggle them on/off quickly.
class _AmenitiesGrid extends ConsumerWidget {
  final List<String> allAmenities;

  const _AmenitiesGrid({required this.allAmenities});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAmenities =
        ref.watch(propertyFormProvider).amenities;

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

// ── REVIEW SUMMARY ──────────────────────────────────────────
// Shows everything the landlord entered before they commit
// to submitting. This is important because once submitted,
// the listing goes to admin review and they can't easily
// pull it back. A clear summary prevents mistakes.
class _ReviewSummary extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(propertyFormProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _reviewRow(context, 'Title', form.title),
        _reviewRow(context, 'Description',
            form.description.isEmpty ? 'Not set' : form.description),
        _reviewRow(context, 'Price',
            'KES ${form.price?.toStringAsFixed(0) ?? '0'}/month'),
        _reviewRow(
          context,
          'Type',
          form.propertyType.name[0].toUpperCase() +
              form.propertyType.name.substring(1),
        ),
        _reviewRow(context, 'Bedrooms', '${form.bedrooms}'),
        _reviewRow(context, 'Bathrooms', '${form.bathrooms}'),
        _reviewRow(
          context,
          'Address',
          form.location?.address ?? 'Not set',
        ),
        _reviewRow(
          context,
          'City',
          form.location?.city ?? 'Not set',
        ),
        if (form.amenities.isNotEmpty)
          _reviewRow(context, 'Amenities', form.amenities.join(', ')),
      ],
    );
  }

  Widget _reviewRow(BuildContext context, String label, String value) {
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
