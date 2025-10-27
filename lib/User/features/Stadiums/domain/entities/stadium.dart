class Stadium {
  final String id;
  final String name;
  final String location;
  final int capacity;
  final double pricePerHour;


  Stadium({
    required this.id,
    required this.name,
    required this.location,
    required this.capacity,
    required this.pricePerHour,

  });

  factory Stadium.fromFirestore(Map<String, dynamic> data, String id) {
    return Stadium(
      id: id,
      name: data['name'],
      location: data['location'],
      capacity: data['capacity'],
      pricePerHour: data['price_per_hour'],

    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      "name": name,
      "location": location,
      "capacity": capacity,
      "price_per_hour": pricePerHour,

    };
  }
}
