/// Satu titik destinasi pada sebuah postingan (disimpan sebagai JSON di backend).
class Destination {
  final String name;
  final double? lat;
  final double? lng;

  const Destination({required this.name, this.lat, this.lng});

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      name: (json['name'] ?? '') as String,
      lat: _toDouble(json['lat']),
      lng: _toDouble(json['lng']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
