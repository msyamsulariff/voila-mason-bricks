import '../utils/enums.dart';

class ConfigSetting {
  factory ConfigSetting() => _appSetting;

  ConfigSetting._();

  static final ConfigSetting _appSetting = ConfigSetting._();

  bool addMethod = true;

  int column1Width = 2;

  int column2Width = 3;

  bool enableArrayProtection = true;

  bool enableDataProtection = true;

  String fileHeaderInfo = '';

  int traverseArrayCount = 1;

  PropertyNamingConventionsType propertyNamingConventionsType =
      PropertyNamingConventionsType.camelCase;

  PropertyAccessorType propertyAccessorType = PropertyAccessorType.final_;

  PropertyNameSortingType propertyNameSortingType =
      PropertyNameSortingType.none;

  bool nullsafety = true;

  bool nullable = true;

  bool smartNullable = false;

  bool addCopyMethod = false;

  bool automaticCheck = true;

  bool showResultDialog = true;
}
