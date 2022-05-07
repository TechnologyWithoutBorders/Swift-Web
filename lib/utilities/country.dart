class Country {
  final String name;
  final String code;

  Country({required this.name, required this.code});

  factory Country.fromString(String countryInfo) {
    List<String> parts = countryInfo.split(":");

    return Country(
      name: parts[0],
      code: parts[1],
    );
  }
}