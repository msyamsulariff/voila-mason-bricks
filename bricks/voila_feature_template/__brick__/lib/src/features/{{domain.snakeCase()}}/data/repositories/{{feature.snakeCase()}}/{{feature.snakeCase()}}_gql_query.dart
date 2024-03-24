part of '{{feature.snakeCase()}}_repository.dart';

class _{{feature.pascalCase()}}GqlQuery {
  {{#isQuery}}
  static String get{{feature.pascalCase()}}() {
    // TODO: UnimplementedError
    return r'''

    ''';
  }
  {{/isQuery}}

  {{^isQuery}}
  static String request{{feature.pascalCase()}}() {
    return r'''

    ''';
  }
  {{/isQuery}}
}
