import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitapp/components/my_button.dart';
import 'package:fitapp/components/my_textfield.dart';
import 'package:fitapp/components/square_tile.dart';
import 'package:flutter/material.dart';
import 'package:email_validator_flutter/email_validator_flutter.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  bool isValidEmail(String email) {
    return EmailValidatorFlutter().validateEmail(email);
  }

  //methods
  void signUserIn() async {
    showDialog(
        context: context,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);

      print("errorcode $e.code");
      if (e.code == 'invalid-credential') {
        wrongEmailMessage(e.code);
      }
    }
  }

  void wrongEmailMessage(String errorCode) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Invalid Credential'),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 50,
              ),
              //logo
              const Icon(
                Icons.lock,
                size: 100,
              ),

              const SizedBox(
                height: 50,
              ),
              //welcome text

              Text(
                "Let start your fitness journey",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700]),
              ),
              const SizedBox(
                height: 25,
              ),

              //username textfield

              MyTextfield(
                controller: emailController,
                hintText: "Email",
                obscureText: false,
              ),

              const SizedBox(
                height: 25,
              ),
              //passward textfield

              MyTextfield(
                controller: passwordController,
                hintText: "password",
                obscureText: true,
              ),
              const SizedBox(
                height: 10,
              ),
              //forgot password
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "Forgot password?",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 25,
              ),
              //sign in button

              MyButton(
                //s
                onTap: () {
                  if (isValidEmail(emailController.text)) {
                    // signUserIn();
                    print("emailvalid true");
                  } else {
                    print("emailvalid false");
                  }
                },
                //e
                // onTap: signUserIn,
              ),

              const SizedBox(
                height: 50,
              ),
              //or contiune with
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        'Or continue with ',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 50,
              ),

              //google + apple sign in buttons

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SquareTile(imgPath: 'lib/images/google.png'),
                  const SizedBox(
                    width: 10,
                  ),
                  SquareTile(imgPath: 'lib/images/google.png'),
                ],
              ),
              const SizedBox(
                height: 50,
              ),
              //not a member? register now
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Not a member?',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Text(
                    'Register now',
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
