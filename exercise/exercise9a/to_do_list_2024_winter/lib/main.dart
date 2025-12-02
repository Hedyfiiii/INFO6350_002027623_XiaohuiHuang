


import 'package:flutter/material.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'auth/firebase_auth/firebase_user_provider.dart';
import 'auth/firebase_auth/auth_util.dart';




import 'backend/firebase/firebase_config.dart';
import 'flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/nav/nav.dart';
import 'package:flutter/foundation.dart';







void main() async {
    WidgetsFlutterBinding.ensureInitialized();

  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();
  await initFirebase();

  await FlutterFlowTheme.initialize();

  runApp(MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  

  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
    context.findAncestorStateOfType<_MyAppState>()!;

  
}



class _MyAppState extends State<MyApp> {
    
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late Stream<BaseAuthUser> userStream;


late AppStateNotifier _appStateNotifier;
late GoRouter _router;

final authUserSub = authenticatedUserStream.listen((_) {});


@override
void initState() {
  super.initState();
  
      _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
    userStream = toDoList2024WinterFirebaseUserStream()
      ..listen((user) {
        _appStateNotifier.update(user);

        // For web, force navigation after auth check
        if (kIsWeb && mounted) {
          Future.delayed(Duration(milliseconds: 100), () {
            if (!user.loggedIn && _router.routeInformationProvider.value.uri.path == '/') {
              _router.go('/login');
            } else if (user.loggedIn && _router.routeInformationProvider.value.uri.path == '/') {
              _router.go('/toDoList');
            }
          });
        }
      });
  jwtTokenStream.listen((_) {});
    Future.delayed(
      Duration(milliseconds: kIsWeb ? 2000 : 1000),
      () => _appStateNotifier.stopShowingSplashImage(),
    );
    
}

    @override
    void dispose() {
      authUserSub.cancel();
      
      super.dispose();
    }


  
  void setThemeMode(ThemeMode mode) => setState(() {
      _themeMode = mode;
      FlutterFlowTheme.saveThemeMode(mode);
    });

  

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ToDoList-2024-Winter',
      
      localizationsDelegates: [
        
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
        
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(brightness: Brightness.light,  useMaterial3: false,),
      darkTheme: ThemeData(brightness: Brightness.dark,  useMaterial3: false,),
      themeMode: _themeMode,
              routerConfig: _router,
      

      
    );
  }
}


