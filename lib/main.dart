import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FarmingApp());
}

class FarmingApp extends StatelessWidget {
  const FarmingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farm Connect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // ---------- colour ----------
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF388E3C),
          brightness: Brightness.light,
        ),
        primaryColor: const Color(0xFF388E3C),

        // ---------- text ----------
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: const Color(0xFF212121),
            displayColor: const Color(0xFF212121),
          ),
        ),

        // ---------- surfaces ----------
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
        ),

        // ---------- app-bar ----------
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212121),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF212121)),
        ),

        // ---------- buttons ----------
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: .5),
          ),
        ),
      ),
      home: const _AnimatedLaunch(),
    );
  }
}

/* ----------------------------------------------------------
   A tiny “launch” screen that fades into the real LoginPage.
   ---------------------------------------------------------- */
class _AnimatedLaunch extends StatefulWidget {
  const _AnimatedLaunch();

  @override
  State<_AnimatedLaunch> createState() => _AnimatedLaunchState();
}

class _AnimatedLaunchState extends State<_AnimatedLaunch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _scale = Tween<double>(begin: .95, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const LoginPage(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE8F5E9),
                    Color(0xFFC8E6C9),
                    Color(0xFFA5D6A7),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // simple leaf logo
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.7),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 24,
                          color: Colors.black.withOpacity(.08),
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.eco,
                        size: 52, color: Color(0xFF388E3C)),
                  ),
                  const SizedBox(height: 24),
                  Text('Farm Connect',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      )),
                  const SizedBox(height: 8),
                  Text('Growing together',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.black.withOpacity(.6),
                          letterSpacing: .2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}