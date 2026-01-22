import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatefulWidget {
  final void Function(BuildContext) onContinue;
  //final bool isFirstTime;
  const WelcomeScreen({super.key, required this.onContinue,/* required this.isFirstTime*/});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final Color accentColor = const Color(0xffFF7043); // Orange-Red, strong but not harsh
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 1,
            child: Image.asset(
              'assets/welcome_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(color: Colors.white.withValues(alpha: 0.20)),
          Center(
            child: 
                 Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'EazySave',
                        style: GoogleFonts.rubikPuddles(
                          
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                          letterSpacing: 2,
                          shadows: const [
                            Shadow(
                              offset: Offset(0, 3),
                              blurRadius: 6,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 1),
                      SizedBox(
                        height: 120,
                        width: 120,
                        child: Image.asset('assets/cart_icon.png'),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Always on time for big savings',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.black87),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        ),
                        onPressed: () => widget.onContinue(context),
                        child: const Text('save now', style: TextStyle(fontSize: 20, color: Colors.white)),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {},
                            child: const Text('Terms', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ),
                          const Text(' | ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Privacy', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
