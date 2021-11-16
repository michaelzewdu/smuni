import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smuni/repositories/auth.dart';

abstract class SignUpBlocEvent {
  const SignUpBlocEvent();
}

class SignUpEvent extends SignUpBlocEvent {
  final String name;
  final String email;
  final String password;
  final String phone;
  final String username;
  final String? otpCode;

  SignUpEvent(
      {required this.name,
      required this.username,
      required this.email,
      required this.password,
      required this.phone,
      this.otpCode});
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
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  SignUpBloc(this.repository, SignUpBlocState initialState)
      : super(initialState) {
    on<SignUpEvent>(authenticatePhoneNumber);
    on<OtpSentEvent>(firebaseCodeSent);
  }

  Future<void> authenticatePhoneNumber(
      SignUpEvent event, Emitter<SignUpBlocState> emitter) async {
    try {
      repository.authenticatePhoneNumber(event.phone, _firebaseAuth);
    } on MyFirebaseError catch (e) {
      emitter(FirebaseError(errorMessage: e.toString()));
    }
  }

  Future<void> firebaseCodeSent(OtpSentEvent event, Emitter emitter) async {
    try {
      repository.firebaseCodeSent(
          otpCode: event.otpCode, firebaseAuth: _firebaseAuth);
      emitter(SignUpSuccess());
    } catch (e) {
      emitter(FirebaseError(errorMessage: e.toString()));
    }
  }
}
