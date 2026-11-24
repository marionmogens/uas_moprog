import 'package:flutter/material.dart';
import '../../data/booking_options.dart';
import '../../models/padel_court.dart';
import '../../services/api_exception.dart';
import '../../services/location_service.dart';
import '../../services/venue_service.dart';
import '../../utils/ui_helpers.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

const List<String> _facilityChoices = [
  'Parkir', 'Toilet', 'Kantin', 'Mushola', 'AC', 'Shower', 'Loker', 'Wifi',
];

class VenueFormPage extends StatefulWidget {
  final PadelCourt? existing;
  const VenueFormPage({super.key, this.existing});

  @override
  State<VenueFormPage> createState() => _VenueFormPageState();
}

class _VenueFormPageState extends State<VenueFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _address;
  late final TextEditingController _mapsUrl;
  late final TextEditingController _whatsapp;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late final TextEditingController _imageUrl;
  late final TextEditingController _lat;
  late final TextEditingController _lng;

  late String _category;
  late bool _isIndoor;
  late int _fieldCount;
  late int _openHour;
  late int _closeHour;
  late Set<String> _facilities;
  late Set<int> _classStarts;

  bool _saving = false;
  bool _locating = false;

  bool get _isEdit => widget.existing != null;
  bool get _isClass => _category == 'Kelas';

  @override
  void initState() {
    super.initState();
    final v = widget.existing;
    _name = TextEditingController(text: v?.name ?? '');
    _city = TextEditingController(text: v?.city ?? '');
    _address = TextEditingController(text: v?.address ?? '');
    _mapsUrl = TextEditingController(text: v?.mapsUrl ?? '');
    _whatsapp = TextEditingController(text: v?.whatsapp ?? '');
    _price = TextEditingController(text: v == null ? '' : '${v.pricePerHour}');
    _description = TextEditingController(text: v?.description ?? '');
    _imageUrl = TextEditingController(text: v?.imageUrl ?? '');
    _lat = TextEditingController(text: v?.latitude?.toString() ?? '');
    _lng = TextEditingController(text: v?.longitude?.toString() ?? '');
    _category = v?.category ?? 'Lapangan';
    _isIndoor = v?.isIndoor ?? true;
    _fieldCount = v?.fieldCount ?? 1;
    _openHour = v?.openHour ?? 6;
    _closeHour = v?.closeHour ?? 22;
    _facilities = {...?v?.facilities};
    _classStarts = {...?v?.classStartSlots};
  }

  @override
  void dispose() {
    for (final c in [
      _name, _city, _address, _mapsUrl, _whatsapp, _price, _description,
      _imageUrl, _lat, _lng,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final loc = await LocationService.instance.getCurrent();
      _lat.text = loc.latitude.toStringAsFixed(6);
      _lng.text = loc.longitude.toStringAsFixed(6);
    } on LocationException catch (e) {
      if (mounted) showMessage(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  String? _coordValidator(String? v, {required bool isLat}) {
    final text = (v ?? '').trim();
    final other = (isLat ? _lng : _lat).text.trim();
    if (text.isEmpty) return other.isEmpty ? null : 'Isi lat & long berdua';
    final n = double.tryParse(text.replaceAll(',', '.'));
    if (n == null) return 'Harus angka';
    if (isLat && (n < -90 || n > 90)) return 'Antara -90 s/d 90';
    if (!isLat && (n < -180 || n > 180)) return 'Antara -180 s/d 180';
    return null;
  }

  double? _parseCoord(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : double.tryParse(t.replaceAll(',', '.'));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isClass && _classStarts.isEmpty) {
      showMessage(context, 'Pilih minimal satu jam mulai sesi kelas', isError: true);
      return;
    }
    if (_closeHour <= _openHour) {
      showMessage(context, 'Jam tutup harus setelah jam buka', isError: true);
      return;
    }

    final data = <String, dynamic>{
      'category': _category,
      'name': _name.text.trim(),
      'city': _city.text.trim(),
      'address': _address.text.trim(),
      'maps_url': _mapsUrl.text.trim(),
      'whatsapp': _whatsapp.text.trim(),
      'is_indoor': _isIndoor,
      'field_count': _isClass ? 1 : _fieldCount,
      'price_per_hour': int.parse(_price.text.trim()),
      'open_hour': _openHour,
      'close_hour': _closeHour,
      'facilities': _facilities.toList(),
      'description': _description.text.trim(),
      'image_url': _imageUrl.text.trim(),
      'class_start_slots': _isClass ? (_classStarts.toList()..sort()) : <int>[],
      'latitude': _parseCoord(_lat),
      'longitude': _parseCoord(_lng),
    };

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await VenueService.instance.update(widget.existing!.id, data);
      } else {
        await VenueService.instance.create(data);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _section(String text) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Text(text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
  );

  Widget _hourPicker(String label, int value, int from, int to,
      ValueChanged<int> onChanged) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          isExpanded: true,
          items: [
            for (var h = from; h <= to; h++)
              DropdownMenuItem(
                  value: h, child: Text('${h.toString().padLeft(2, '0')}.00')),
          ],
          onChanged: (v) => onChanged(v ?? value),
        ),
      ),
    );
  }

  String _sessionLabel(int start) {
    String h(int x) => '${(PadelCourt.firstSlotHour + x).toString().padLeft(2, '0')}:00';
    return '${h(start)} - ${h(start + 2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.pink.shade300,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(_isEdit ? 'Ubah Tempat' : 'Daftarkan Tempat',
            style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_isEdit)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Pengajuanmu akan ditinjau admin. Setelah disetujui, tempat '
                              'tampil di Beranda dan kamu resmi menjadi Pemilik Tempat.',
                          style: TextStyle(fontSize: 12.5, color: Colors.pink.shade700),
                        ),
                      ),
                    _section('Jenis'),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Lapangan', label: Text('Lapangan')),
                        ButtonSegment(value: 'Kelas', label: Text('Kelas')),
                      ],
                      selected: {_category},
                      onSelectionChanged: (s) => setState(() => _category = s.first),
                    ),
                    _section('Informasi dasar'),
                    AppTextField(
                      controller: _name,
                      label: _isClass ? 'Nama Kelas' : 'Nama Lapangan / Venue',
                      icon: Icons.sports_tennis,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _city,
                      label: 'Kota / Wilayah (mis. Jakarta Selatan)',
                      icon: Icons.location_city_outlined,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Kota wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _address,
                      label: 'Alamat / Area',
                      icon: Icons.place_outlined,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Alamat wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _whatsapp,
                      label: 'WhatsApp pengelola (opsional)',
                      icon: Icons.chat_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _mapsUrl,
                      label: 'Link Google Maps (opsional)',
                      icon: Icons.map_outlined,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                    ),
                    _section('Titik lokasi (untuk fitur "Dekat saya")'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _lat,
                            label: 'Latitude',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true, signed: true),
                            validator: (v) => _coordValidator(v, isLat: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppTextField(
                            controller: _lng,
                            label: 'Longitude',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true, signed: true),
                            validator: (v) => _coordValidator(v, isLat: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _locating ? null : _useMyLocation,
                        icon: _locating
                            ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location, size: 18),
                        label: const Text('Pakai lokasiku sekarang'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Isi saat kamu berada di lokasi, atau salin koordinat dari Google Maps. '
                            'Tanpa koordinat, tempat tidak muncul di filter jarak.',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                      ),
                    ),
                    _section('Harga & jam'),
                    AppTextField(
                      controller: _price,
                      label: _isClass ? 'Harga per jam (kelas 2 jam = 2x)' : 'Harga per jam (Rp)',
                      icon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null || n <= 0) return 'Isi harga dengan angka > 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _hourPicker('Jam buka', _openHour, 6, 22,
                                  (v) => setState(() => _openHour = v)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _hourPicker('Jam tutup', _closeHour, 7, 23,
                                  (v) => setState(() => _closeHour = v)),
                        ),
                      ],
                    ),
                    if (!_isClass) ...[
                      const SizedBox(height: 12),
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Jumlah lapangan',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _fieldCount > 1
                                  ? () => setState(() => _fieldCount--)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('$_fieldCount',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                              onPressed: _fieldCount < 10
                                  ? () => setState(() => _fieldCount++)
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_isClass) ...[
                      _section('Jam mulai sesi kelas (tiap sesi 2 jam)'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (var i = 0; i <= timeSlots.length - 2 && i <= 15; i++)
                            FilterChip(
                              label: Text(_sessionLabel(i),
                                  style: const TextStyle(fontSize: 11.5)),
                              selected: _classStarts.contains(i),
                              selectedColor: Colors.pink.shade100,
                              onSelected: (on) => setState(() {
                                on ? _classStarts.add(i) : _classStarts.remove(i);
                              }),
                            ),
                        ],
                      ),
                    ],
                    _section('Detail'),
                    SwitchListTile(
                      value: _isIndoor,
                      onChanged: (v) => setState(() => _isIndoor = v),
                      activeColor: Colors.pink.shade300,
                      contentPadding: EdgeInsets.zero,
                      title: Text(_isIndoor ? 'Indoor' : 'Outdoor'),
                      subtitle: const Text('Geser untuk mengubah tipe'),
                    ),
                    const SizedBox(height: 4),
                    const Text('Fasilitas',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final f in _facilityChoices)
                          FilterChip(
                            label: Text(f, style: const TextStyle(fontSize: 12)),
                            selected: _facilities.contains(f),
                            selectedColor: Colors.pink.shade100,
                            onSelected: (on) => setState(() {
                              on ? _facilities.add(f) : _facilities.remove(f);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _description,
                      maxLines: 4,
                      validator: (v) =>
                      (v ?? '').trim().length < 20 ? 'Deskripsi minimal 20 karakter' : null,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi',
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _imageUrl,
                      label: 'Link foto (URL gambar)',
                      icon: Icons.image_outlined,
                      keyboardType: TextInputType.url,
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'Link foto wajib diisi';
                        if (!t.startsWith('http')) return 'Harus diawali http:// atau https://';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: _isEdit ? 'Simpan Perubahan' : 'Kirim Pengajuan',
                      loading: _saving,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}