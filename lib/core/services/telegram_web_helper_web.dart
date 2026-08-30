import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:convert';

@JS('window')
external JSObject get _window;

@JS('JSON.stringify')
external JSString _jsJsonStringify(JSAny? obj);

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

      // 1. Try initDataUnsafe.user directly via JSON.stringify
      if (webApp.has('initDataUnsafe')) {
        final initDataUnsafe = webApp.getProperty('initDataUnsafe'.toJS) as JSObject;
        if (initDataUnsafe.has('user')) {
          final userObj = initDataUnsafe.getProperty('user'.toJS);
          if (userObj != null) {
            final jsonStr = _jsJsonStringify(userObj).toDart;
            if (jsonStr.isNotEmpty && jsonStr != 'null' && jsonStr != '{}') {
              try {
                final map = jsonDecode(jsonStr) as Map<String, dynamic>;
                if (initDataUnsafe.has('start_param')) {
                  final sp = (initDataUnsafe.getProperty('start_param'.toJS) as JSString).toDart;
                  map['start_param'] = sp;
                }
                return jsonEncode(map);
              } catch (_) {}
              return jsonStr;
            }
          }
        }
      }

      // 2. Try raw initData string
      if (webApp.has('initData')) {
        final rawInitData = (webApp.getProperty('initData'.toJS) as JSString).toDart;
        if (rawInitData.isNotEmpty) {
          final uri = Uri.tryParse('http://localhost/?$rawInitData');
          if (uri != null && uri.queryParameters.containsKey('user')) {
            return uri.queryParameters['user'];
          }
        }
      }
    }

    // 3. Try URL hash parameters (#tgWebAppData=...)
    if (_window.has('location')) {
      final loc = _window.getProperty('location'.toJS) as JSObject;
      if (loc.has('hash')) {
        final hash = (loc.getProperty('hash'.toJS) as JSString).toDart;
        if (hash.contains('tgWebAppData=')) {
          final rawData = hash.split('tgWebAppData=').last.split('&').first;
          final decoded = Uri.decodeComponent(rawData);
          final uri = Uri.tryParse('http://localhost/?$decoded');
          if (uri != null && uri.queryParameters.containsKey('user')) {
            return uri.queryParameters['user'];
          }
        }
      }
    }
  } catch (_) {}
  return null;
}

String? getTelegramStartParam() {
  try {
    // 1. From Telegram.WebApp.initDataUnsafe.start_param
    if (isInsideTelegram()) {
      final tg = _window.getProperty('Telegram'.toJS) as JSObject;
      final webApp = tg.getProperty('WebApp'.toJS) as JSObject;
      if (webApp.has('initDataUnsafe')) {
        final initData = webApp.getProperty('initDataUnsafe'.toJS) as JSObject;
        if (initData.has('start_param')) {
          final param = (initData.getProperty('start_param'.toJS) as JSString).toDart;
          if (param.isNotEmpty) return param;
        }
      }
      if (webApp.has('initData')) {
        final rawInitData = (webApp.getProperty('initData'.toJS) as JSString).toDart;
        if (rawInitData.isNotEmpty) {
          final uri = Uri.tryParse('http://localhost/?$rawInitData');
          if (uri != null && uri.queryParameters.containsKey('start_param')) {
            return uri.queryParameters['start_param'];
          }
        }
      }
    }

    // 2. From URL Query search params (?startapp=join_... or ?tgWebAppStartParam=join_...)
    if (_window.has('location')) {
      final loc = _window.getProperty('location'.toJS) as JSObject;
      if (loc.has('search')) {
        final search = (loc.getProperty('search'.toJS) as JSString).toDart;
        final uri = Uri.tryParse('http://localhost/$search');
        if (uri != null) {
          if (uri.queryParameters.containsKey('startapp')) {
            return uri.queryParameters['startapp'];
          }
          if (uri.queryParameters.containsKey('tgWebAppStartParam')) {
            return uri.queryParameters['tgWebAppStartParam'];
          }
        }
      }
      // 3. From URL Hash
      if (loc.has('hash')) {
        final hash = (loc.getProperty('hash'.toJS) as JSString).toDart;
        if (hash.contains('start_param=')) {
          final part = hash.split('start_param=').last.split('&').first;
          if (part.isNotEmpty) return Uri.decodeComponent(part);
        }
        if (hash.contains('tgWebAppStartParam=')) {
          final part = hash.split('tgWebAppStartParam=').last.split('&').first;
          if (part.isNotEmpty) return Uri.decodeComponent(part);
        }
      }
    }
  } catch (_) {}
  return null;
}

String? getTelegramPhotoParam() {
  try {
    if (_window.has('location')) {
      final loc = _window.getProperty('location'.toJS) as JSObject;
      if (loc.has('search')) {
        final search = (loc.getProperty('search'.toJS) as JSString).toDart;
        final uri = Uri.tryParse('http://localhost/$search');
        if (uri != null && uri.queryParameters.containsKey('tg_photo')) {
          return uri.queryParameters['tg_photo'];
        }
      }
      if (loc.has('hash')) {
        final hash = (loc.getProperty('hash'.toJS) as JSString).toDart;
        if (hash.contains('tg_photo=')) {
          final part = hash.split('tg_photo=').last.split('&').first;
          if (part.isNotEmpty) return Uri.decodeComponent(part);
        }
      }
    }
  } catch (_) {}
  return null;
}

String? getTelegramUsernameParam() {
  try {
    if (_window.has('location')) {
      final loc = _window.getProperty('location'.toJS) as JSObject;
      if (loc.has('search')) {
        final search = (loc.getProperty('search'.toJS) as JSString).toDart;
        final uri = Uri.tryParse('http://localhost/$search');
        if (uri != null && uri.queryParameters.containsKey('tg_username')) {
          return uri.queryParameters['tg_username'];
        }
      }
    }
  } catch (_) {}
  return null;
}
