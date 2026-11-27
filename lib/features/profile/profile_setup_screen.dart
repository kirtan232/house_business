import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/validators.dart';
import '../../core/widgets/auth_form_layout.dart';
import '../../data/auth_repository.dart';
import '../../data/user_repository.dart';
import '../../models/app_user.dart';

// Screen 3. Pick buyer or seller, add name, photo, and phone.
// When the save works, the router sees the new profile and opens the app.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  UserRole? _role;
  Uint8List? _photo;
  bool _loading = false;
  bool _roleMissing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Google users already have a name, so fill it in for them.
    _name.text = ref.read(authRepositoryProvider).currentUser?.displayName ?? '';
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        imageQuality: 80,
      );
      if (file == null) return; // closed the picker
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _photo = bytes);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not open your photos. Check the app permissions.');
    }
  }

  Future<void> _save() async {
    if (_loading) return;
    final formOk = _formKey.currentState!.validate();
    setState(() => _roleMissing = _role == null);
    if (!formOk || _role == null) return;

    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final phone = _phone.text.trim();
      await ref.read(userRepositoryProvider).createProfile(
            uid: user.uid,
            name: _name.text.trim(),
            role: _role!,
            email: user.email,
            phone: phone.isEmpty ? null : phone,
            photo: _photo,
          );
    } on ProfileFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set up your profile'),
        actions: [
          TextButton(
            onPressed: _loading ? null : () => ref.read(authRepositoryProvider).signOut(),
            child: const Text('Log out'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _loading ? null : _pickPhoto,
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage: _photo == null ? null : MemoryImage(_photo!),
                        child: _photo == null ? const Icon(Icons.add_a_photo_outlined, size: 32) : null,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _loading ? null : _pickPhoto,
                    child: Text(_photo == null ? 'Add a photo (optional)' : 'Change photo'),
                  ),
                  const SizedBox(height: 16),
                  Text('I want to', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<UserRole>(
                    emptySelectionAllowed: true,
                    selected: {?_role},
                    onSelectionChanged: _loading
                        ? null
                        : (s) => setState(() {
                              _role = s.isEmpty ? null : s.first;
                              _roleMissing = false;
                            }),
                    segments: const [
                      ButtonSegment(
                        value: UserRole.buyer,
                        icon: Icon(Icons.search),
                        label: Text('Buy a home'),
                      ),
                      ButtonSegment(
                        value: UserRole.seller,
                        icon: Icon(Icons.sell_outlined),
                        label: Text('Sell a home'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _roleMissing ? 'Pick buyer or seller.' : "You can't change this later.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _roleMissing ? theme.colorScheme.error : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Your name'),
                    validator: validateName,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Phone (optional)',
                      helperText: 'Only you can see this. Buyers and sellers talk in the app chat.',
                      helperMaxLines: 2,
                    ),
                    validator: validatePhone,
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 12),
                  ],
                  LoadingButton(label: 'Save and continue', loading: _loading, onPressed: _save),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
