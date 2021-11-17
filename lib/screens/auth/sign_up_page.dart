import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';
import 'package:smuni/blocs/signup.dart';
import 'package:smuni/screens/auth/otp_page.dart';

class SignUpPage extends StatelessWidget {
  SignUpPage({Key? key}) : super(key: key);
  static const String routeName = '/signuppage';
  final _formKey = GlobalKey<FormState>();
  bool _loadingInidicator = false;
  String _name = '';
  String _email = '';
  static const String plus = '+';
  String _phone = '';
  String _username = '';
  String _password = '';

  static Route route() => MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) => SignUpPage());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                'SIGN UP TO KAMASIYO!',
                textScaleFactor: 2,
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    /*
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TextFormField(
                        onChanged: (value) => _name = value,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Who should we call you?',
                            helperText: '*Your name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Your name field can\'t be empty';
                          }
                        },
                      ),
                    ),

                     */
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TextFormField(
                        onChanged: (value) => _email = value,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'What email of yours should we use?',
                          helperText: '* Email',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email can\'t be empty';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Invalid email';
                          }
                          if (value.contains(' ')) {
                            return 'Email can\'t contain space';
                          }
                        },
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.all(4),
                        child: TextFormField(
                          onChanged: (value) => _phone = value,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Your phone number?',
                              prefix: Text('+ '),
                              helperText: '* Phone number with country code'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Phone number can\'t be empty';
                            }
                            if (value.contains(' ')) {
                              return 'Phone number can\'t contain space';
                            }
                          },
                        )),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TextFormField(
                        onChanged: (value) => _username = value,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Username',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Username can\'t be empty';
                          }
                          if (value.contains(' ')) {
                            return 'Username can\'t contain space';
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TextFormField(
                        onChanged: (value) => _password = value,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Your password',
                            helperText: '* Password'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password can\'t be empty';
                          }
                          if (value.contains(' ')) {
                            return 'Password can\'t contain space';
                          }
                          if (value.length < 6) {
                            return 'The inserted password length is too low';
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              _loadingInidicator
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          minimumSize: Size(200, 40),
                          shape: BeveledRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.elliptical(8, 8)))),
                      onPressed: () {
                        //TODO: Uncomment the if condition below

                        if (_formKey.currentState != null &&
                            _formKey.currentState!.validate()) {
                          context
                              .read<SignUpBloc>()
                              .add(AuthenticatePhoneNo(phoneNo: plus + _phone));

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => OtpVerificationPage(
                                      name: _name,
                                      username: _username,
                                      email: _email,
                                      password: _password,
                                      phone: plus + _phone)));
                        }
                      },
                      child: Text('Next'))
            ],
          ),
        ),
      ),
    );
  }
}
