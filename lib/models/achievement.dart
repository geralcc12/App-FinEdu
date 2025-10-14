class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon; // Using string for icons for now (e.g., emoji or asset path)

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}
