import 'package:dart_mappable/dart_mappable.dart';

part 'activity_type.mapper.dart';

@MappableClass()
class ActivityType with ActivityTypeMappable {
  final String id;
  final String name;
  final String color;
  final int position;

  const ActivityType({
    required this.id,
    required this.name,
    required this.color,
    required this.position,
  });
}
