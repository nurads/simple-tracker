class UserRegistrationRequest {
  final String email;
  final String password;

  UserRegistrationRequest({
    required this.email,
    required this.password,
  });
}

class UserLoginRequest {
  final String email;
  final String password;

  UserLoginRequest({
    required this.email,
    required this.password,
  });
}
