import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

const List<String> kIndiaStates = [
  'Andhra Pradesh',
  'Arunachal Pradesh',
  'Assam',
  'Bihar',
  'Chhattisgarh',
  'Goa',
  'Gujarat',
  'Haryana',
  'Himachal Pradesh',
  'Jharkhand',
  'Karnataka',
  'Kerala',
  'Madhya Pradesh',
  'Maharashtra',
  'Manipur',
  'Meghalaya',
  'Mizoram',
  'Nagaland',
  'Odisha',
  'Punjab',
  'Rajasthan',
  'Sikkim',
  'Tamil Nadu',
  'Telangana',
  'Tripura',
  'Uttar Pradesh',
  'Uttarakhand',
  'West Bengal',
  'Andaman and Nicobar Islands',
  'Chandigarh',
  'Dadra and Nagar Haveli and Daman and Diu',
  'Delhi',
  'Jammu and Kashmir',
  'Ladakh',
  'Lakshadweep',
  'Puducherry',
];

const String kCurrentLocationAddressId = 'current-location-address';

Future<void> showAddressPickerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _AddressPickerSheet(parentContext: context),
  );
}

class _AddressPickerSheet extends StatefulWidget {
  const _AddressPickerSheet({required this.parentContext});

  final BuildContext parentContext;

  @override
  State<_AddressPickerSheet> createState() => _AddressPickerSheetState();
}

