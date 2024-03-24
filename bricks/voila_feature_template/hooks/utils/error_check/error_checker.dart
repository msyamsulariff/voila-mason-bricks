import 'package:dartx/dartx.dart';
import 'package:equatable/equatable.dart';

import '../../main_controller.dart';
import '../../models/dart_object.dart';
import '../../models/dart_property.dart';
import '../camel_under_score_converter.dart';

enum DartErrorType {
  classNameEmpty,
  propertyNameEmpty,
  keyword,
}

class DartError extends Equatable {
  const DartError(this.content);

  final String content;

  @override
  List<Object?> get props => <Object>[content];
}

abstract class DartErrorChecker {
  DartErrorChecker(this.property);

  final DartProperty property;

  void checkError(String input);
}

class EmptyErrorChecker extends DartErrorChecker {
  EmptyErrorChecker(DartProperty property) : super(property);

  @override
  void checkError(String input) {
    late String errorInfo;
    late Set<String> out;
    // property change
    if (identical(input, property.name)) {
      errorInfo = "'${property.uid}': property name is empty.";
      out = property.propertyError;
    }
    // class name change
    else {
      final DartObject object = property as DartObject;
      errorInfo = "'${object.uid}'s class name is empty.";
      out = object.classError;
    }

    if (input.isEmpty) {
      out.add(errorInfo);
    } else {
      out.remove(errorInfo);
    }
  }
}

class ValidityChecker extends DartErrorChecker {
  ValidityChecker(DartProperty property) : super(property);

  @override
  void checkError(String input) {
    String? errorInfo;
    late Set<String> out;
    final String value = input;
    // property change
    if (identical(input, property.name)) {
      if (propertyKeyWord.contains(value)) {
        errorInfo = "'$value' is a key word! appLocalizations";
      }
      // PropertyAndClassNameSameChecker has do this
      // else if (property is DartObject &&
      //     (property as DartObject).className.value == value) {
      //   errorInfo = appLocalizations.propertyCantSameAsClassName;
      // }
      else if (property.value is List) {
        if (value == 'List') {
          errorInfo = "property can't the same as Type";
        } else if (property.getTypeString().contains('<$value>')) {
          errorInfo = "property can't the same as Type";
        }
      } else if (property.getBaseTypeString() == value) {
        errorInfo = "property can't the same as Type";
      }
      out = property.propertyError;
    }
    // class name change
    else {
      final DartObject object = property as DartObject;
      if (classNameKeyWord.contains(value)) {
        errorInfo = "'$value' is a key word!";
      }
      out = object.classError;
    }

    if (errorInfo == null) {
      String temp = '';
      for (int i = 0; i < value.length; i++) {
        final String char = value[i];
        if (char == '_' ||
            (temp.isEmpty ? RegExp('[a-zA-Z]') : RegExp('[a-zA-Z0-9]'))
                .hasMatch(char)) {
          temp += char;
        } else {
          errorInfo = "contains illegal characters";
          break;
        }
      }
    }

    out.removeWhere((String element) => element.startsWith('vcf: '));
    if (errorInfo != null) {
      out.add('vcf: $errorInfo');
    }
  }
}

class DuplicateClassChecker extends DartErrorChecker {
  DuplicateClassChecker(DartObject property) : super(property);

  DartObject get dartObject => property as DartObject;

  @override
  void checkError(String input) {
    if (!identical(input, dartObject.className)) {
      return;
    }

    final Map<String, List<DartObject>> groupObjects = MainController
        .instance.allObjects
        .groupBy((DartObject element) => element.className);
    final String errorInfo = "There are duplicate classes";
    for (final MapEntry<String, List<DartObject>> item
        in groupObjects.entries) {
      for (final DartObject element in item.value) {
        if (item.value.length > 1) {
          element.classError.add(errorInfo);
        } else {
          element.classError.remove(errorInfo);
        }
      }
    }
  }
}

class DuplicatePropertyNameChecker extends DartErrorChecker {
  DuplicatePropertyNameChecker(DartProperty property) : super(property);

  @override
  void checkError(String input) {
    if (property.dartObject == null || !identical(input, property.name)) {
      return;
    }

    final DartObject dartObject = property.dartObject!;
    final String errorInfo = "There are duplicate properties";
    final Map<String, List<DartProperty>> groupProperies =
        dartObject.properties.groupBy((DartProperty element) => element.name);

    for (final MapEntry<String, List<DartProperty>> item
        in groupProperies.entries) {
      for (final DartProperty element in item.value) {
        if (item.value.length > 1) {
          element.propertyError.add(errorInfo);
        } else {
          element.propertyError.remove(errorInfo);
        }
      }
    }
  }
}

class PropertyAndClassNameSameChecker extends DartErrorChecker {
  PropertyAndClassNameSameChecker(DartProperty property) : super(property);

  @override
  void checkError(String input) {
    final String errorInfo = "property can't the same as Class name";
    final Set<DartProperty> hasErrorProperites = <DartProperty>{};
    for (final DartObject dartObject in MainController.instance.allObjects) {
      final Iterable<DartProperty> list =
          MainController.instance.allProperties.where((DartProperty element) {
        final bool same = element.name == dartObject.className;
        if (same) {
          hasErrorProperites.add(element);
          element.propertyError.add(errorInfo);
        }
        return same;
      });

      if (list.isNotEmpty) {
        dartObject.classError.add(errorInfo);
      } else {
        dartObject.classError.remove(errorInfo);
      }
    }

    for (final DartProperty item in MainController.instance.allProperties) {
      if (!hasErrorProperites.contains(item)) {
        item.propertyError.remove(errorInfo);
      }
    }
  }
}
