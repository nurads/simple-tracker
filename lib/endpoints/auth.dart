import 'dart:async';

import 'package:gisila_doc/gisila_doc.dart';
import 'package:simple_tracker/forms/auth_forms.dart';
import 'package:simple_tracker/models/dto/dto.dart';
import 'package:simple_tracker/models/models.dart';
import 'package:simple_tracker/services/auth_service.dart';

part 'auth.g.dart';

@Controller('/auth', ['Auth'])
class AuthApi {
  @Post(
    '/register',
    summary: 'Register a new account',
    body:
        BodyDoc(UserRegistrationRequest, description: 'User registration data'),
    config: RouteConfig(
      rateLimit: RateLimitConfig(requestsPerMinute: 30),
    ),
  )
  @Public()
  @ApiResponse(201, bodyType: UserRegistrationResponse)
  Future<Map<String, Object?>> register(
    RegisterForm form,
    AuthService auth,
  ) async {
    await auth.register(
      email: form.email.value!,
      password: form.password.value!,
    );
    return <String, Object?>{
      'detail':
          'Verification email sent. Please verify your email to activate your account.',
    };
  }

  @Post(
    '/login',
    summary: 'Login with email and password',
    body: BodyDoc(UserLoginRequest, description: 'The login credentials'),
    config: RouteConfig(
      rateLimit: RateLimitConfig(requestsPerMinute: 60),
    ),
  )
  @Public()
  Future<Map<String, Object?>> login(LoginForm form, AuthService auth) async {
    final result = await auth.login(
      email: form.email.value!,
      password: form.password.value!,
    );
    return <String, Object?>{
      'user': result.user.toJson(exclude: ['password']),
      'access': result.accessToken,
    };
  }

  @Get('/me', summary: 'Get the authenticated user profile')
  @RequireAuth()
  Future<Map<String, Object?>> me(RequestContext ctx) async {
    final user = ctx.principal!.claims['user'] as User;
    return user.toJson(exclude: ['password']);
  }

  @Post('/change-password', summary: 'Change password')
  @RequireAuth()
  Future<Map<String, Object?>> changePassword(
    ChangePasswordForm form,
    AuthService auth,
    RequestContext ctx,
  ) async {
    final user = ctx.principal!.claims['user'] as User;
    await auth.changePassword(
      user,
      oldPassword: form.oldPassword.value!,
      newPassword: form.newPassword.value!,
    );
    return <String, Object?>{'detail': 'Password changed successfully.'};
  }
}
