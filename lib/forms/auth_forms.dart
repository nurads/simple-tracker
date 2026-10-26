import 'package:gisila/gisila.dart';

String? _strongPassword(String value) {
  if (value.length < 8) {
    return 'Password must be at least 8 characters long.';
  }
  return null;
}

/// `POST /auth/register` body.
class RegisterForm extends Form {
  final email = EmailField(name: 'email', required: true);
  final password = StringField(
    name: 'password',
    required: true,
    validators: <FieldValidator<String>>[_strongPassword],
  );

  @override
  List<FormField<Object?>> collectFields() => <FormField<Object?>>[
        email,
        password,
      ];
}

/// `POST /auth/login` body.
class LoginForm extends Form {
  final email = EmailField(name: 'email', required: true);
  final password = StringField(name: 'password', required: true);

  @override
  List<FormField<Object?>> collectFields() =>
      <FormField<Object?>>[email, password];
}

/// `POST /auth/change-password` body.
class ChangePasswordForm extends Form {
  final oldPassword = StringField(name: 'oldPassword', required: true);
  final newPassword = StringField(
    name: 'newPassword',
    required: true,
    validators: <FieldValidator<String>>[_strongPassword],
  );

  @override
  List<FormField<Object?>> collectFields() =>
      <FormField<Object?>>[oldPassword, newPassword];
}
