import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Sign Up User and Save Details to Firestore (Default role: "user")
  Future<User?> signUp(String shopName, String gst, String username, String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        await _firestore.collection("users").doc(user.uid).set({
          "shopName": shopName,
          "gst": gst,
          "username": username,
          "email": email,
          "role": "user", // 👈 Default role is "user"
          "createdAt": FieldValue.serverTimestamp(),
        });

        return user;
      }
    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuth Error: ${e.code} - ${e.message}");
    } catch (e) {
      print("❌ General Error: $e");
    }
    return null;
  }

  // ✅ Sign-In Method
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("❌ SignIn Error: ${e.code} - ${e.message}");
    }
    return null;
  }

  // ✅ Sign-Out Method
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ✅ Reset Password (Forgot Password)
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print("✅ Password reset email sent to $email");
      return true;
    } on FirebaseAuthException catch (e) {
      print("❌ Reset Password Error: ${e.code} - ${e.message}");
      return false;
    }
  }

  // ✅ Check if the logged-in user is an admin
  Future<bool> isAdmin() async {
    var user = _auth.currentUser;
    if (user != null) {
      var doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.exists && doc.data()?['role'] == "admin";
    }
    return false;
  }

  // ✅ Promote User to Admin (Requires manual action in Firestore)
  Future<void> makeAdmin(String userId) async {
    try {
      await _firestore.collection("users").doc(userId).update({
        "role": "admin",
      });
      print("✅ User $userId is now an admin");
    } catch (e) {
      print("❌ Error making user admin: $e");
    }
  }
}
