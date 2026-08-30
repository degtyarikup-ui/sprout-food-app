import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:convert';

@JS('window')
external JSObject get _window;

bool isInsideTelegram() {
  try {
    if (_window.has('Telegram')) {
      final tg = _window.getProperty('Telegram'.toJS);
      if (tg != null && (tg as JSObject).has('WebApp')) {
        return true;
      }
    }
  } catch (_) {}
  return false;
}

void initTelegramApp() {
  try {
    if (isInsideTelegram()) {
      final tg = _window.getProperty('Telegram'.toJS) as JSObject;
      final webApp = tg.getProperty('WebApp'.toJS) as JSObject;
      if (webApp.has('ready')) {
        webApp.callMethod('ready'.toJS);
      }
      if (webApp.has('expand')) {
        webApp.callMethod('expand'.toJS);
      }
      if (webApp.has('enableClosingConfirmation')) {
        webApp.callMethod('enableClosingConfirmation'.toJS);
      }
    }
  } catch (_) {}
}

String? getTelegramUserJson() {
  try {
    if (isInsideTelegram()) {
      final tg = _window.getProperty('Telegram'.toJS) as JSObject;
      final webApp = tg.getProperty('WebApp'.toJS) as JSObject;
      if (webApp.has('initDataUnsafe')) {
        final initData = webApp.getProperty('initDataUnsafe'.toJS) as JSObject;
        if (initData.has('user')) {
          final userObj = initData.getProperty('user'.toJS) as JSObject;
          final Map<String, dynamic> userMap = {};

          if (userObj.has('id')) {
            userMap['id'] = (userObj.getProperty('id'.toJS) as JSNumber).toDartInt;
          }
          if (userObj.has('first_name')) {
            userMap['first_name'] = (userObj.getProperty('first_name'.toJS) as JSString).toDart;
          }
          if (userObj.has('last_name')) {
            userMap['last_name'] = (userObj.getProperty('last_name'.toJS) as JSString).toDart;
          }
          if (userObj.has('username')) {
            userMap['username'] = (userObj.getProperty('username'.toJS) as JSString).toDart;
          }
          if (userObj.has('photo_url')) {
            userMap['photo_url'] = (userObj.getProperty('photo_url'.toJS) as JSString).toDart;
          }
          if (userObj.has('language_code')) {
            userMap['language_code'] = (userObj.getProperty('language_code'.toJS) as JSString).toDart;
          }

          // Check start_param from initData
          if (initData.has('start_param')) {
            userMap['start_param'] = (initData.getProperty('start_param'.toJS) as JSString).toDart;
          }

          return jsonEncode(userMap);
        }
      }
    }
  } catch (_) {}
  return null;
}

String? getTelegramStartParam() {
  try {
    if (isInsideTelegram()) {
      final tg = _window.getProperty('Telegram'.toJS) as JSObject;
      final webApp = tg.getProperty('WebApp'.toJS) as JSObject;
      if (webApp.has('initDataUnsafe')) {
        final initData = webApp.getProperty('initDataUnsafe'.toJS) as JSObject;
        if (initData.has('start_param')) {
          return (initData.getProperty('start_param'.toJS) as JSString).toDart;
        }
      }
    }
  } catch (_) {}
  return null;
}
