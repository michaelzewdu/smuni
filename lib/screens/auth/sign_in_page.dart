import 'package:firebase_core/firebase_core.dart';
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
  String? _userIdentity;
  String? _username;
  String? _email;
  String? _phoneNumber;
  String? _password;

  bool _awaitingOp = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _awaitingOp = true;

    initializeFirebase();
    _awaitingOp = false;
    setState(() {});
  }

  void initializeFirebase() async {
    await Firebase.initializeApp();
  }

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
                    /*
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text("Sign In Method"),

                        DropdownButton(
                          value: _method,
                          onChanged: (v) =>
                              setState(() => _method = v as SignInMethod),
                          items: [
                            ...<List<dynamic>>[
                              [SignInMethod.username, "Username"],
                              [SignInMethod.email, "Email"],
                              [SignInMethod.phoneNumber, "Phone Number"],
                            ].map(
                              (e) => DropdownMenuItem<SignInMethod>(
                                value: e[0],
                                child: Text(e[1]),
                                // groupValue: _method,
                              ),
                            )
                          ],
                        ),
                      ],
                    ),

                     */
                    Text(
                      'KamasiYo',
                      textScaleFactor: 3,
                    ),
                    // if (_method == SignInMethod.username)

                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            enabled: !_awaitingOp,
                            initialValue: _userIdentity,
                            onSaved: (value) {
                              setState(() => _userIdentity = value!);
                            },
                            validator: (value) {
                              // TODO: username validation
                              if (value == null || value.isEmpty) {
                                return "Username can't be empty";
                              }
                              if (value.contains('@')) {
                                print('This is an email');
                                _method = SignInMethod.email;
                                _email = _userIdentity;
                              } else if (RegExp(r'^[0-9]+$').hasMatch(value) ||
                                  value.contains('+')) {
                                print('This is a phone number');
                                _method = SignInMethod.phoneNumber;
                                _phoneNumber = _userIdentity;
                              } else {
                                print('This is a username');
                                _method = SignInMethod.username;
                                _username = _userIdentity;
                              }
                              /*
                                if (RegExp(
                                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                    .hasMatch(value)) {
                                  print('it is an email');
                                  // _email = value;
                                }
                                if (RegExp(r"/^[A-Za-z0-9]+(?:[_-][A-Za-z0-9]+)*$/")
                                    .hasMatch(value)) {
                                  print('This is a username');
                                }

                                 */
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
                            enabled: !_awaitingOp,
                            initialValue: _password,
                            onSaved: (value) =>
                                setState(() => _password = value!),
                            validator: (value) {
                              // TODO: password validation
                              if (value == null || value.isEmpty) {
                                return "Password can't be empty";
                              }
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

                    // Spacer(),
                    // TODO
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
                                                          'Connection Failed')
                                                      : err
                                                              is CredentialsRejected
                                                          ? Text(
                                                              'Credentials Rejected')
                                                          : Text(
                                                              'Unknown Error Occurred'),
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
