import 'dart:convert';
import 'dart:developer';

import 'package:dart_style/dart_style.dart';
import 'package:dartx/dartx.dart';
import 'package:intl/intl.dart';

import 'models/config.dart';
import 'models/dart_object.dart';
import 'models/dart_property.dart';
import 'utils/dart_helper.dart';
import 'utils/my_string_buffer.dart';

class MainController {
  static MainController? _instance;

  MainController._();

  static MainController get instance {
    _instance ??= MainController._();
    return _instance!;
  }

  set text(String value) {
    if (value.isNotEmpty) {
      _text = value;
    }
  }

  String _text = '';

  String get text => _text;
  String _errorMessage = '';

  DartObject? dartObject;

  Set<DartProperty> allProperties = <DartProperty>{};
  Set<DartObject> allObjects = <DartObject>{};
  Set<DartObject> printedObjects = <DartObject>{};

  Future<void> formatJsonAndCreateDartObject({required String rootName}) async {
    allProperties.clear();
    allObjects.clear();
    if (text.isNullOrEmpty) {
      return;
    }

    log('🔄Loading Format JSON...');

    String inputText = text;
    try {
      inputText = text.replaceAll('.0', '.1');

      final dynamic jsonData = jsonDecode(inputText);

      final DartObject? extendedObject = createDartObject(
        jsonData: jsonData,
        rootName: rootName,
      );

      if (extendedObject == null) {
        _errorMessage = 'Illegal JSON format';

        logError(_errorMessage);
        throw _errorMessage;
      }

      dartObject = extendedObject;
      if (ConfigSetting().nullsafety &&
          ConfigSetting().nullable &&
          !ConfigSetting().smartNullable) {
        updateNullable(true);
      }

      final String? formatJsonString = formatJson(jsonData);

      if (formatJsonString != null) {
        _text = formatJsonString;
      }
    } catch (error, stackTrace) {
      handleError(error, stackTrace);
      rethrow;
    }
  }

  String? generateDart() {
    // allProperties.clear();
    // allObjects.clear();
    printedObjects.clear();

    if (dartObject != null) {
      final DartObject? errorObject = allObjects.firstOrNullWhere(
          (DartObject element) =>
              element.classError.isNotEmpty ||
              element.propertyError.isNotEmpty);
      if (errorObject != null) {
        _errorMessage =
            '${errorObject.classError.join('\n')}\n${errorObject.propertyError.join('\n')}';

        logError(_errorMessage);
        throw _errorMessage;
      }

      final DartProperty? errorProperty = allProperties.firstOrNullWhere(
          (DartProperty element) => element.propertyError.isNotEmpty);

      if (errorProperty != null) {
        _errorMessage = errorProperty.propertyError.join('\n');

        logError(_errorMessage);
        throw _errorMessage;
      }

      final MyStringBuffer sb = MyStringBuffer();
      try {
        if (ConfigSetting().fileHeaderInfo.isNotEmpty) {
          String info = ConfigSetting().fileHeaderInfo;
          //[Date MM-dd HH:mm]
          try {
            int start = info.indexOf('[Date');
            final int startIndex = start;
            if (start >= 0) {
              start = start + '[Date'.length;
              final int end = info.indexOf(']', start);
              if (end >= start) {
                String format = info.substring(start, end - start).trim();

                final String replaceString =
                    info.substring(startIndex, end - startIndex + 1);
                if (format == '') {
                  format = 'yyyy MM-dd';
                }

                info = info.replaceAll(
                    replaceString, DateFormat(format).format(DateTime.now()));
              }
            }
          } catch (e) {
            _errorMessage = 'The format of time is not right.';

            logError(_errorMessage);
            rethrow;
          }

          sb.writeLine(info);
        }

        sb.writeLine(DartHelper.jsonImport);

        if (ConfigSetting().addMethod) {
          if (ConfigSetting().enableArrayProtection) {
            sb.writeLine('import \'dart:developer\';');
            sb.writeLine(
              ConfigSetting().nullsafety
                  ? DartHelper.tryCatchMethodNullSafety
                  : DartHelper.tryCatchMethod,
            );
          }

          sb.writeLine(
            ConfigSetting().enableDataProtection
                ? ConfigSetting().nullsafety
                    ? DartHelper.asTMethodWithDataProtectionNullSafety
                    : DartHelper.asTMethodWithDataProtection
                : ConfigSetting().nullsafety
                    ? DartHelper.asTMethodNullSafety
                    : DartHelper.asTMethod,
          );
        }

        sb.writeLine(dartObject!.toString());
        String result = sb.toString();

        final DartFormatter formatter = DartFormatter();

        result = formatter.format(result);

        log('✅The dart code is generated successfully.');

        return result;
      } catch (e, stack) {
        _errorMessage = 'The dart code is generated failed.';

        log('$e');
        log('$stack');

        logError(_errorMessage);
        rethrow;
      }
    }
    return null;
  }

  void orderProperties() {
    if (dartObject != null) {
      dartObject!.orderProperties();
    }
  }

  void updateNameByNamingConventionsType() {
    if (dartObject != null) {
      dartObject!.updateNameByNamingConventionsType();
    }
  }

  void updateNullable(bool nullable) {
    if (dartObject != null) {
      dartObject!.updateNullable(nullable);
    }
  }

  void updatePropertyAccessorType() {
    if (dartObject != null) {
      dartObject!.updatePropertyAccessorType();
    }
  }
}

DartObject? createDartObject({
  required dynamic jsonData,
  required String rootName,
}) {
  DartObject? extendedObject;

  if (jsonData is Map) {
    extendedObject = DartObject(
      depth: 0,
      keyValuePair:
          MapEntry<String, dynamic>(rootName, jsonData as Map<String, dynamic>),
      nullable: false,
      uid: rootName,
    );
  } else if (jsonData is List) {
    final Map<String, List<dynamic>> root = <String, List<dynamic>>{
      rootName: jsonData
    };
    extendedObject = DartObject(
      depth: 0,
      keyValuePair: MapEntry<String, dynamic>(rootName, root),
      nullable: false,
      uid: rootName,
    ).objectKeys[rootName]!
      ..decDepth();
  }
  return extendedObject;
}

String? formatJson(dynamic jsonData) {
  Map<String, dynamic>? jsonObject;
  if (jsonData is Map) {
    jsonObject = jsonData as Map<String, dynamic>;
  } else if (jsonData is List) {
    jsonObject = jsonData.first as Map<String, dynamic>;
  }
  if (jsonObject != null) {
    return const JsonEncoder.withIndent('  ').convert(jsonObject);
  }
  return null;
}

void logError(String error) {
  log('❌Error: $error');
}

void handleError(Object? e, StackTrace stack) {
  log('$e');
  log('$stack');
  logError('There is something wrong to format.');
}
