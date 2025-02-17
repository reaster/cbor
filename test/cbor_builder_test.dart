/*
 * Package : Cbor
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/12/2016
 * Copyright :  S.Hamblett
 */

import 'package:cbor/cbor.dart' as cbor;
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'package:typed_data/typed_data.dart'; // as typed;
import 'dart:convert';
import 'package:hex/hex.dart';

Uint8Buffer uint8BufferFromString(String string) {
  if (string.isEmpty) return Uint8Buffer(0);
  final list = utf8.encoder.convert(string);
  final result = Uint8Buffer();
  result.addAll(list);
  return result;
}

void main() {
  group('List', () {
    test('List - Simple + Mixed Tag Values  -> ', () {
      final builder = cbor.ListBuilder.builder();
      builder.writeInt(2);
      builder.writeDateTime('2020/04/20');
      builder.writeURI('a/uri/it/is');
      builder.writeArray([3, 4, 5]);
      builder.writeRegEx('^[12]');
      builder.writeDouble(4.0);
      builder.writeFloat(6.0);
      final builderRes = builder.getData();
      final inst = cbor.Cbor();
      final encoder = inst.encoder;
      encoder.addBuilderOutput(builderRes);
      encoder.writeFloat(3.0);
      encoder.writeMap({'a': 'avalue'});
      inst.decodeFromInput();
      print(inst.decodedPrettyPrint(true));
      expect(inst.getDecodedData(), [
        [
          2,
          '2020/04/20',
          'a/uri/it/is',
          [3, 4, 5],
          '^[12]',
          4.0,
          6.0
        ],
        3.0,
        {'a': 'avalue'}
      ]);
    });
    test('List - Mixed Tag + Indefinte Sequence -> ', () {
      final builder = cbor.ListBuilder.builder();
      builder.writeNull();
      final b64 = typed.Uint8Buffer();
      b64.addAll([1, 2, 3]);
      builder.writeBase64(b64);
      builder.writeBase16(b64);
      final b64Url = typed.Uint8Buffer();
      b64Url.addAll('a/url'.codeUnits);
      builder.writeBase64URL(b64Url);
      builder.startIndefinite(cbor.majorTypeString);
      builder.writeString('Indef String');
      builder.writeInt(23);
      builder.writeBreak();
      final builderRes = builder.getData();
      final inst = cbor.Cbor();
      final encoder = inst.encoder;
      encoder.addBuilderOutput(builderRes);
      inst.decodeFromInput();
      final decodedData = inst.getDecodedData();
      expect(decodedData, isNotNull);
      expect(decodedData![0], [
        null,
        [1, 2, 3],
        [1, 2, 3],
        [97, 47, 117, 114, 108],
        23
      ]);
      print(inst.decodedPrettyPrint(true));
    });
  });
  group('Map', () {
    test('Map - byte string keys  -> ', () {
      final builder = cbor.MapBuilder.builder();
      final hexDude = uint8BufferFromString('dude');
      builder.writeBuff(hexDude);
      builder.writeInt(2);
      final builderRes = builder.getData();
      final hex = HEX.encode(builderRes);
      print(hex);
      final inst = cbor.Cbor();
      final encoder = inst.encoder;
      encoder.addBuilderOutput(builderRes);
      inst.decodeFromInput();
      print(inst.decodedPrettyPrint(true));
      final mapInList = inst.getDecodedData();
      expect(mapInList, isNotNull);
      expect(mapInList![0], isMap);
      final map = mapInList[0] as Map<dynamic, dynamic>;
      expect(map.keys.first, hexDude);
      expect(map.values.first, 2);
      // expect(map![0], {
      //   hexDude: 2,
      // });
    });

    test('Map - Invalid Key -> ', () {
      final builder = cbor.MapBuilder.builder();
      void build() {
        builder.writeFloat(2.0);
      }

      expect(
          build,
          throwsA(predicate((e) =>
              e is cbor.CborException && e.toString() == 'CborException: Map Builder - key expected but type is not valid for a map key')));
    });

    test('Map - Invalid Length -> ', () {
      final builder = cbor.MapBuilder.builder();
      builder.writeInt(2);
      expect(
          () => builder.getData(),
          throwsA(allOf(
              isA<cbor.CborException>(),
              predicate((e) =>
                  e.toString() ==
                  'CborException: Map Builder - unmatched key/value pairs, cannot build map,'
                      'there are 1 keys and 0 values'))));
    });

    test('Map - Simple + Mixed Tag Values  -> ', () {
      final builder = cbor.MapBuilder.builder();
      builder.writeInt(1);
      builder.writeDateTime('2020/04/20');
      builder.writeInt(2);
      builder.writeURI('a/uri/it/is');
      builder.writeInt(3);
      builder.writeArray([4, 5, 6]);
      final builderRes = builder.getData();
      final inst = cbor.Cbor();
      final encoder = inst.encoder;
      encoder.addBuilderOutput(builderRes);
      encoder.writeFloat(4.0);
      encoder.writeMap({'a': 'first', 'b': 'second'});
      inst.decodeFromInput();
      print(inst.decodedPrettyPrint(true));
      expect(inst.getDecodedData(), [
        {
          1: '2020/04/20',
          2: 'a/uri/it/is',
          3: [4, 5, 6]
        },
        4.0,
        {'a': 'first', 'b': 'second'}
      ]);
    });
    test('Map - Mixed Tag Values + Indefinite Sequence -> ', () {
      final builder = cbor.MapBuilder.builder();
      builder.writeInt(4);
      builder.writeDateTime('2020/04/20');
      builder.writeInt(5);
      builder.writeURI('a/uri/it/is');
      builder.writeInt(6);
      builder.startIndefinite(cbor.majorTypeArray);
      builder.writeArray([7, 8, 9]);
      builder.writeBreak();
      final builderRes = builder.getData();
      final inst = cbor.Cbor();
      final encoder = inst.encoder;
      encoder.addBuilderOutput(builderRes);
      encoder.writeFloat(5.0);
      encoder.writeMap({'a': 'first', 'b': 'second'});
      inst.decodeFromInput();
      print(inst.decodedPrettyPrint(true));
      expect(inst.getDecodedData(), [
        {
          4: '2020/04/20',
          5: 'a/uri/it/is',
          6: [
            [7, 8, 9]
          ]
        },
        5.0,
        {'a': 'first', 'b': 'second'}
      ]);
    });
  });
  group('Mixed building', () {
    test('Map - Built List Values-> ', () {
      final builder = cbor.MapBuilder.builder();
      builder.writeInt(7);
      final listBuilder = cbor.ListBuilder.builder();
      listBuilder.writeInt(2);
      listBuilder.writeDateTime('2020/04/20');
      builder.addBuilderOutput(listBuilder.getData());
      final inst = cbor.Cbor();
      final encoder = inst.encoder;
      encoder.addBuilderOutput(builder.getData());
      inst.decodeFromInput();
      print(inst.decodedPrettyPrint(true));
      final decodedData = inst.getDecodedData();
      expect(decodedData, isNotNull);
      expect(decodedData![0], {
        7: [2, '2020/04/20']
      });
    });
    test('List - Built Map Entries -> ', () {
      final mapBuilder = cbor.MapBuilder.builder();
      mapBuilder.writeInt(7);
      mapBuilder.writeDateTime('2020/05/21');
      final listBuilder = cbor.ListBuilder.builder();
      listBuilder.writeInt(2);
      listBuilder.writeDateTime('2020/04/20');
      listBuilder.addBuilderOutput(mapBuilder.getData());
      final inst = cbor.Cbor();
      final encoder = inst.encoder;
      encoder.addBuilderOutput(listBuilder.getData());
      inst.decodeFromInput();
      print(inst.decodedPrettyPrint(true));
      final decodedData = inst.getDecodedData();
      expect(decodedData, isNotNull);
      expect(decodedData![0], [
        2,
        '2020/04/20',
        {7: '2020/05/21'}
      ]);
    });
  });
}
