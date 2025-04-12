import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:socialx/app.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {  
    await Firebase.initializeApp();
  }
  runApp( const MyApp());
}