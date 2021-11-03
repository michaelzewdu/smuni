import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:smuni/blocs/blocs.dart';
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

  var _method = SignInMethod.username;
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
            title:
                _awaitingOp ? const Text("Loading...") : const Text("Sign In"),
          ),
          body: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
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

                if (_method == SignInMethod.username)
                  TextFormField(
                    enabled: !_awaitingOp,
                    initialValue: _username,
                    onSaved: (value) => setState(() => _username = value!),
                    validator: (value) {
                      // TODO: username validation
                      if (value == null || value.isEmpty) {
                        return "Username can't be empty";
                      }
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: "Username",
                      helperText: "Username",
                    ),
                  ),
                if (_method == SignInMethod.email)
                  TextFormField(
                    enabled: !_awaitingOp,
                    initialValue: _email,
                    onSaved: (value) => setState(() => _email = value!),
                    validator: (value) {
                      // TODO: email validation
                      if (value == null || value.isEmpty) {
                        return "Email can't be empty";
                      }
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: "Email",
                      helperText: "Email",
                    ),
                  ),
                if (_method == SignInMethod.phoneNumber)
                  TextFormField(
                    enabled: !_awaitingOp,
                    initialValue: _phoneNumber,
                    onSaved: (value) => setState(() => _phoneNumber = value!),
                    validator: (value) {
                      // TODO: phoneNumber validation
                      if (value == null || value.isEmpty) {
                        return "Phone Number can't be empty";
                      }
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: "Phone Number",
                      helperText: "Phone Numbe",
                    ),
                  ),
                TextFormField(
                  enabled: !_awaitingOp,
                  initialValue: _password,
                  onSaved: (value) => setState(() => _password = value!),
                  validator: (value) {
                    // TODO: password validation
                    if (value == null || value.isEmpty) {
                      return "Password can't be empty";
                    }
                  },
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: "Password",
                    helperText: "Password",
                  ),
                ),
                !_awaitingOp
                    ? ElevatedButton(
                        onPressed: () {
                          final form = _formKey.currentState;
                          if (form != null && form.validate()) {
                            form.save();
                            setState(() => _awaitingOp = true);
                            context.read<AuthBloc>().add(
                                  SignIn(
                                    method: _method,
                                    identifier: _method == SignInMethod.email
                                        ? _email!
                                        : _method == SignInMethod.username
                                            ? _username!
                                            : _method ==
                                                    SignInMethod.phoneNumber
                                                ? _phoneNumber!
                                                : throw Exception(
                                                    "unhandled type"),
                                    password: _password!,
                                    onSuccess: () {
                                      setState(() => _awaitingOp = false);
                                      context.read<UserBloc>().add(LoadUser());
                                    },
                                    onError: (err) {
                                      setState(() => _awaitingOp = false);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: err is ConnectionException
                                              ? Text('Connection Failed')
                                              : err is CredentialsRejected
                                                  ? Text('Credentials Rejected')
                                                  : Text(
                                                      'Unknown Error Occured'),
                                          behavior: SnackBarBehavior.floating,
                                          duration: Duration(seconds: 2),
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
                Spacer(),
                // TODO
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        SmuniHomeScreen.routeName,
                        (r) => false,
                      ),
                      child: const Text("Skip"),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text("Sign Up"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      );
}
