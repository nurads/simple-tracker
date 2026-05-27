import 'package:gisila/gisila.dart' hide Query;
import 'package:gisila_orm/gisila.dart';
import 'package:simple_tracker/models/models.dart';
import 'package:simple_tracker/utils/jwt.dart';

/// Business logic for the `/auth` endpoints. Controllers stay thin and
/// forward to this service; persistence and JWT minting live here.
class AuthService extends Service {
  Database get _database => db<Database>();

  /// Registers a new unverified user. Throws [Conflict] if an account
  /// with the email already exists and is verified. If the account exists
  /// but is not yet verified, the call is a no-op (allowing re-send).
  Future<void> register({
    required String email,
    required String password,
  }) async {
    final existing = await Query<User>(UserTable.metadata)
        .where(UserTable.email.eq(email))
        .first(_database.context());

    if (existing != null && existing.isEmailVerified == true) {
      throw Conflict(
        'An account with this email already exists.',
        code: 'email_taken',
      );
    }

    if (existing == null) {
      await Query<User>(UserTable.metadata).insert({
        'email': email,
        'password': password,
        'isActive': true,
        'isEmailVerified': false,
        'isPhoneVerified': false,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      }).one(_database.context());
    }

    // In a real application, send a verification email here.
  }

  /// Verifies credentials and returns the matched user + a fresh JWT.
  /// Throws [Unauthorized] when the credentials don't match and
  /// [Forbidden] when the account is inactive.
  Future<({User user, String accessToken})> login({
    required String email,
    required String password,
  }) async {
    final user = await Query<User>(UserTable.metadata)
        .where(UserTable.email.eq(email))
        .first(_database.context());

    if (user == null || user.password != password) {
      throw Unauthorized('Invalid email or password.');
    }
    if (user.isActive == false) {
      throw Forbidden('This account is inactive.');
    }

    return (user: user, accessToken: JWTAuth.sign(user));
  }

  /// Rotates the password for [current]. Throws [BadRequest] if the
  /// supplied [oldPassword] does not match.
  Future<void> changePassword(
    User current, {
    required String oldPassword,
    required String newPassword,
  }) async {
    if (current.password != oldPassword) {
      throw BadRequest(
        'Old password is incorrect.',
        code: 'invalid_old_password',
      );
    }

    await Query<User>(UserTable.metadata)
        .where(UserTable.id.eq(current.id!))
        .update({'password': newPassword}).run(_database.context());
  }
}
