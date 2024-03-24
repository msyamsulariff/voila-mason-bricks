import 'package:mobile_app/commons/utils/result_information.dart';

import '../../../domain/entities/{{feature.snakeCase()}}/{{feature.snakeCase()}}_model.dart';
import '{{feature.snakeCase()}}_response.dart';

extension {{feature.pascalCase()}}ResponseExt on {{feature.pascalCase()}}Response {
  ResultInformation? toResultInformation() {
    // TODO: UnimplementedError
    return null;
  }

  {{feature.pascalCase()}}Model? toDomain() {
    // TODO: UnimplementedError
    return null;
  }
}
