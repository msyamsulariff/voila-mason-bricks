import '../main_controller.dart';
import '../utils/camel_under_score_converter.dart';
import '../utils/dart_helper.dart';
import '../utils/enums.dart';
import '../utils/error_check/error_checker.dart';
import '../utils/my_string_buffer.dart';
import '../utils/string_helper.dart';
import 'config.dart';
import 'dart_property.dart';

// ignore: must_be_immutable
class DartObject extends DartProperty {
  DartObject({
    String? uid,
    MapEntry<String, dynamic>? keyValuePair,
    required int depth,
    required bool nullable,
    DartObject? dartObject,
  }) : super(
          uid: uid!,
          keyValuePair: keyValuePair!,
          depth: depth,
          nullable: nullable,
          dartObject: dartObject,
        ) {
    properties = <DartProperty>[];
    objectKeys = <String, DartObject>{};
    _jObject = (this.keyValuePair.value as Map<String, dynamic>).map(
      (String key, dynamic value) => MapEntry<String, InnerObject>(
        key,
        InnerObject(
          data: value,
          type: DartHelper.converDartType(value.runtimeType),
          nullable: DartHelper.converNullable(value),
        ),
      ),
    );

    final String key = this.keyValuePair.key;
    className = correctName(
      upcaseCamelName(key),
      isClassName: true,
    );
    initializeProperties();
    updateNameByNamingConventionsType();

    MainController.instance.allObjects.add(this);
    duplicateClassChecker = DuplicateClassChecker(this);
    errors.add(duplicateClassChecker);
    updateError(className);
  }

  Map<String, InnerObject>? _jObject;
  Map<String, InnerObject>? _mergeObject;

  Map<String, InnerObject>? get jObject =>
      _mergeObject != null ? _mergeObject! : _jObject;

  late DuplicateClassChecker duplicateClassChecker;

  String className = '';
  late List<DartProperty> properties;

  late Map<String, DartObject> objectKeys;

  void decDepth() {
    depth -= 1;
    for (final DartObject obj in objectKeys.values) {
      obj.decDepth();
    }
  }

  void initializeProperties() {
    properties.clear();
    objectKeys.clear();
    if (jObject != null && jObject!.isNotEmpty) {
      for (final MapEntry<String, InnerObject> item in jObject!.entries) {
        initializePropertyItem(item, depth);
      }
      orderProperties();
    }
  }

  void initializePropertyItem(MapEntry<String, InnerObject> item, int depth,
      {bool addProperty = true}) {
    if (item.value.data is Map &&
        (item.value.data as Map<String, dynamic>).isNotEmpty) {
      if (objectKeys.containsKey(item.key)) {
        final DartObject temp = objectKeys[item.key]!;
        temp.merge(
          (item.value.data as Map<String, dynamic>).map(
            (String key, dynamic value) => MapEntry<String, InnerObject>(
              key,
              InnerObject(
                data: value,
                type: DartHelper.converDartType(value.runtimeType),
                nullable: DartHelper.converNullable(value),
              ),
            ),
          ),
        );
        objectKeys[item.key] = temp;
      } else {
        final DartObject temp = DartObject(
          uid: '${uid}_${item.key}',
          keyValuePair: MapEntry<String, dynamic>(item.key, item.value.data),
          nullable: item.value.nullable,
          depth: depth + 1,
          dartObject: this,
        );
        if (addProperty) {
          properties.add(temp);
        }
        objectKeys[item.key] = temp;
      }
    } else if (item.value.data is List) {
      if (addProperty) {
        properties.add(
          DartProperty(
            uid: uid,
            keyValuePair: MapEntry<String, dynamic>(item.key, item.value.data),
            nullable: item.value.nullable,
            depth: depth,
            dartObject: this,
          ),
        );
      }
      final List<dynamic> array = item.value.data as List<dynamic>;
      if (array.isNotEmpty) {
        int count = ConfigSetting().traverseArrayCount;
        if (count == 99) {
          count = array.length;
        }
        final Iterable<dynamic> cutArray = array.take(count);
        for (final dynamic arrayItem in cutArray) {
          initializePropertyItem(
            MapEntry<String, InnerObject>(
              item.key,
              InnerObject(
                data: arrayItem,
                type: DartHelper.converDartType(arrayItem.runtimeType),
                nullable: DartHelper.converNullable(value) &&
                    ConfigSetting().smartNullable,
              ),
            ),
            depth,
            addProperty: false,
          );
        }
      }
    } else {
      if (addProperty) {
        properties.add(
          DartProperty(
            uid: uid,
            keyValuePair: MapEntry<String, dynamic>(item.key, item.value.data),
            nullable: item.value.nullable,
            depth: depth,
            dartObject: this,
          ),
        );
      }
    }
  }

