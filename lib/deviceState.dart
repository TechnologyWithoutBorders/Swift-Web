class DeviceState {
  static const int working = 0;
  static const int maintenance = 1;
  static const int broken = 2;
  static const int inProgress = 3;
  static const int salvage = 4;
  static const int limitations = 5;

  static const names = ["working", "maintenance due", "broken", "in progress", "salvage", "working with limitations"];
}