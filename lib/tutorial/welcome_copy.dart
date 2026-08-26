/// Product copy for the one-time device-local Welcome surface.
///
/// Keeping it separate from widget geometry makes future localization or
/// account actions possible without coupling them to the first-run policy.
abstract final class WelcomeCopy {
  static const routeLabel = 'Добро пожаловать в RPG To-Do';
  static const title = 'Добро пожаловать';
  static const subtitle = 'Преврати намерение в понятный путь';
  static const body =
      'Не нужно планировать всё сразу. Начни с одного направления — приложение поможет увидеть следующий шаг.';
  static const beginSemantics = 'Начать работу в приложении';
  static const beginLabel = 'Начать';
  static const localDataNote = 'Данные хранятся на этом устройстве';
}