  void merge(Map<String, InnerObject>? other) {
    bool needInitialize = false;
    if (_jObject != null) {
      _mergeObject ??= <String, InnerObject>{};

      for (final MapEntry<String, InnerObject> item in _jObject!.entries) {
        if (!_mergeObject!.containsKey(item.key)) {
          needInitialize = true;
          _mergeObject![item.key] = item.value;
        }
      }

      if (other != null) {
        _mergeObject ??= <String, InnerObject>{};

        if (ConfigSetting().smartNullable) {
          for (final MapEntry<String, InnerObject> existObject
              in _mergeObject!.entries) {
            if (!other.containsKey(existObject.key)) {
              final InnerObject newObject = InnerObject(
                data: existObject.value.data,
                type: existObject.value.type,
                nullable: true,
              );
              _mergeObject![existObject.key] = newObject;
              needInitialize = true;
            }
          }
        }

        for (final MapEntry<String, InnerObject> item in other.entries) {
          if (!_mergeObject!.containsKey(item.key)) {
            needInitialize = true;
            _mergeObject![item.key] = InnerObject(
              data: item.value.data,
              type: item.value.type,
              nullable: true,
            );
          } else {
            InnerObject existObject = _mergeObject![item.key]!;
            if ((existObject.isNull && !item.value.isNull) ||
                (!existObject.isNull && item.value.isNull) ||
                existObject.nullable != item.value.nullable) {
              existObject = InnerObject(
                data: item.value.data ?? existObject.data,
                type: item.value.type != DartType.Null
                    ? item.value.type
                    : existObject.type,
                nullable: (existObject.nullable || item.value.nullable) &&
                    ConfigSetting().smartNullable,
              );
              _mergeObject![item.key] = existObject;
              needInitialize = true;
            } else if (existObject.isList &&
                item.value.isList &&
                ((existObject.isEmpty || item.value.isEmpty) ||
                    // make sure Object will be merge
                    (existObject.isObject || item.value.isObject))) {
              existObject = InnerObject(
                data: (item.value.data as List<dynamic>)
                  ..addAll(existObject.data as List<dynamic>),
                type: item.value.type,
                nullable: false,
              );
              _mergeObject![item.key] = existObject;
              needInitialize = true;
            }
          }
        }
        if (needInitialize) {
          initializeProperties();
        }
      }
    }
  }

  @override
  void updateNameByNamingConventionsType() {
    super.updateNameByNamingConventionsType();

    for (final DartProperty item in properties) {
      item.updateNameByNamingConventionsType();
    }

    for (final MapEntry<String, DartObject> item in objectKeys.entries) {
      item.value.updateNameByNamingConventionsType();
    }
  }

  @override
  void updatePropertyAccessorType() {
    super.updatePropertyAccessorType();

    for (final DartProperty item in properties) {
      item.updatePropertyAccessorType();
    }

    for (final MapEntry<String, DartObject> item in objectKeys.entries) {
      item.value.updatePropertyAccessorType();
    }
  }

  @override
  void updateNullable(bool nullable) {
    super.updateNullable(nullable);
    for (final DartProperty item in properties) {
      item.updateNullable(nullable);
    }

    for (final MapEntry<String, DartObject> item in objectKeys.entries) {
      item.value.updateNullable(nullable);
    }
  }

  @override
  String getTypeString({String? className}) {
    return this.className;
  }

  void orderProperties() {
    final PropertyNameSortingType sortingType =
        ConfigSetting().propertyNameSortingType;
    if (sortingType != PropertyNameSortingType.none) {
      if (sortingType == PropertyNameSortingType.ascending) {
        properties.sort((DartProperty left, DartProperty right) =>
            left.name.compareTo(right.name));
      } else {
        properties.sort((DartProperty left, DartProperty right) =>
            right.name.compareTo(left.name));
      }
    }

    if (jObject != null) {
      for (final MapEntry<String, DartObject> item in objectKeys.entries) {
        item.value.orderProperties();
      }
    }
  }

