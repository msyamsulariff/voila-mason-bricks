import 'package:graphql/client.dart';
import 'package:mobile_app/src/network/gql_helpers.dart';
import 'package:mobile_app/src/network/graphql_client_provider.dart';
import 'package:mobile_app/src/ui/components/app_state/app_state_result.dart';
import 'package:mobile_app/src/network/graphql_clients.dart' as graphql_clients;
import 'package:mobile_app/commons/utils/result_information.dart';
import 'package:mobile_app/src/utils/result_response/data/app_error.dart';

import '../../../domain/entities/{{feature.snakeCase()}}/{{feature.snakeCase()}}_model.dart';
import '../../models/{{feature.snakeCase()}}/{{feature.snakeCase()}}_response.dart';
import '../../models/{{feature.snakeCase()}}/{{feature.snakeCase()}}_response_ext.dart';

part '{{feature.snakeCase()}}_gql_query.dart';

typedef {{feature.pascalCase()}}StateResult = AppStateResult<{{feature.pascalCase()}}Model, ResultInformation>;
class {{feature.pascalCase()}}Repository {
  {{feature.pascalCase()}}Repository() : gqlClientProvider = GqlClientProvider();
  final GqlClientProvider gqlClientProvider;

  {{^isQuery}}
  Future<{{feature.pascalCase()}}StateResult>
      request{{feature.pascalCase()}}() async {
    final options = MutationOptions(
      operationName: "",
      document: gqlVoila(
        _{{feature.pascalCase()}}GqlQuery.request{{feature.pascalCase()}}(),
      ),
      variables: {},
    );

    try {
      final response =
          await gqlClientProvider.getResultResponse<{{feature.pascalCase()}}Response>(
        graphqlClient: graphql_clients.appGqlClient(),
        mutationOption: options,
      );

      final data = response.data?.toDomain();
      final information = response.data?.toResultInformation();
      final error = response.appError;

      return AppStateResult(
        data: data,
        information: information,
        error: error,
      );
    } catch (e) {
      return AppStateResult(
        data: null,
        information: null,
        error: AppError(error: e),
      );
    }
  }
  {{/isQuery}}

  {{#isQuery}}
  Future<{{feature.pascalCase()}}StateResult>
      get{{feature.pascalCase()}}() async {
    final options = QueryOptions(
      operationName: "",
      document: gqlVoila(
        _{{feature.pascalCase()}}GqlQuery.get{{feature.pascalCase()}}(),
      ),
    );

    try {
      final response =
          await gqlClientProvider.getResultResponse<{{feature.pascalCase()}}Response>(
        graphqlClient: graphql_clients.appGqlClient(),
        queryOptions: options,
      );

      final data = response.data?.toDomain();
      final information = response.data?.toResultInformation();
      final error = response.appError;

      return AppStateResult(
        data: data,
        information: information,
        error: error,
      );
    } catch (e) {
      return AppStateResult(
        data: null,
        information: null,
        error: AppError(error: e),
      );
    }
  }
  {{/isQuery}}
}