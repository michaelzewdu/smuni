import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:smuni/blocs/signup.dart';
import 'package:smuni/constants.dart';
import 'package:smuni/screens/auth/sign_in_page.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage(
      {Key? key,
      required this.name,
      required this.username,
      required this.email,
      required this.password,
      required this.phone})
      : super(key: key);

  static const routeName = '/otpPage';
  final String name;
  final String username;
  final String email;
  final String password;
  final String phone;

  /*
  static Route route() => MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) => OtpVerificationPage());

   */

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _loadingIndicator = false;
  String smsCode = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.black,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(
                  Icons.message,
                  color: semuni700,
                  size: 50,
                ),
                Text(
                  'We have sent a verification code to: ${widget.phone} ',
                  textScaleFactor: 1.5,
                ),
                Form(
                  key: _formKey,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 30),
                      child: PinCodeTextField(
                        appContext: context,
                        pastedTextStyle: TextStyle(
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                        length: 6,
                        obscureText: true,
                        obscuringCharacter: '*',
                        // obscuringWidget: FlutterLogo(            size: 24,           ),
                        blinkWhenObscuring: true,
                        animationType: AnimationType.fade,
                        validator: (v) {
                          if (v!.length < 3) {
                            return "Yes, feed me more!";
                          } else {
                            return null;
                          }
                        },
                        pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(5),
                            fieldHeight: 50,
                            fieldWidth: 40,
                            activeFillColor: Colors.white,
                            activeColor: semuni100,
                            inactiveColor: semuni500,
                            inactiveFillColor: semuni500,
                            selectedFillColor: semuni100),
                        cursorColor: Colors.black,
                        animationDuration: Duration(milliseconds: 300),
                        enableActiveFill: true,
                        //errorAnimationController: errorController,
                        //controller: textEditingController,
                        keyboardType: TextInputType.number,
                        boxShadows: [
                          BoxShadow(
                            offset: Offset(0, 1),
                            color: Colors.black12,
                            blurRadius: 10,
                          )
                        ],
                        onCompleted: (thisSmsCode) {
                          setState(() {
                            _loadingIndicator = true;
                          });
                          context
                              .read<SignUpBloc>()
                              .add(OtpSentEvent(thisSmsCode));
                        },
                        // onTap: () {
                        //   print("Pressed");
                        // },
                        onChanged: (value) {
                          print(value);
                          setState(() {
                            smsCode = value;
                          });
                        },
                        beforeTextPaste: (text) {
                          print("Allowing to paste $text");
                          //if you return true then it will show the paste confirmation dialog. Otherwise if false, then nothing will happen.
                          //but you can show anything you want here, like your pop up saying wrong paste format or etc
                          return true;
                        },
                      )),
                ),
                _loadingIndicator ? CircularProgressIndicator() : Container(),
                BlocConsumer<SignUpBloc, SignUpBlocState>(
                  listener: (context, currentState) async {
                    if (currentState is PhoneNumberVerified) {
                      final snackBar = SnackBar(
                        content: (Text('${currentState.message}')),
                        duration: Duration(seconds: 2),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      context.read<SignUpBloc>().add(SignUpToBackEndEvent(
                          // name: _name,
                          username: widget.username,
                          email: widget.email,
                          password: widget.password,
                          phone: widget.phone));
                    }
                    if (currentState is SignUpSuccess) {
                      setState(() {
                        _loadingIndicator = false;
                      });
                      Navigator.pushNamedAndRemoveUntil(
                          context,
                          SignInPage.routeName,
                          ModalRoute.withName(SignInPage.routeName));
                    }
                    if (currentState is FirebaseError) {
                      if (currentState.errorMessage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('An error occurred'),
                          duration: Duration(seconds: 3),
                        ));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(currentState.errorMessage!),
                          duration: Duration(seconds: 3),
                        ));
                      }
                    }
                    if (currentState is SignUpFailure) {
                      var snackBar = SnackBar(
                        content: Text('${currentState.failureMessage}'),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    }
                  },
                  builder: (context, currentState) {
                    return Container();
                  },
                ),
              ],
            ),
          ),
        ));
  }
}