class _AddressPickerSheetState extends State<_AddressPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _usingCurrentLocation = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    if (_usingCurrentLocation) return;

    setState(() => _usingCurrentLocation = true);
    final auth = context.read<AuthProvider>();
    final customer = auth.customer;
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw Exception('Location service is turned off.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final placemark = placemarks.isNotEmpty ? placemarks.first : null;
      if (placemark == null) {
        throw Exception('Unable to resolve your current address.');
      }

      final addressLine = [
        placemark.name,
        placemark.subLocality,
        placemark.locality,
        placemark.subAdministrativeArea,
      ].whereType<String>().map((value) => value.trim()).where((value) => value.isNotEmpty).toList();

      await auth.upsertSavedAddress({
        'id': kCurrentLocationAddressId,
        'label': 'Current',
        'name': (customer?['name'] ?? '').toString().trim(),
        'phone': (customer?['phone'] ?? '').toString().trim(),
        'address': addressLine.join(', '),
        'state': (placemark.administrativeArea ?? '').trim(),
        'pinCode': (placemark.postalCode ?? '').trim(),
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _usingCurrentLocation = false);
      }
    }
  }

  Future<void> _openEditor([Map<String, dynamic>? address]) async {
    Navigator.pop(context);
    await showAddressEditorSheet(widget.parentContext, address: address);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final selectedAddressId = auth.selectedAddress?['id']?.toString();
    final query = _searchCtrl.text.trim().toLowerCase();
    final addresses = auth.savedAddresses.where((address) {
      if (query.isEmpty) return true;
      final haystack = [
        address['label'],
        address['name'],
        address['phone'],
        address['address'],
        address['state'],
        address['pinCode'],
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList()
      ..sort((left, right) {
        final leftId = left['id']?.toString();
        final rightId = right['id']?.toString();
        final leftSelected = leftId == selectedAddressId;
        final rightSelected = rightId == selectedAddressId;

        if (leftSelected != rightSelected) {
          return leftSelected ? -1 : 1;
        }

        final leftCurrent = (left['label'] ?? '').toString() == 'Current';
        final rightCurrent = (right['label'] ?? '').toString() == 'Current';
        if (leftCurrent != rightCurrent) {
          return leftCurrent ? -1 : 1;
        }

        return 0;
      });

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 0,
          right: 0,
          top: 80,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Material(
          color: const Color(0xFFF5F5F7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4D4D8),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  children: [
                    const Text(
                      'Select delivery location',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF262626),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search for area, street name...',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.search_rounded),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _actionTile(
                      icon: Icons.my_location_rounded,
                      iconColor: const Color(0xFF0C831F),
                      title: 'Use current location',
                      subtitle: _usingCurrentLocation
                          ? 'Resolving your live location...'
                          : 'Detect and use your live location',
                      onTap: _useCurrentLocation,
                    ),
                    const SizedBox(height: 10),
                    _actionTile(
                      icon: Icons.add_rounded,
                      iconColor: const Color(0xFF0C831F),
                      title: 'Add new address',
                      subtitle: 'Save a home, work, or other address',
                      onTap: _openEditor,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Your saved addresses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (addresses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Text(
                          'No saved address yet. Add one to speed up checkout.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    for (final address in addresses) ...[
                      _SavedAddressCard(
                        address: address,
                        selected:
                            auth.selectedAddress?['id'] == address['id'],
                        onSelect: () async {
                          final navigator = Navigator.of(context);
                          await auth.selectSavedAddress(
                            address['id'].toString(),
                          );
                          if (!mounted) return;
                          navigator.pop();
                        },
                        onEdit: () => _openEditor(address),
                        onDelete: () async {
                          await auth.deleteSavedAddress(
                            address['id'].toString(),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(24),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFA1A1AA),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showAddressEditorSheet(
  BuildContext context, {
  Map<String, dynamic>? address,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AddressEditorSheet(address: address),
  );
}

class _AddressEditorSheet extends StatefulWidget {
  const _AddressEditorSheet({this.address});

  final Map<String, dynamic>? address;

  @override
  State<_AddressEditorSheet> createState() => _AddressEditorSheetState();
}

class _AddressEditorSheetState extends State<_AddressEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _pinCtrl;
  late String _label;
  String? _state;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final seed = widget.address ?? const <String, dynamic>{};

    _nameCtrl = TextEditingController(
      text: (seed['name'] ?? '').toString().trim(),
    );
    _phoneCtrl = TextEditingController(
      text: (seed['phone'] ?? '').toString().trim(),
    );
    _addressCtrl = TextEditingController(
      text: (seed['address'] ?? '').toString().trim(),
    );
    _pinCtrl = TextEditingController(
      text: (seed['pinCode'] ?? '').toString().trim(),
    );
    _label = (seed['label'] ?? 'Home').toString().trim().isEmpty
      ? 'Home'
      : (seed['label'] ?? 'Home').toString().trim();
    final initialState = (seed['state'] ?? '').toString().trim();
    _state = kIndiaStates.contains(initialState) ? initialState : null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    await auth.upsertSavedAddress({
      'id': widget.address?['id'],
      'label': _label,
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'state': _state,
      'pinCode': _pinCtrl.text.trim(),
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.address == null ? 'Add address' : 'Edit address';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          top: 80,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4D4D8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _label,
                    items: const [
                      DropdownMenuItem(value: 'Home', child: Text('Home')),
                      DropdownMenuItem(value: 'Work', child: Text('Work')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    decoration: _inputDecoration(
                      'Address Type',
                      Icons.bookmark_outline_rounded,
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _label = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _textField(
                    controller: _nameCtrl,
                    label: 'Full Name',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  _textField(
                    controller: _phoneCtrl,
                    label: 'Phone Number',
                    icon: Icons.call_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      final phone = value?.trim() ?? '';
                      if (phone.isEmpty) return 'Enter Phone Number';
                      if (phone.length < 10) return 'Enter valid phone number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _state,
                    isExpanded: true,
                    decoration: _inputDecoration(
                      'State',
                      Icons.map_outlined,
                    ),
                    items: kIndiaStates
                        .map(
                          (state) => DropdownMenuItem<String>(
                            value: state,
                            child: Text(state, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _state = value),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Select State' : null,
                  ),
                  const SizedBox(height: 12),
                  _textField(
                    controller: _pinCtrl,
                    label: 'Pin Code',
                    icon: Icons.pin_drop_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final pin = value?.trim() ?? '';
                      if (pin.isEmpty) return 'Enter Pin Code';
                      if (pin.length != 6) return 'Enter 6-digit pin';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _textField(
                    controller: _addressCtrl,
                    label: 'Full Address',
                    icon: Icons.location_on_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0C831F),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(widget.address == null ? 'Save Address' : 'Update Address'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: _inputDecoration(label, icon),
      validator: validator ??
          (value) => value == null || value.trim().isEmpty
              ? 'Enter $label'
              : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _SavedAddressCard extends StatelessWidget {
  const _SavedAddressCard({
    required this.address,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> address;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final label = (address['label'] ?? 'Home').toString();
    final fullAddress = [
      (address['address'] ?? '').toString().trim(),
      (address['state'] ?? '').toString().trim(),
      (address['pinCode'] ?? '').toString().trim(),
    ].where((value) => value.isNotEmpty).join(', ');
    final phone = (address['phone'] ?? '').toString().trim();

    return Material(
      color: selected ? const Color(0xFFF2FBF4) : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFF0C831F) : const Color(0xFFEAEAEA),
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0C831F).withAlpha(18),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFDFF6E3)
                      : const Color(0xFFFFF5CC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  label == 'Work' ? Icons.business_rounded : Icons.home_rounded,
                  color: selected
                      ? const Color(0xFF0C831F)
                      : const Color(0xFF805B00),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF262626),
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0C831F),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Selected',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (fullAddress.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        fullAddress,
                        style: const TextStyle(
                          height: 1.4,
                          fontSize: 14,
                          color: Color(0xFF52525B),
                        ),
                      ),
                    ],
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Phone number: $phone',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF52525B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                    return;
                  }
                  onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.more_horiz_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}