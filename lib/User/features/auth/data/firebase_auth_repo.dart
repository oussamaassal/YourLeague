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
  @override
  Future<void> deleteAccount() async {
    try {
      // Get current user
      final user = firebaseAuth.currentUser;

      // Check if there is a logged in user
      if (user == null) {
        throw Exception('No user is currently logged in.');
      }

      final uid = user.uid;

      // --- NEW: Delete user's document from Firestore ---
      // This will also delete all subcollections, including 'friends'.
      await firestore.collection('users').doc(uid).delete();

      // --- Delete the Firebase Auth user ---
      // This must be done after other cleanup as it requires re-authentication.
      await user.delete();

      // --- Final logout ---
      await logout();

    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors, like 'requires-recent-login'
      if (e.code == 'requires-recent-login') {
        throw Exception(
            'This is a sensitive operation and requires a recent sign-in. Please log out and log back in to delete your account.'
        );
      }
      // Handle other potential auth errors
      throw Exception('Failed to delete account: ${e.message}');
    } catch (e) {
      // Handle Firestore errors or other general issues
      throw Exception('An error occurred while deleting your account: $e');
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
      // 1. Begin the interactive sign-in process
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

      // 2. User cancelled the sign-in
      if (gUser == null) return null;

      // 3. Obtain auth details from the request
      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      // 4. Create a new Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      // 5. Sign in to Firebase with the credential
      UserCredential userCredential =
      await firebaseAuth.signInWithCredential(credential);

      final firebaseUser = userCredential.user;

      if (firebaseUser == null) return null;

      // 6. *** NEW: Check if this is a new user ***
      // If the user is new, 'additionalUserInfo.isNewUser' will be true.
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        // Create a document for the new user in Firestore
        await firestore.collection('users').doc(firebaseUser.uid).set({
          'uid': firebaseUser.uid,
          'email': firebaseUser.email,
          'name': firebaseUser.displayName, // Get name from Google profile
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // 7. Create and return the AppUser object
      AppUser appUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
      );

      return appUser;
    } catch (e) {
      print("Error signing in with Google: $e");
      // Optionally, provide a more user-friendly error
      throw Exception('Failed to sign in with Google: $e');
    }
  }

}
