import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: RegistrationForm(),
    );
  }
}

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nrpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _deviceID;

  @override
  void initState() {
    super.initState();
    _checkAndGenerateUUID();
  }

  Future<void> _checkAndGenerateUUID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUUID = prefs.getString('device_id');

    if (savedUUID == null) {
      // Generate unique code
      var uuid = const Uuid();
      String uniqueCode = uuid.v4();

      // Save unique code locally
      await prefs.setString('device_id', uniqueCode);

      // Set _deviceID to the newly generated UUID
      setState(() {
        _deviceID = uniqueCode;
      });

      // Display the generated UUID in the terminal
      if (kDebugMode) {
        print('Generated UUID: $uniqueCode');
      }
    } else {
      // Set _deviceID to the saved UUID
      setState(() {
        _deviceID = savedUUID;
      });

      // Display the saved UUID in the terminal
      if (kDebugMode) {
        print('Retrieved UUID: $savedUUID');
      }
    }
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Get the UUID from local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? deviceID = prefs.getString('device_id');

      // Prepare data to be sent as JSON
      Map<String, String> data = {
        'uuid': deviceID!,
        'name': _nameController.text,
        'nrp': _nrpController.text,
        'password': _passwordController.text,
      };

      // Convert data to JSON
      String jsonData = jsonEncode(data);

      // Send POST request
      try {
        http.Response response = await http.post(
          Uri.parse('http://209.182.237.240:1880/apk'),
          headers: {'Content-Type': 'application/json'},
          body: jsonData,
        );

        if (response.statusCode == 200) {
          // If the server returns a 200 OK response, show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful!')),
          );
        } else {
          // If the server did not return a 200 OK response, show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Registration failed: ${response.reasonPhrase}')),
          );
        }
      } catch (e) {
        // If there was an error sending the request, show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_deviceID != null)
              Text('Your Device ID: $_deviceID',
                  style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _nrpController,
                    decoration: const InputDecoration(labelText: 'NRP'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your NRP';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _registerUser,
                    child: const Text('Register'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
