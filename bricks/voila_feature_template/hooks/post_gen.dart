import 'dart:convert';
import 'dart:io';

import 'package:mason/mason.dart';

import 'main_controller.dart';

Future<void> run(HookContext context) async {
  final logger = context.logger;
  final domain = context.vars['domain'] as String;
  final feature = context.vars['feature'] as String;
  final jsonFile = jsonEncode(context.vars['json_file']);

  int failCount = 0;
  String? resultConvert;

  try {
    final flutterFormattedProgress = logger.progress('Formatting JSON...');

    if (jsonFile.isNotEmpty) {
      MainController.instance.text = jsonFile;
      try {
        await MainController.instance.formatJsonAndCreateDartObject(
          rootName: '${feature.pascalCase}Response',
        );
        flutterFormattedProgress.complete('JSON formatting successful!');
      } catch (e) {
        flutterFormattedProgress.fail('$e'.trim());
        flutterFormattedProgress.fail('Failed to format JSON!');
        failCount++;
      }
    } else {
      flutterFormattedProgress.fail('No JSON content found!');
      failCount++;
    }

    final flutterGeneratedProgress = logger.progress('Generating Dart code...');

    if (jsonFile.isNotEmpty) {
      try {
        resultConvert = await MainController.instance.generateDart();

        flutterGeneratedProgress.complete('Dart code generation successful!');
      } catch (e) {
        flutterGeneratedProgress.fail('$e'.trim());
        flutterGeneratedProgress.fail('Failed to generate Dart code!');
        failCount++;
      }
    } else {
      flutterGeneratedProgress.fail('No JSON content found!');
      failCount++;
    }

    final modelDirectoryProcess =
        logger.progress('Checking model directory...');
    final filePath =
        'lib/src/features/${domain.snakeCase}/data/models/${feature.snakeCase}/${feature.snakeCase}_response.dart';

    var result = await Process.run(
      'ls',
      [filePath],
    );

    if (result.exitCode != 0) {
      modelDirectoryProcess.fail('Model directory does not exist!');
    } else {
      modelDirectoryProcess.complete('Model directory found!');
    }

    final fileName = '${feature.snakeCase}_response.dart';
    final rewriteModelResponse = logger.progress('Rewriting file $fileName...');
    Process? process;

    if (resultConvert != null && resultConvert.isNotEmpty) {
      process = await Process.start(
        'bash',
        ['-c', 'echo "$resultConvert" > $filePath'],
      );
      await process.stderr.drain();
    } else {
      rewriteModelResponse.fail('No content to rewrite for file $fileName!');
      failCount++;
    }

    if (await process?.exitCode != 0) {
      rewriteModelResponse.fail('Failed to rewrite file $fileName!');
      failCount++;
    } else {
      rewriteModelResponse.complete('File $fileName rewritten successfully!');
    }

    final fixSyntaxProgress =
        logger.progress('Clearing all syntax violations...');
    result = await Process.run('dart', [
      'fix',
      '--apply',
      'lib',
    ]);

    if (result.exitCode == 0) {
      fixSyntaxProgress.complete('All syntax violations have been fixed!');
    } else {
      fixSyntaxProgress.fail('All syntax violations could not be fixed!');
      failCount++;
    }

    // final removeUnusedFileProgress =
    // logger.progress('Removing unused files...');
    // result = await Process.run(
    //   'test',
    //   [
    //     '-e',
    //     'test/widget_test.dart',
    //   ],
    // );
    //
    // if (result.exitCode == 0) {
    //   removeUnusedFileProgress.complete('All unused files have been removed!');
    // } else {
    //   removeUnusedFileProgress.fail('All unused files have not been removed!');
    //   failCount++;
    // }

    final fixDartFormat = logger.progress('Formatting all Dart syntax code...');
    result = await Process.run('dart', [
      'format',
      'lib',
    ]);

    if (result.exitCode == 0) {
      fixDartFormat.complete('All Dart syntax has been formatted!');
    } else {
      fixDartFormat.fail('All Dart syntax cannot be formatted!');
      failCount++;
    }

    if (failCount > 0) {
      logger.warn(
        'Some tasks were not executed successfully. Please review your configuration and code before retrying!',
      );
    } else {
      logger.success(
        'Flutter project skeleton generated successfully! Let\'s build something awesome!',
      );
    }
  } catch (e) {
    logger.alert('An error occurred: $e');
    failCount++;
  }
}
