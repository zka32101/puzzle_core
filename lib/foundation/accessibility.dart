/// 見やすさの検査(色だけに頼らない・コントラスト・タップ領域)。
/// 色は 0xRRGGBB の整数。UI非依存の純関数なので CI で検査できる。
library;

import 'dart:math';

/// タップ領域の最小値(pt)。
const minTapTarget = 44.0;

/// 文字の最大拡大率(端末の文字拡大 200%)。golden テストはこの値で行う。
const maxTextScale = 2.0;

double _lin(int c) {
  final s = c / 255;
  return s <= 0.04045 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4).toDouble();
}

(double, double, double) _linear(int rgb) =>
    (_lin((rgb >> 16) & 0xFF), _lin((rgb >> 8) & 0xFF), _lin(rgb & 0xFF));

double relativeLuminance(int rgb) {
  final (r, g, b) = _linear(rgb);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// WCAG のコントラスト比(1〜21)。
double contrastRatio(int a, int b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

/// 文字は AA(通常 4.5、大きい文字 3.0)。
bool meetsTextAA(int fg, int bg, {bool large = false}) =>
    contrastRatio(fg, bg) >= (large ? 3.0 : 4.5);

/// 図形・アイコンなど文字以外の部品は 3.0(WCAG 1.4.11)。
bool meetsNonTextContrast(int fg, int bg) => contrastRatio(fg, bg) >= 3.0;

enum ColorVision { normal, protanopia, deuteranopia, tritanopia }

const _matrices = {
  ColorVision.protanopia: [
    [0.152286, 1.052583, -0.204868],
    [0.114503, 0.786281, 0.099216],
    [-0.003882, -0.048116, 1.051998],
  ],
  ColorVision.deuteranopia: [
    [0.367322, 0.860646, -0.227968],
    [0.280085, 0.672501, 0.047413],
    [-0.011820, 0.042940, 0.968881],
  ],
  ColorVision.tritanopia: [
    [1.255528, -0.076749, -0.178779],
    [-0.078411, 0.930809, 0.147602],
    [0.004733, 0.691367, 0.303900],
  ],
};

/// 色覚の違いでの見え方を近似する(Machado et al. 2009、強度1.0、線形RGB)。
/// 戻りは Lab 空間の値(比較用)。
(double, double, double) _lab(int rgb, ColorVision v) {
  var (r, g, b) = _linear(rgb);
  final m = _matrices[v];
  if (m != null) {
    final nr = m[0][0] * r + m[0][1] * g + m[0][2] * b;
    final ng = m[1][0] * r + m[1][1] * g + m[1][2] * b;
    final nb = m[2][0] * r + m[2][1] * g + m[2][2] * b;
    r = nr.clamp(0.0, 1.0);
    g = ng.clamp(0.0, 1.0);
    b = nb.clamp(0.0, 1.0);
  }
  // linear sRGB → XYZ(D65) → Lab
  final x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047;
  final y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
  final z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883;
  double f(double t) =>
      t > 0.008856 ? pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
  final fx = f(x), fy = f(y), fz = f(z);
  return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz));
}

/// 色の差(CIE76 ΔE)。おおむね 20 以上で並べて区別できる。
double colorDifference(int a, int b,
    {ColorVision vision = ColorVision.normal}) {
  final (l1, a1, b1) = _lab(a, vision);
  final (l2, a2, b2) = _lab(b, vision);
  return sqrt(pow(l1 - l2, 2) + pow(a1 - a2, 2) + pow(b1 - b2, 2));
}

class IndistinguishablePair {
  const IndistinguishablePair(this.a, this.b, this.vision, this.difference);

  final int a;
  final int b;
  final ColorVision vision;
  final double difference;

  @override
  String toString() =>
      '色$a と 色$b は ${vision.name} で見分けにくい(ΔE=${difference.toStringAsFixed(1)})';
}

/// パレット内で、色だけでは見分けにくい組を返す(インデックスで返す)。
/// 見分けにくい組があっても、形・数字など色以外の手がかりが付いていれば許容できる。
/// その確認はゲーム側のテストで行う。
List<IndistinguishablePair> findIndistinguishable(
  List<int> palette, {
  double minDifference = 20,
  Iterable<ColorVision> visions = ColorVision.values,
}) {
  final out = <IndistinguishablePair>[];
  for (final v in visions) {
    for (var i = 0; i < palette.length; i++) {
      for (var j = i + 1; j < palette.length; j++) {
        final d = colorDifference(palette[i], palette[j], vision: v);
        if (d < minDifference) out.add(IndistinguishablePair(i, j, v, d));
      }
    }
  }
  return out;
}
