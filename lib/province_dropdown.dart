import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProvinceDropdown extends StatefulWidget {
  const ProvinceDropdown({
    super.key,
    required this.foregroundColor,
    this.dropdownColor,
    this.iconSize = 18,
  });

  final Color foregroundColor;
  final Color? dropdownColor;
  final double iconSize;

  @override
  State<ProvinceDropdown> createState() => _ProvinceDropdownState();
}

class _ProvinceDropdownState extends State<ProvinceDropdown> {
  static const String _prefsKey = 'selected_province';

  static const List<String> _provinces = <String>[
    'Eastern Cape',
    'Free State',
    'Gauteng',
    'KwaZulu-Natal',
    'Limpopo',
    'Mpumalanga',
    'Northern Cape',
    'North West',
    'Western Cape',
  ];

  String _selectedProvince = 'Free State';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String value = prefs.getString(_prefsKey) ?? '';
    if (!mounted) return;
    if (value.isNotEmpty && _provinces.contains(value)) {
      setState(() {
        _selectedProvince = value;
      });
    }
  }

  Future<void> _save(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, value);
  }

  @override
  Widget build(BuildContext context) {
    final Color dropdownColor = widget.dropdownColor ?? Theme.of(context).cardColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          Icons.location_on_outlined,
          size: widget.iconSize,
          color: widget.foregroundColor,
        ),
        const SizedBox(width: 4),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedProvince,
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: widget.iconSize,
              color: widget.foregroundColor,
            ),
            dropdownColor: dropdownColor,
            style: TextStyle(
              color: widget.foregroundColor,
              fontWeight: FontWeight.w600,
            ),
            items: _provinces
                .map(
                  (String p) => DropdownMenuItem<String>(
                    value: p,
                    child: Text(p),
                  ),
                )
                .toList(),
            onChanged: (String? value) {
              if (value == null) return;
              setState(() {
                _selectedProvince = value;
              });
              _save(value);
            },
          ),
        ),
      ],
    );
  }
}
