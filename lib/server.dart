import 'package:gisila_doc/gisila_doc.dart';
import 'package:gisila_orm/gisila.dart' hide PostgresErrorMapper;
import 'package:simple_tracker/admin.dart';
import 'package:simple_tracker/config.dart';
import 'package:simple_tracker/endpoints/auth.dart';
import 'package:simple_tracker/endpoints/users.dart';
import 'package:simple_tracker/infra/database_provider.dart';
import 'package:simple_tracker/infra/jwt_authenticator.dart';
import 'package:simple_tracker/infra/postgres_error_mapper.dart';
import 'package:simple_tracker/services/auth_service.dart';
import 'package:simple_tracker/services/users_service.dart';

/// Build the top-level Shelf [Handler] for simple-tracker.
///
/// `init()` must have been called first (so `databaseConfig` is
/// populated). The returned [Handler] is the full gisila pipeline:
///
///  • Per-process [Database] pool, exposed as `ctx.db<Database>()`
///    inside every controller / service via [GisilaOrmDatabaseProvider].
///  • JWT [Authenticator] that hydrates the active [User] into
///    `ctx.principal!.claims['user']` and tags `staff` as a role.
///  • [PostgresDbErrorMapper] that turns constraint violations into
///    `409`/`400` JSON responses.
///  • Request-id, structured logging, CORS, body-size cap, request
///    timeout and a 300 req/min default rate limit.
///  • The annotated `AuthApi` / `UsersApi` controllers.
///  • GisilaStudio admin panel at `/studio`.
///  • OpenAPI spec + Swagger UI + ReDoc at `/openapi.json`, `/docs`, `/redoc`.
Future<Handler> application() async {
  final spec = OpenApiSpec(
    info: const ApiInfo(
      title: 'Simple Tracker API',
      version: '1.0.0',
      description: 'Generated with the Gisila dart-backend-template.',
    ),
  );

  final database = await Database.connect(databaseConfig);

  final app = GisilaApp(
    config: AppConfig(
      cors: const CorsConfig(),
      requestTimeout: const Duration(seconds: 30),
      maxRequestBodyBytes: 10 * 1024 * 1024, // 10 MB
      serverHeader: 'simple-tracker/1.0',
      poweredByHeader: false,
      authenticator: JwtAuthenticator(database: database),
      database: GisilaOrmDatabaseProvider(database),
      dbErrorMapper: const PostgresDbErrorMapper(),
      defaultRouteConfig: const RouteConfig(
        rateLimit: RateLimitConfig(requestsPerMinute: 300),
      ),
    ),
  );

  app.registerService<AuthService>(AuthService.new);
  app.registerService<UsersService>(UsersService.new);

  app.registerController(
    attacher: (app, router, {prefix = ''}) {
      AuthApi().attachToApp(app, router, spec, prefix: prefix);
      UsersApi().attachToApp(app, router, spec, prefix: prefix);

      router.mount('/studio', adminHandler());
      router.mount('/', docsHandler(spec));
    },
  );

  return app.buildHandler();
}
