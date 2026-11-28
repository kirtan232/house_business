import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/validators.dart';
import '../../data/auth_repository.dart';
import '../../data/geocoder.dart';
import '../../data/listing_repository.dart';
import '../../data/photo_repository.dart';
import '../../data/user_repository.dart';
import '../../models/listing.dart';

// A photo on the form. It has a url once it's uploaded, and picked bytes if it's new.
class _FormPhoto {
  _FormPhoto.saved(String this.url) : picked = null;
  _FormPhoto.picked(PickedPhoto this.picked);

  String? url;
  final PickedPhoto? picked;
}

// Screen 13. Create a new listing, or edit one when listingId is given.
// Viewing time slots get added to this screen in the next step.
class ListingFormScreen extends ConsumerStatefulWidget {
  const ListingFormScreen({super.key, this.listingId});

  final String? listingId;

  @override
  ConsumerState<ListingFormScreen> createState() => _ListingFormScreenState();
}

class _ListingFormScreenState extends ConsumerState<ListingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _beds = TextEditingController();
  final _baths = TextEditingController();
  final _sqft = TextEditingController();
  final _year = TextEditingController();
  final _lot = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _zip = TextEditingController();
  final _description = TextEditingController();
  HomeType _type = HomeType.house;
  final Set<String> _amenities = {};
  final List<_FormPhoto> _photos = []; // first one is the cover
  final List<String> _removedUrls = []; // deleted from Storage after the save works

  Listing? _original; // the saved version when editing
  late final String _newId; // made once, so trying again doesn't make a second listing
  bool _loading = false;
  String? _loadError;
  bool _saving = false;
  String? _progress; // "Uploading photo 2 of 5..."
  bool _changed = false;
  String? _error;

  bool get _editing => widget.listingId != null;

  @override
  void initState() {
    super.initState();
    _newId = ref.read(listingRepositoryProvider).newListingId();
    if (_editing) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final listing = await ref.read(listingRepositoryProvider).getListing(widget.listingId!);
      final uid = ref.read(authRepositoryProvider).currentUser?.uid;
      if (!mounted) return;
      if (listing == null) {
        _loadError = "This listing doesn't exist, or it isn't yours.";
      } else if (listing.sellerId != uid) {
        _loadError = 'You can only edit your own listings.';
      } else {
        _fill(listing);
      }
    } on ListingFailure catch (e) {
      _loadError = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fill(Listing l) {
    _original = l;
    _title.text = l.title;
    _price.text = l.price.toString();
    _beds.text = l.beds.toString();
    _baths.text = _numText(l.baths);
    _sqft.text = l.sqft?.toString() ?? '';
    _year.text = l.yearBuilt?.toString() ?? '';
    _lot.text = l.lotSize == null ? '' : _numText(l.lotSize!);
    _address.text = l.address ?? '';
    _city.text = l.city;
    _zip.text = l.zip;
    _description.text = l.description ?? '';
    _type = l.type;
    _amenities.addAll(l.amenities);
    _photos.addAll(l.photos.map(_FormPhoto.saved));
  }

  // 2.0 shows as "2", 2.5 stays "2.5".
  String _numText(double n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString();

  String? _optional(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  String get _listingId => _original?.id ?? _newId;

  Listing _buildListing(ListingStatus status, String sellerId, List<String> photoUrls) {
    final original = _original;
    return Listing(
      id: _listingId,
      sellerId: sellerId,
      status: status,
      title: _title.text.trim(),
      description: _optional(_description),
      price: parsePrice(_price.text)!,
      type: _type,
      beds: int.parse(_beds.text.trim()),
      baths: double.parse(_baths.text.trim()),
      sqft: int.tryParse(_sqft.text.replaceAll(',', '').trim()),
      yearBuilt: int.tryParse(_year.text.trim()),
      lotSize: double.tryParse(_lot.text.trim()),
      address: _optional(_address),
      city: _city.text.trim(),
      zip: _zip.text.trim(),
      location: original?.location,
      amenities: amenityOptions.where(_amenities.contains).toList(),
      photos: photoUrls,
      createdAt: original?.createdAt,
    );
  }

  // ---------- photos ----------

  Future<void> _pickPhotos() async {
    final room = maxListingPhotos - _photos.length;
    if (room <= 0) return;
    try {
      final picked = await ref.read(photoPickerProvider).pickMany(limit: room);
      if (!mounted || picked.isEmpty) return; // closed the picker
      final small = picked.where((p) => p.bytes.length < maxPhotoBytes).toList();
      final tooBig = picked.length - small.length;
      final added = small.take(room).toList();
      final overLimit = small.length - added.length;
      setState(() {
        _photos.addAll(added.map(_FormPhoto.picked));
        _changed = true;
      });
      final notes = [
        if (tooBig > 0) '$tooBig ${tooBig == 1 ? 'photo was' : 'photos were'} over 5 MB and skipped.',
        if (overLimit > 0) 'You can add up to $maxListingPhotos photos.',
      ];
      if (notes.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(notes.join(' '))));
      }
    } catch (e) {
      debugPrint('[photos] picker failed: $e');
      if (mounted) setState(() => _error = 'Could not open your photos. Check the app permissions.');
    }
  }

  Future<void> _photoOptions(int index) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (index > 0)
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Make cover photo'),
                onTap: () => Navigator.pop(context, 'cover'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Remove photo'),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    setState(() {
      final photo = _photos.removeAt(index);
      if (choice == 'cover') {
        _photos.insert(0, photo);
      } else if (photo.url != null) {
        _removedUrls.add(photo.url!);
      }
      _changed = true;
    });
  }

  // Uploads the new photos in order and returns every URL, cover first.
  // A photo keeps its URL after uploading, so trying again doesn't upload it twice.
  Future<List<String>> _uploadPhotos(String sellerId) async {
    final waiting = _photos.where((p) => p.url == null).toList();
    final repo = ref.read(photoRepositoryProvider);
    for (var i = 0; i < waiting.length; i++) {
      setState(() => _progress = 'Uploading photo ${i + 1} of ${waiting.length}...');
      waiting[i].url = await repo.uploadListingPhoto(
        sellerId: sellerId,
        listingId: _listingId,
        photo: waiting[i].picked!,
      );
    }
    return [for (final p in _photos) p.url!];
  }

  // ---------- save ----------

  Future<void> _save(ListingStatus status) async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    final formOk = _formKey.currentState!.validate();
    final needsPhoto = status == ListingStatus.published && _photos.isEmpty;
    if (!formOk || needsPhoto) {
      setState(() => _error = needsPhoto && formOk
          ? 'Add at least one photo before publishing. You can save a draft without photos.'
          : 'Fix the fields in red.');
      return;
    }
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final photoUrls = await _uploadPhotos(uid);
      setState(() => _progress = 'Saving...');
      var listing = _buildListing(status, uid, photoUrls);

      // Only look up the map spot when the address is new or changed.
      final original = _original;
      if (original == null ||
          original.location == null ||
          original.fullAddress != listing.fullAddress) {
        final spot = await ref.read(geocoderProvider).locate(listing.fullAddress);
        listing = spot == null ? listing.copyWith(clearLocation: true) : listing.copyWith(location: spot);
      }

      final repo = ref.read(listingRepositoryProvider);
      final online = _editing ? await repo.updateListing(listing) : await repo.createListing(listing);

      // The listing doesn't point at removed photos anymore, so the files can go.
      final photos = ref.read(photoRepositoryProvider);
      for (final url in _removedUrls) {
        photos.delete(url);
      }
      _removedUrls.clear();
      if (!mounted) return;

      _changed = false;
      _showDone(listing, online);
      _leave();
    } on ListingFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _progress = null;
        });
      }
    }
  }

  void _showDone(Listing listing, bool online) {
    final parts = <String>[
      switch (listing.status) {
        ListingStatus.published => 'Listing published.',
        ListingStatus.draft => 'Draft saved.',
        _ => 'Changes saved.',
      },
      if (listing.location == null)
        "We couldn't find that address on the map, so it won't have a map pin. Buyers can still find it by city and ZIP.",
      if (!online) "No internet right now. It's saved on your phone and will upload when you're back online.",
    ];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(parts.join(' ')), duration: const Duration(seconds: 6)),
    );
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile/my-listings');
    }
  }

  Future<void> _confirmLeave() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text("Your changes to this listing haven't been saved."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep editing')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard')),
        ],
      ),
    );
    if (discard == true && mounted) {
      // Photos uploaded during a save that then failed aren't used by any listing.
      final kept = _original?.photos ?? const [];
      final unused = [..._photos.map((p) => p.url), ..._removedUrls]
          .whereType<String>()
          .where((url) => !kept.contains(url));
      final photos = ref.read(photoRepositoryProvider);
      for (final url in unused) {
        photos.delete(url);
      }
      setState(() => _changed = false);
      _leave();
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _price, _beds, _baths, _sqft, _year, _lot, _address, _city, _zip, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final title = Text(_editing ? 'Edit listing' : 'New listing');

    if (profile != null && !profile.isSeller) {
      return _message(title, 'Only sellers can make listings.');
    }
    if (_loading) {
      return Scaffold(appBar: AppBar(title: title), body: const Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) return _message(title, _loadError!);

    return PopScope(
      canPop: !_changed && !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(title: title),
        body: SafeArea(
          child: Form(
            key: _formKey,
            // Rebuild once so PopScope knows to ask before leaving.
            onChanged: () {
              if (!_changed) setState(() => _changed = true);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Text('Photos (${_photos.length} of $maxListingPhotos)',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'The first photo is the cover. Tap a photo to make it the cover or remove it.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 110,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (var i = 0; i < _photos.length; i++) _photoTile(i),
                      if (_photos.length < maxListingPhotos) _addPhotoTile(),
                    ],
                  ),
                ),
                _section('The basics'),
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Title', hintText: 'Sunny 3 bed near the park'),
                  validator: validateTitle,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final t in HomeType.values)
                      ChoiceChip(
                        label: Text(t.label),
                        selected: _type == t,
                        onSelected: _saving
                            ? null
                            : (_) => setState(() {
                                  _type = t;
                                  _changed = true;
                                }),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,]'))],
                  decoration: const InputDecoration(labelText: 'Price', prefixText: '\$ '),
                  validator: validatePrice,
                ),
                const SizedBox(height: 16),
                _row([
                  _numberField(_beds, 'Beds', validateBeds),
                  _numberField(_baths, 'Baths', validateBaths, decimal: true),
                ]),
                const SizedBox(height: 16),
                Text(
                  'Optional, but they help buyers compare and give better Similar Homes.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                _row([
                  _numberField(_sqft, 'Sq ft', validateSqft),
                  _numberField(_year, 'Year built', (v) => validateYearBuilt(v)),
                  _numberField(_lot, 'Lot (acres)', validateLotSize, decimal: true),
                ]),
                _section('Where is it?'),
                TextFormField(
                  controller: _address,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Street address (optional)',
                    helperText: 'Used for the map pin. Leave it out to only show the city and ZIP.',
                    helperMaxLines: 2,
                  ),
                  validator: (v) => (v?.trim().length ?? 0) > 120 ? 'Address is too long.' : null,
                ),
                const SizedBox(height: 16),
                _row([
                  TextFormField(
                    controller: _city,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: validateCity,
                  ),
                  TextFormField(
                    controller: _zip,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(5),
                    ],
                    decoration: const InputDecoration(labelText: 'ZIP'),
                    validator: validateZip,
                  ),
                ]),
                _section('Amenities'),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final a in amenityOptions)
                      FilterChip(
                        label: Text(a),
                        selected: _amenities.contains(a),
                        onSelected: _saving
                            ? null
                            : (on) => setState(() {
                                  on ? _amenities.add(a) : _amenities.remove(a);
                                  _changed = true;
                                }),
                      ),
                  ],
                ),
                _section('Description'),
                TextFormField(
                  controller: _description,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 4,
                  maxLines: 10,
                  maxLength: 5000,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_progress != null) ...[
                  Text(_progress!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                ],
                _buttons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Which buttons show depends on where the listing is now.
  Widget _buttons() {
    final status = _original?.status ?? ListingStatus.draft;
    final (String, ListingStatus)? left;
    final (String, ListingStatus) right;
    switch (status) {
      case ListingStatus.draft:
        left = ('Save as draft', ListingStatus.draft);
        right = ('Publish', ListingStatus.published);
      case ListingStatus.published:
        left = ('Unpublish', ListingStatus.draft);
        right = ('Save changes', ListingStatus.published);
      case ListingStatus.archived || ListingStatus.sold:
        left = null;
        right = ('Save changes', status);
    }

    return Row(
      children: [
        if (left != null) ...[
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: _saving ? null : () => _save(left!.$2),
              child: Text(left.$1),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: FilledButton(
            onPressed: _saving ? null : () => _save(right.$2),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(right.$1),
          ),
        ),
      ],
    );
  }

  Widget _photoTile(int i) {
    final photo = _photos[i];
    Widget broken(BuildContext _, Object _, StackTrace? _) =>
        const Center(child: Icon(Icons.broken_image_outlined));
    final image = photo.picked != null
        ? Image.memory(photo.picked!.bytes, fit: BoxFit.cover, errorBuilder: broken)
        : Image.network(photo.url!, fit: BoxFit.cover, errorBuilder: broken);
    final colors = Theme.of(context).colorScheme;

    return Padding(
      key: ValueKey('photo-$i'),
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        label: i == 0 ? 'Photo 1, cover' : 'Photo ${i + 1}',
        button: true,
        child: InkWell(
          onTap: _saving ? null : () => _photoOptions(i),
          borderRadius: BorderRadius.circular(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: colors.surfaceContainerHighest, child: image),
                  if (i == 0)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Cover', style: TextStyle(color: colors.onPrimary, fontSize: 12)),
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

  Widget _addPhotoTile() {
    return SizedBox(
      width: 110,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _saving ? null : _pickPhotos,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_a_photo_outlined),
            SizedBox(height: 6),
            Text('Add photos'),
          ],
        ),
      ),
    );
  }

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _row(List<Widget> children) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: children[i]),
          ],
        ],
      );

  Widget _numberField(
    TextEditingController controller,
    String label,
    String? Function(String?) validator, {
    bool decimal = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(decimal ? r'[\d.]' : r'\d'))],
      decoration: InputDecoration(labelText: label),
      validator: validator,
    );
  }

  Widget _message(Widget title, String text) => Scaffold(
        appBar: AppBar(title: title),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(text, textAlign: TextAlign.center),
          ),
        ),
      );
}
