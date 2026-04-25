import 'package:go_router/go_router.dart';

import '../../features/example/presentation/example_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ExampleScreen(),
    ),
  ],
);
