import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:socialx/app.dart';
//import 'package:socialx/firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {  
    await Firebase.initializeApp();
  }
  //await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp( const MyApp());
}