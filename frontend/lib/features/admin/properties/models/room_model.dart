import 'package:flutter/material.dart';

enum RoomStatus { available, rented, maintenance }

extension RoomStatusExtension on RoomStatus {
  String get label {
    switch (this) {
      case RoomStatus.available: return 'Trống';
      case RoomStatus.rented: return 'Đã thuê';
      case RoomStatus.maintenance: return 'Bảo trì';
    }
  }

  Color get color {
    switch (this) {
      case RoomStatus.available: return const Color(0xFF2E7D32); 
      case RoomStatus.rented: return Colors.grey.shade600;
      case RoomStatus.maintenance: return Colors.orange.shade700;
    }
  }

  Color get bgColor {
    switch (this) {
      case RoomStatus.available: return const Color(0xFFE8F5E9); 
      case RoomStatus.rented: return Colors.grey.shade100;
      case RoomStatus.maintenance: return Colors.orange.shade50;
    }
  }
}

class RoomModel {
  final String id;
  final String name;
  final RoomStatus status;
  final double price;
  final double? area;
  final String? furniture;
  final String? description;

  final String? tenantName;
  final String? tenantPhone;
  final String? tenantCCCD;
  final String? tenantAddress;
  final double? contractDeposit;
  final DateTime? contractStartDate;
  final DateTime? contractEndDate;

  final int? electricityIndex;
  final int? waterIndex;

  final double? electricityPrice;
  final double? waterPrice;
  final double? internetPrice;
  final double? servicePrice;

  RoomModel({
    required this.id,
    required this.name,
    required this.status,
    required this.price,
    this.area,
    this.furniture,
    this.description,
    this.tenantName,
    this.tenantPhone,
    this.tenantCCCD,
    this.tenantAddress,
    this.contractDeposit,
    this.contractStartDate,
    this.contractEndDate,
    this.electricityIndex,
    this.waterIndex,
    this.electricityPrice,
    this.waterPrice,
    this.internetPrice,
    this.servicePrice,
  });
}