import 'package:cloud_firestore/cloud_firestore.dart';

class Doctor {
  final String id;
  final String name;
  final String email;
  final bool isFirstLogin;
  final String centerId;

  Doctor({
    required this.id,
    required this.name,
    required this.email,
    required this.isFirstLogin,
    required this.centerId,
  });

  factory Doctor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
     bool isFirstLogin;
    if (data['isFirstLogin'] is String) {
      isFirstLogin = data['isFirstLogin'].toLowerCase() == 'true';
    } else if (data['isFirstLogin'] is bool) {
      isFirstLogin = data['isFirstLogin'] as bool;
    } else {
      isFirstLogin = true; 
    }

    return Doctor(
      id: doc.id,
      name: data['name'] as String,
      email: data['email'] as String,
      isFirstLogin: isFirstLogin,
      centerId: data['centerId'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'isFirstLogin': isFirstLogin,
      'centerId': centerId,
    };
  }
}