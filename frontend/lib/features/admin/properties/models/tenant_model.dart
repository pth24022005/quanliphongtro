import '../../properties/models/room_model.dart';

class TenantModel {
  final String roomId;
  final String fullName;
  final String phone;
  final String roomName;
  final RoomModel room;

  TenantModel({
    required this.roomId,
    required this.fullName,
    required this.phone,
    required this.roomName,
    required this.room,
  });
}
