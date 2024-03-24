
import 'package:mobile_app/commons/mvvm/base_view_model.dart';

import '../../../data/repositories/{{feature.snakeCase()}}/{{feature.snakeCase()}}_repository.dart';

class {{feature.pascalCase()}}ViewModel extends BaseViewModel {
  {{feature.pascalCase()}}ViewModel({
    required this.repository,
  });

  final {{feature.pascalCase()}}Repository repository;

  // TODO: UnimplementedError
}

