import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hris_app/features/sales/data/models/store_model.dart';

class StoreModel {
  final String id;
  final String name;
  final String ownerName;
  final String address;
  final bool isNew;
  final double latitude;
  final double longitude;

  StoreModel({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.address,
    this.isNew = false,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      ownerName: json['owner_name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      isNew: json['first_transaction_date'] == null,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'owner_name': ownerName,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
  };
}
