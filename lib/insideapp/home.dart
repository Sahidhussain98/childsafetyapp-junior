import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  late String userId;
  late String deviceId;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
  GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();

    // Initialize or retrieve user and device IDs
    userId = 'user123'; // Replace with actual logic to retrieve or generate the user ID
    deviceId = 'device456'; // Replace with actual logic to retrieve or generate the device ID

    // Fetch and update location every 30 seconds
    _timer = Timer.periodic(Duration(minutes: 5), (Timer timer) {
      _fetchAndStoreLocation();
    });
  }

  Future<void> _fetchAndStoreLocation() async {
    try {
      Position position = await _getUserCurrentLocation();
      await _storeLocationInFirestore(position);
    } catch (e) {
      print('Error fetching and storing location data: $e');
    }
  }

  Future<Position> _getUserCurrentLocation() async {
    await Geolocator.requestPermission().then((value) {}).onError((error, stackTrace) {
      print("Error: " + error.toString());
    });

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _storeLocationInFirestore(Position position) async {
    try {
      // Reference to the user's document
      DocumentReference userDocRef = FirebaseFirestore.instance.collection('users_devices').doc(userId);

      // Reference to the device's document under the user
      DocumentReference deviceDocRef = userDocRef.collection('devices').doc(deviceId);

      // Reference to the location document under the device
      DocumentReference locationDocRef = deviceDocRef.collection('locations').doc('current');

      // Update the location fields
      await locationDocRef.set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now(),
      });
    } catch (e) {
      print('Error storing location data: $e');
    }
  }

  Future<bool> validatePassword(String enteredPassword) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Validate the entered password against the user's actual password
        AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: enteredPassword);
        await user.reauthenticateWithCredential(credential);
        return true;
      } else {
        print('No user is logged in');
        return false;
      }
    } catch (e) {
      print('Error validating password: $e');
      return false;
    }
  }

  Future<void> _signOutWithConfirmation(BuildContext context) async {
    TextEditingController passwordController = TextEditingController();

    bool passwordConfirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Password'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Enter your password',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Validate the password
                if (await validatePassword(passwordController.text.trim())) {
                  Navigator.of(context).pop(true);
                } else {
                  // Show an error message for an invalid password using GlobalKey
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invalid password. Please try again.'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                  Navigator.of(context).pop(false);
                }
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (passwordConfirmed == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Home Screen'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _signOutWithConfirmation(context);
            },
          ),
        ],
      ),
      body: Center(
        child: const Text('Auto-updating location every 30 seconds'),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer to avoid memory leaks
    super.dispose();
  }
}