  @override
  String toString() {
    if (MainController.instance.printedObjects.contains(this)) {
      return '';
    }
    MainController.instance.printedObjects.add(this);

    orderProperties();

    final MyStringBuffer sb = MyStringBuffer();

    sb.writeLine(stringFormat(DartHelper.classHeader, <String>[className]));

    if (properties.isNotEmpty) {
      final MyStringBuffer factorySb = MyStringBuffer();
      final MyStringBuffer factorySb1 = MyStringBuffer();
      final MyStringBuffer propertySb = MyStringBuffer();

      final MyStringBuffer fromJsonSb = MyStringBuffer();
      //Array
      final MyStringBuffer fromJsonSb1 = MyStringBuffer();
      final MyStringBuffer toJsonSb = MyStringBuffer();

      final MyStringBuffer copySb = MyStringBuffer();

      final bool isAllFinalProperties = !properties.any(
          (DartProperty element) =>
              element.propertyAccessorType != PropertyAccessorType.final_);

      factorySb.writeLine(
        stringFormat(DartHelper.factoryStringHeader,
            <String>['${isAllFinalProperties ? 'const' : ''} $className']),
      );

      toJsonSb.writeLine(DartHelper.toJsonHeader);

      for (final DartProperty item in properties) {
        final String lowName =
            item.name.substring(0, 1).toLowerCase() + item.name.substring(1);
        final String name = item.name;
        String? className;
        String? typeString;
        final String setName = DartHelper.getSetPropertyString(item);
        String setString = '';
        final String fss = DartHelper.factorySetString(
          item.propertyAccessorType,
          (!ConfigSetting().nullsafety) ||
              (ConfigSetting().nullsafety && item.nullable),
        );
        final bool isGetSet = fss.startsWith('{');
        String copyProperty = item.name;

        if (item is DartObject) {
          className = item.className;

          setString = stringFormat(
            DartHelper.setObjectProperty,
            <String>[
              item.name,
              item.key,
              className,
              if (ConfigSetting().nullsafety && item.nullable)
                '${DartHelper.jsonRes}[\'${item.key}\']==null?null:'
              else
                '',
              if (ConfigSetting().nullsafety) '!' else ''
            ],
          );
          typeString = className;
          if (ConfigSetting().nullsafety && item.nullable) {
            typeString += '?';
          }

          if (ConfigSetting().addCopyMethod) {
            if (!ConfigSetting().nullsafety || item.nullable) {
              copyProperty += '?';
            }
            copyProperty += '.copy()';
          }
        } else if (item.value is List) {
          if (objectKeys.containsKey(item.key)) {
            className = objectKeys[item.key]!.className;
          }
          typeString = item.getTypeString(className: className);

          typeString = typeString.replaceAll('?', '');

          fromJsonSb1.writeLine(
            item.getArraySetPropertyString(
              lowName,
              typeString,
              className: className,
              baseType: item.getBaseTypeString(className: className).replaceAll(
                    '?',
                    '',
                  ),
            ),
          );

          setString = ' ${item.name}:$lowName';

          if (ConfigSetting().nullsafety) {
            if (item.nullable) {
              typeString += '?';
            } else {
              setString += '!';
            }
          }
          setString += ',';
          if (ConfigSetting().addCopyMethod) {
            copyProperty = item.getListCopy(className: className);
          }
        } else {
          setString = DartHelper.setProperty(item.name, item, this.className);
          typeString = DartHelper.getDartTypeString(item.type, item);
        }

        if (isGetSet) {
          factorySb.writeLine(stringFormat(fss, <String>[typeString, lowName]));
          if (factorySb1.length == 0) {
            factorySb1.write('}):');
          } else {
            factorySb1.write(',');
          }
          factorySb1.write('$setName=$lowName');
        } else {
          factorySb.writeLine(stringFormat(fss, <String>[item.name]));
        }

        propertySb.writeLine(
          stringFormat(DartHelper.propertyS(item.propertyAccessorType),
              <String>[typeString, name, lowName]),
        );
        fromJsonSb.writeLine(setString);

        toJsonSb.writeLine(stringFormat(DartHelper.toJsonSetString, <String>[
          item.key,
          setName,
        ]));
        if (ConfigSetting().addCopyMethod) {
          copySb.writeLine('${item.name}:$copyProperty,');
        }
      }

      if (factorySb1.length == 0) {
        factorySb.writeLine(DartHelper.factoryStringFooter);
      } else {
        factorySb1.write(';');
        factorySb.write(factorySb1.toString());
      }

      String fromJson = '';
      if (fromJsonSb1.length != 0) {
        fromJson = stringFormat(
                ConfigSetting().nullsafety
                    ? DartHelper.fromJsonHeader1NullSafety
                    : DartHelper.fromJsonHeader1,
                <String>[className]) +
            fromJsonSb1.toString() +
            stringFormat(DartHelper.fromJsonFooter1,
                <String>[className, fromJsonSb.toString()]);
      } else {
        fromJson = stringFormat(
                ConfigSetting().nullsafety
                    ? DartHelper.fromJsonHeaderNullSafety
                    : DartHelper.fromJsonHeader,
                <String>[className]) +
            fromJsonSb.toString() +
            DartHelper.fromJsonFooter;
      }

      toJsonSb.writeLine(DartHelper.toJsonFooter);
      sb.writeLine(factorySb.toString());
      sb.writeLine(fromJson);
      sb.writeLine(propertySb.toString());
      sb.writeLine(DartHelper.classToString);
      sb.writeLine(toJsonSb.toString());
      if (ConfigSetting().addCopyMethod) {
        sb.writeLine(stringFormat(DartHelper.copyMethodString, <String>[
          className,
          copySb.toString(),
        ]));
      }
    }

    sb.writeLine(DartHelper.classFooter);

    for (final MapEntry<String, DartObject> item in objectKeys.entries) {
      sb.writeLine(item.value.toString());
    }

    return sb.toString();
  }

  @override
  List<Object?> get props => <Object?>[
        key,
        uid,
      ];

  Set<String> classError = <String>{};

  bool get hasClassError => classError.isNotEmpty;
}

class InnerObject {
  InnerObject({
    required this.data,
    required this.type,
    required this.nullable,
  });

  final dynamic data;
  final DartType type;

  // data is null ?
  final bool nullable;

  bool get isList => data is List;

  bool get isEmpty => isList && (data as List<dynamic>).isEmpty;

  bool get isNull => type.isNull;

  bool get isObject => type == DartType.Object;
}

class CheckError implements Exception {
  CheckError(this.msg);

  final String msg;
}
