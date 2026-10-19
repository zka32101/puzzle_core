import 'package:puzzle_core/foundation.dart';
import 'package:test/test.dart';

void main() {
  test('コントラスト比: 白黒は21、同色は1', () {
    expect(contrastRatio(0xFFFFFF, 0x000000), closeTo(21, 0.01));
    expect(contrastRatio(0x336699, 0x336699), closeTo(1, 1e-9));
  });

  test('AA判定: #767676 on 白 は通る(4.54)、#777777 は通らない', () {
    expect(meetsTextAA(0x767676, 0xFFFFFF), isTrue);
    expect(meetsTextAA(0x777777, 0xFFFFFF), isFalse);
    expect(meetsTextAA(0x777777, 0xFFFFFF, large: true), isTrue);
    expect(meetsNonTextContrast(0x949494, 0xFFFFFF), isTrue);
  });

  test('色覚シミュレーション: 赤と緑は赤緑色覚で近づく', () {
    const red = 0xD03030, green = 0x30A030;
    final normal = colorDifference(red, green);
    expect(colorDifference(red, green, vision: ColorVision.deuteranopia),
        lessThan(normal));
    expect(colorDifference(red, green, vision: ColorVision.protanopia),
        lessThan(normal));
  });

  test('findIndistinguishable: 赤と緑は赤緑色覚の組として検出、青は別', () {
    final r = findIndistinguishable([0xD03030, 0x30A030, 0x3030D0],
        visions: [ColorVision.normal, ColorVision.deuteranopia],
        minDifference: 25);
    expect(r.where((p) => p.vision == ColorVision.normal), isEmpty);
    expect(r.any((p) => p.a == 0 && p.b == 1), isTrue);
  });

  test('同じ色の差は0', () {
    expect(colorDifference(0xABCDEF, 0xABCDEF), 0);
  });
}
