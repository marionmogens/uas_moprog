import 'package:flutter/material.dart';
import '../models/venue_filter.dart';
import '../utils/formatters.dart';

Future<VenueFilter?> showFilterSheet(
    BuildContext context, {
      required VenueFilter current,
      required List<String> cities,
      required bool hasLocation,
    }) {
  return showModalBottomSheet<VenueFilter>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _FilterSheet(
      current: current,
      cities: cities,
      hasLocation: hasLocation,
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  final VenueFilter current;
  final List<String> cities;
  final bool hasLocation;
  const _FilterSheet({
    required this.current,
    required this.cities,
    required this.hasLocation,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late VenueFilter _f = widget.current;

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
  );

  ChoiceChip _chip(String label, bool selected, VoidCallback onTap,
      {bool enabled = true}) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      selectedColor: Colors.pink.shade100,
      onSelected: enabled ? (_) => onTap() : null,
    );
  }

  String get _budgetLabel {
    final min = formatRupiah(_f.minPrice);
    final max = _f.maxPrice >= VenueFilter.budgetMax
        ? '${formatRupiah(VenueFilter.budgetMax)}+'
        : formatRupiah(_f.maxPrice);
    return '$min - $max / jam';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Filter & Urutkan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _f = const VenueFilter()),
                    child: const Text('Reset'),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _title('Kota / wilayah'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _chip('Semua', _f.city == null,
                                  () => setState(() => _f = _f.copyWith(clearCity: true))),
                          for (final c in widget.cities)
                            _chip(c, _f.city == c,
                                    () => setState(() => _f = _f.copyWith(city: c))),
                        ],
                      ),
                      _title('Budget per jam'),
                      Text(_budgetLabel,
                          style: TextStyle(color: Colors.pink.shade400, fontSize: 13)),
                      RangeSlider(
                        values: RangeValues(
                            _f.minPrice.toDouble(), _f.maxPrice.toDouble()),
                        min: VenueFilter.budgetMin.toDouble(),
                        max: VenueFilter.budgetMax.toDouble(),
                        divisions: (VenueFilter.budgetMax - VenueFilter.budgetMin) ~/
                            VenueFilter.budgetStep,
                        activeColor: Colors.pink.shade300,
                        onChanged: (v) => setState(() => _f = _f.copyWith(
                          minPrice: v.start.round(),
                          maxPrice: v.end.round(),
                        )),
                      ),
                      _title('Jarak dari lokasiku'),
                      if (!widget.hasLocation)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'Aktifkan tombol "Dekat saya" di Beranda dulu untuk memakai filter jarak.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _chip('Semua', _f.radiusKm == null,
                                  () => setState(() => _f = _f.copyWith(clearRadius: true)),
                              enabled: widget.hasLocation),
                          for (final r in VenueFilter.radiusOptions)
                            _chip('≤ ${r.toStringAsFixed(0)} km', _f.radiusKm == r,
                                    () => setState(() => _f = _f.copyWith(radiusKm: r)),
                                enabled: widget.hasLocation),
                        ],
                      ),
                      _title('Tipe'),
                      Wrap(
                        spacing: 8,
                        children: [
                          _chip('Semua', _f.indoor == null,
                                  () => setState(() => _f = _f.copyWith(clearIndoor: true))),
                          _chip('Indoor', _f.indoor == true,
                                  () => setState(() => _f = _f.copyWith(indoor: true))),
                          _chip('Outdoor', _f.indoor == false,
                                  () => setState(() => _f = _f.copyWith(indoor: false))),
                        ],
                      ),
                      _title('Urutkan'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final s in VenueSort.values)
                            _chip(
                              s.label,
                              _f.sort == s,
                                  () => setState(() => _f = _f.copyWith(sort: s)),
                              enabled: s != VenueSort.nearest || widget.hasLocation,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _f),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade300,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Terapkan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}