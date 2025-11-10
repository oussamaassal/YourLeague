/*

FIREBASE IS OUR BACKEND - You can swap out any backend here..

*/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../domain/entities/app_user.dart';
import '../domain/repos/auth_repo.dart';

class FirebaseAuthRepo implements AuthRepo {
  // access to firebase
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  // access to firebase firestore
  final FirebaseFirestore firestore = FirebaseFirestore.instance; // <-- 2. ADD FIRESTORE INSTANCE



  // LOGIN: Email & Password
  @override
  Future<AppUser?> loginWithEmailPassword(String email, String password) async {
    try {
      // attempt sign in
      UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      // create user
      AppUser user = AppUser(
        uid: userCredential.user!.uid,
        email: email,
      );

      // return user
      return user;
    }

    // catch any errors...
    catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // REGISTER: Email & Password
  @override
  Future<AppUser?> registerWithEmailPassword(
      String name, String email, String password) async {
    try {
      // attempt sign up
      UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      // create user
      AppUser user = AppUser(uid: userCredential.user!.uid, email: email);

      // Step C (THE FIX): Save the user's data to the 'users' collection in Firestore
      await firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': name, // Save the name passed into the function
        'createdAt': FieldValue.serverTimestamp(), // Good practice to add a timestamp
      });

      // return user
      return user;
    }
    // any errors..
    on FirebaseAuthException catch (e) {
      // This block runs if Firebase returns a specific authentication error
      print("Registration failed with FirebaseAuthException code: ${e.code}");

      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('An account already exists for that email.');
      } else if (e.code == 'invalid-email') {
        throw Exception('The email address is not valid.');
      } else {
        // Handle other Firebase-specific errors
        throw Exception('Registration failed. Please try again.');
      }

    } catch (e) {
      // This block catches any other unexpected errors (e.g., network issues)
      print("An unexpected error occurred during registration: $e");
      throw Exception('An unexpected error occurred. Please check your connection.');
    }
  }

  // DELETE ACCOUNT
  @override
  Future<void> deleteAccount() async {
    try {
      // get current user
      final user = firebaseAuth.currentUser;

      // check if there is a logged in user
      if (user == null) throw Exception('No user logged in..');

      // delete account
      await user.delete();

      // logout
      await logout();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // GET CURRENT USER
  @override
  Future<AppUser?> getCurrentUser() async {
    // get current logged in user from firebase
    final firebaseUser = firebaseAuth.currentUser;

    // no logged in user
    if (firebaseUser == null) return null;

    // logged in user exists
    return AppUser(uid: firebaseUser.uid, email: firebaseUser.email!);
  }

  // LOGOUT
  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  // RESET PASSWORD
  @override
  Future<String> sendPasswordResetEmail(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
      return "Password reset email sent! Check your inbox";
    } catch (e) {
      return "An error occured: $e";
    }
  }

  // APPLE SIGN IN
  @override
  Future<AppUser?> signInWithApple() async {
    try {
      // request Apple ID credentials
      final appleCredential =
          await SignInWithApple.getAppleIDCredential(scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ]);

      // create an OAuth credential
      final oAuthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // sign in with the credential
      UserCredential userCredential =
          await firebaseAuth.signInWithCredential(oAuthCredential);

      // firebase user
      final firebaseUser = userCredential.user;

      // user cancelled the sign-in process
      if (firebaseUser == null) return null;

      AppUser appUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
      );

      return appUser;
    } catch (e) {
      print("Error signing in with apple: $e");
      return null;
    }
  }

  // GOOGLE SIGN IN
  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      // begin the interactive sign-in process
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

      // user cancelled sign-in
      if (gUser == null) return null;

      // obtain auth details from request
      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      // create a credential for the user
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      // sign in with these credentials
      UserCredential userCredential =
          await firebaseAuth.signInWithCredential(credential);

      // firebase user
      final firebaseUser = userCredential.user;

      // user cancelled sign-in process
      if (firebaseUser == null) return null;

      AppUser appUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
      );

      return appUser;
    } catch (e) {
      print(e);
      return null;
    }
  }
}
