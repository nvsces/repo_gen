import 'dart:convert';
import 'dart:io';

import 'package:build/src/builder/build_step.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:repository_gen/src/swag_api_method.dart';
import 'package:source_gen/source_gen.dart';

import 'model_visitor.dart';

class SwagApiGenerator extends GeneratorForAnnotation<RepositoryBloc> {
  @override
  Future<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    final visitor = ModelVisitor();
    element.visitChildren(visitor);

    final className = '${visitor.className}Request';

    final classBuffer = StringBuffer();

    final method = annotation.read('method').stringValue;
    // classBuffer.writeln(" import 'package:http/http.dart' as http;");

    final nameApiclass = '''
     class $className extends GetRequest {
        final Map<String, dynamic> options;
        $className({
          required this.options,
          required super.data,
          super.headers,
        });

        @override
        $className copyWith(
            {RepositoryResponse? data, Map<String, dynamic>? headers}) {
          // TODO: implement copyWith
          throw UnimplementedError();
        }
      }
          ''';
    classBuffer.writeln(nameApiclass);
    return classBuffer.toString();
  }

  List<String> parseParametrs(Map<String, dynamic> data) {
    bool containsParams = data.containsKey('parameters');
    if (!containsParams) {
      return [];
    }
    return [
      data['parameters'][0]['name'],
      data['parameters'][0]['in'],
    ];
  }

  void generateGettersAndSetters(
      ModelVisitor visitor, StringBuffer classBuffer) {
    // 1
    for (final field in visitor.fields.keys) {
      // 2
      final variable =
          field.startsWith('_') ? field.replaceFirst('_', '') : field;

      // 3
      classBuffer.writeln(
          "${visitor.fields[field]} get $variable => variables['$variable'];");
      // EX: String get name => variables['name'];

      // 4
      classBuffer
          .writeln('set $variable(${visitor.fields[field]} $variable) {');
      classBuffer.writeln('super.$field = $variable;');
      classBuffer.writeln("variables['$variable'] = $variable;");
      classBuffer.writeln('}');

      // EX: set name(String name) {
      //       super._name = name;
      //       variables['name'] = name;
      //     }
    }
  }
}
