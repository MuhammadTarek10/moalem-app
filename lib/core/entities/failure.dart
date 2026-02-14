abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ClassLimitFailure extends Failure {
  const ClassLimitFailure([String message = 'Class limit reached'])
    : super(message);
}

class StudentLimitFailure extends Failure {
  const StudentLimitFailure([String message = 'Student limit reached'])
    : super(message);
}
