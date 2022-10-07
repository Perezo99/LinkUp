import 'dart:async';
import 'package:flutter/material.dart';
import 'package:linkup/src/widgets/header.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _formKey = GlobalKey<FormState>();
  String? username;

  submit() {
    final form = _formKey.currentState!;
    SnackBar snackBar = SnackBar(content: Text('Welcome $username'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    Timer(Duration(seconds: 2), () {
      if (form.validate()) {
        form.save();
        Navigator.pop(context, username);
      }
    });
  }

  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      appBar: header(titleText: 'Set Up Your Profile', removeBackButton: true),
      body: ListView(
        children: [
          Container(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 25.0),
                  child: Center(
                    child: Text(
                      'Create A Username',
                      style: TextStyle(fontSize: 25.0),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Container(
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.always,
                      child: TextFormField(
                        validator: (val) {
                          if (val!.trim().length < 3 || val.isEmpty) {
                            return 'Username is too short';
                          } else if (val.trim().length > 12) {
                            return 'Username is too long';
                          } else {
                            return null;
                          }
                        },
                        onSaved: (val) => username = val!,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Username',
                          labelStyle: TextStyle(fontSize: 15.0),
                          hintText: 'Must At least Be 3 characters',
                        ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: submit,
                  child: Container(
                    height: 50.0,
                    width: 350.0,
                    decoration: BoxDecoration(
                        color: Colors.red[900],
                        borderRadius: BorderRadius.circular(7.0)),
                    child: Center(
                      child: Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
