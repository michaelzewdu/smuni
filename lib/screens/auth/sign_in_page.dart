import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smuni/blocs/blocs.dart';
import 'package:smuni/screens/auth/sign_up_page.dart';
import 'package:smuni/screens/home_screen.dart';
import 'package:smuni/utilities.dart';

class SignInPage extends StatefulWidget {
  static const String routeName = "/signIn";

  const SignInPage({Key? key}) : super(key: key);

  static Route route() => MaterialPageRoute(
        settings: const RouteSettings(name: routeName),
        builder: (context) => SignInPage(),
      );
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();

  var _method = SignInMethod.email;
  String? _username;
  String? _email;
  String? _phoneNumber;
  String? _password;

  bool _awaitingOp = false;

  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthBlocState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              SmuniHomeScreen.routeName,
              (_) => false,
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            foregroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            actions: [
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  SmuniHomeScreen.routeName,
                  (r) => false,
                ),
                child: const Text("Skip"),
              ),
            ],
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Text(
                      'KamasiYo',
                      textScaleFactor: 3,
                    ),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            enabled: !_awaitingOp,
                            onSaved: (value) => setState(() {
                              if (value!.contains('@')) {
                                _method = SignInMethod.email;
                                _email = value;
                              } else if (RegExp(r'^[0-9+]+$').hasMatch(value)) {
                                _method = SignInMethod.phoneNumber;
                                _phoneNumber = value;
                              } else {
                                _method = SignInMethod.username;
                                _username = value;
                              }
                            }),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Identifier can't be empty";
                              }
                            },
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: "Email, phone or username",
                              // helperText: "Username",
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            obscureText: true,
                            enabled: !_awaitingOp,
                            initialValue: _password,
                            onSaved: (value) =>
                                setState(() => _password = value!),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Password can't be empty";
                              }
                              if (value.length < 8) return "Password too short";
                            },
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: "Password",
                              // helperText: "Password",
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        !_awaitingOp
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    shape: BeveledRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.elliptical(8, 8))),
                                    minimumSize: Size(200, 40)),
                                onPressed: () {
                                  final form = _formKey.currentState;
                                  if (form != null && form.validate()) {
                                    form.save();
                                    setState(() => _awaitingOp = true);
                                    context.read<AuthBloc>().add(
                                          SignIn(
                                            method: _method,
                                            identifier: _method ==
                                                    SignInMethod.email
                                                ? _email!
                                                : _method ==
                                                        SignInMethod.username
                                                    ? _username!
                                                    : _method ==
                                                            SignInMethod
                                                                .phoneNumber
                                                        ? _phoneNumber!
                                                        : throw Exception(
                                                            "unhandled type"),
                                            password: _password!,
                                            onSuccess: () {
                                              setState(
                                                  () => _awaitingOp = false);
                                              context
                                                  .read<UserBloc>()
                                                  .add(LoadUser());
                                              context
                                                  .read<PreferencesBloc>()
                                                  .add(LoadPreferences());
                                            },
                                            onError: (err) {
                                              setState(
                                                  () => _awaitingOp = false);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: err
                                                          is ConnectionException
                                                      ? Text(
                                                          'Connection Failed',
                                                        )
                                                      : err is CredentialsRejected
                                                          ? Text(
                                                              'Credentials Rejected',
                                                            )
                                                          : Text(
                                                              'Unknown Error Occurred',
                                                            ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  duration:
                                                      Duration(seconds: 2),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                  }
                                },
                                child: const Text("Sign In"),
                              )
                            : const CircularProgressIndicator(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text('Don\'t have an account? '),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                    context, SignUpPage.routeName);
                              },
                              child: const Text("Sign Up"),
                            ),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
