import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import './login_page.dart';

class FirstPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(height: 150),
                      // logo
                      Image.asset(
                        'assets/images/cameron_logo_with_title.png',
                        width: 305,
                        height: 305,
                      ),

                      const Spacer(),

                      Padding(
                        padding: const EdgeInsets.only(bottom: 50),
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to the next page
                            context.go('/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(
                              255,
                              0,
                              0,
                              0,
                            ), // background color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(41),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 22,
                              horizontal: 60,
                            ),
                          ),
                          child: Text(
                            'Login',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
