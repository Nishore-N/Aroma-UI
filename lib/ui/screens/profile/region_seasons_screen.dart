import 'package:flutter/material.dart';

class RegionSeasonsScreen extends StatefulWidget {
  const RegionSeasonsScreen({super.key});

  @override
  State<RegionSeasonsScreen> createState() => _RegionSeasonsScreenState();
}

class _RegionSeasonsScreenState extends State<RegionSeasonsScreen> {
  static const Color _accent = Color(0xFFFF7A4A);

  final List<String> _indianRegions = [
    'North Indian',
    'South Indian',
    'East Indian',
    'West Indian',
  ];

  final List<String> _globalRegions = [
    'Italian',
    'Chinese',
    'Mexican',
    'Thai',
    'Japanese',
  ];

  // initial selected like in screenshot
  final Set<String> _selectedIndian = {'South Indian', 'West Indian'};
  final Set<String> _selectedGlobal = {'Italian'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // title + subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 4),
                Text(
                  'Region & Seasons',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your regional preferences.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
          const Divider(height: 1),

          // list content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _sectionHeader('Indian Regions'),
                  ..._indianRegions.map(
                    (r) => _regionRow(
                      context,
                      label: r,
                      selected: _selectedIndian.contains(r),
                      onChanged: () {
                        setState(() {
                          if (_selectedIndian.contains(r)) {
                            _selectedIndian.remove(r);
                          } else {
                            _selectedIndian.add(r);
                          }
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 8),
                  _sectionHeader('Global Regions'),
                  ..._globalRegions.map(
                    (r) => _regionRow(
                      context,
                      label: r,
                      selected: _selectedGlobal.contains(r),
                      onChanged: () {
                        setState(() {
                          if (_selectedGlobal.contains(r)) {
                            _selectedGlobal.remove(r);
                          } else {
                            _selectedGlobal.add(r);
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Save button at bottom
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _onSave,
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // grey block header like in screenshot
  Widget _sectionHeader(String text) {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade100,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // one row with label, checkbox and divider under it
  Widget _regionRow(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onChanged,
  }) {
    const Color accent = _accent;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    color: selected ? accent : Colors.black87,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                Checkbox(
                  value: selected,
                  onChanged: (_) => onChanged(),
                  activeColor: accent,
                  side: BorderSide(
                    color: selected
                        ? accent
                        : Colors.grey.shade400,
                    width: 1.4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.8,
          color: Colors.grey.shade300,
        ),
      ],
    );
  }

  void _onSave() {
    // return selected values to previous screen
    Navigator.pop(context, {
      'indianRegions': _selectedIndian.toList(),
      'globalRegions': _selectedGlobal.toList(),
    });
  }
}
