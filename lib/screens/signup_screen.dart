import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController gstController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    var user = await _authService.signUp(
      shopNameController.text.trim(),
      gstController.text.trim(),
      usernameController.text.trim(),
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed. Check logs for details.")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add, size: 80, color: Colors.green),
                  SizedBox(height: 20),
                  Text(
                    "Create an Account",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 30),

                  // Shop Name
                  TextFormField(
                    controller: shopNameController,
                    decoration: InputDecoration(
                      labelText: "Shop Name",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store),
                    ),
                    validator: (value) =>
                    value!.isEmpty ? "Enter your shop name" : null,
                  ),
                  SizedBox(height: 15),

                  // GST Number
                  TextFormField(
                    controller: gstController,
                    decoration: InputDecoration(
                      labelText: "GST Number",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.confirmation_number),
                    ),
                    validator: (value) =>
                    value!.isEmpty ? "Enter your GST number" : null,
                  ),
                  SizedBox(height: 15),

                  // Username
                  TextFormField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: "Username",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) =>
                    value!.isEmpty ? "Enter your username" : null,
                  ),
                  SizedBox(height: 15),

                  // Email
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) =>
                    value!.isEmpty || !value.contains("@") ? "Enter a valid email" : null,
                  ),
                  SizedBox(height: 15),

                  // Password
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) =>
                    value!.length < 6 ? "Password must be 6+ characters" : null,
                  ),
                  SizedBox(height: 15),

                  // Confirm Password
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) =>
                    value != passwordController.text ? "Passwords do not match" : null,
                  ),
                  SizedBox(height: 20),

                  // Sign Up Button
                  _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                    onPressed: signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    child: Text("Sign Up", style: TextStyle(fontSize: 18)),
                  ),

                  SizedBox(height: 15),

                  // Already have an account? Login
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Already have an account? Login"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
