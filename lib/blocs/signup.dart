import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smuni/repositories/auth.dart';
import 'package:smuni/repositories/user.dart';

abstract class SignUpBlocEvent {
  const SignUpBlocEvent();
}

class AuthenticatePhoneNo extends SignUpBlocEvent {
  String phoneNo;
  AuthenticatePhoneNo({required this.phoneNo});
}

class SignUpToBackEndEvent extends SignUpBlocEvent {
  //final String name;
  final String email;
  final String password;
  final String phone;
  final String username;

  SignUpToBackEndEvent({
    // required this.name,
    required this.username,
    required this.email,
    required this.password,
    required this.phone,
  });
}

class OtpSentEvent extends SignUpBlocEvent {
  final String otpCode;
  OtpSentEvent(this.otpCode);
}

abstract class SignUpBlocState {
  const SignUpBlocState();
}

class PhoneNumberVerified extends SignUpBlocState {
  String? message;
  PhoneNumberVerified(this.message);
}

class FirebaseError extends SignUpBlocState {
  String? errorMessage;
  FirebaseError({this.errorMessage});
}

class SignUpSuccess extends SignUpBlocState {
  final String? successMessage;
  SignUpSuccess({this.successMessage});
}

class SignUpFailure extends SignUpBlocState {
  final String? failureMessage;
  SignUpFailure({this.failureMessage});
}

class NotSignedUp extends SignUpBlocState {
  NotSignedUp();
}

// The Sign up Bloc

class SignUpBloc extends Bloc<SignUpBlocEvent, SignUpBlocState> {
  final AuthRepository repository;
  final ApiUserRepository apiUserRepository;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  SignUpBloc(
      this.repository, SignUpBlocState initialState, this.apiUserRepository)
      : super(initialState) {
    on<AuthenticatePhoneNo>(authenticatePhoneNumber);
    on<OtpSentEvent>(firebaseCodeSent);
    on<SignUpToBackEndEvent>(signUpToBackend);
  }

  Future<void> authenticatePhoneNumber(
      AuthenticatePhoneNo event, Emitter<SignUpBlocState> emitter) async {
    try {
      repository.authenticatePhoneNumber(event.phoneNo, _firebaseAuth);
    } on MyFirebaseError catch (e) {
      emitter(FirebaseError(errorMessage: e.toString()));
    } catch (e) {
      emitter(FirebaseError(errorMessage: 'An error occurred'));
    }
  }

  Future<void> firebaseCodeSent(OtpSentEvent event, Emitter emitter) async {
    try {
      repository.firebaseCodeSent(
          otpCode: event.otpCode, firebaseAuth: _firebaseAuth);
      emitter(PhoneNumberVerified('Phone Number verified successfully'));
    } on MyFirebaseError catch (e) {
      emitter(FirebaseError(errorMessage: e.toString()));
    } catch (e) {
      emitter(FirebaseError(errorMessage: e.toString()));
    }
  }

  Future<void> signUpToBackend(
      SignUpToBackEndEvent event, Emitter<SignUpBlocState> emitter) async {
    try {
      final firebaseUserId = _firebaseAuth.currentUser!.uid;
      apiUserRepository.createUser(
          firebaseId: firebaseUserId,
          phoneNo: event.phone,
          email: event.email,
          password: event.password,
          username: event.username);
      emitter(SignUpSuccess(successMessage: 'Sign up successful'));
    } catch (e) {
      emitter(SignUpFailure(
          failureMessage: 'Something went wrong, try again later.'));
    }
  }
}
