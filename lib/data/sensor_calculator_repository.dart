import 'dart:math' as math;

import 'sensor_catalog_repository.dart';

enum SensorCalculatorKind {
  rtd,
  ntc,
}

class SensorCalculationResult {
  const SensorCalculationResult({
    required this.value,
    required this.unit,
  });

  final double value;
  final String unit;
}

abstract class SensorCalculatorSpec {
  const SensorCalculatorSpec({
    required this.label,
    required this.kind,
    required this.minTemperature,
    required this.maxTemperature,
  });

  final String label;
  final SensorCalculatorKind kind;
  final double minTemperature;
  final double maxTemperature;

  SensorCalculationResult? resistanceToTemperature(double resistance);
  SensorCalculationResult? temperatureToResistance(double temperature);
}

class RtdCalculatorSpec extends SensorCalculatorSpec {
  const RtdCalculatorSpec({
    required super.label,
    required super.minTemperature,
    required super.maxTemperature,
    required this.r0,
    required this.a,
    required this.b,
    required this.c,
    required this.mode,
  }) : super(kind: SensorCalculatorKind.rtd);

  final double r0;
  final double a;
  final double b;
  final double c;
  final int mode;

  @override
  SensorCalculationResult? resistanceToTemperature(double resistance) {
    final minResistance = _resistanceAt(minTemperature);
    final maxResistance = _resistanceAt(maxTemperature);
    final lowResistance = math.min(minResistance, maxResistance);
    final highResistance = math.max(minResistance, maxResistance);

    if (resistance < lowResistance || resistance > highResistance) {
      return null;
    }

    var low = minTemperature;
    var high = maxTemperature;
    for (var i = 0; i < 80; i++) {
      final mid = (low + high) / 2;
      final midResistance = _resistanceAt(mid);
      if ((midResistance - resistance).abs() < 0.00001) {
        return SensorCalculationResult(value: mid, unit: '°C');
      }
      if (midResistance < resistance) {
        low = mid;
      } else {
        high = mid;
      }
    }

    return SensorCalculationResult(value: (low + high) / 2, unit: '°C');
  }

  @override
  SensorCalculationResult? temperatureToResistance(double temperature) {
    if (temperature < minTemperature || temperature > maxTemperature) {
      return null;
    }
    return SensorCalculationResult(
      value: _resistanceAt(temperature),
      unit: 'Ω',
    );
  }

  double _resistanceAt(double temperature) {
    switch (mode) {
      case 0:
        if (temperature >= 0) {
          return (1 + (a * temperature) + (b * temperature * temperature)) * r0;
        }
        return (1 +
                (a * temperature) +
                (b * temperature * temperature) +
                (c * math.pow(temperature, 3) * (temperature - 100)))
            * r0;
      case 1:
        if (temperature < 0) {
          return (1 +
                  (a * temperature) +
                  (((6.7 + temperature) * b) * temperature) +
                  (c * math.pow(temperature, 3)))
              * r0;
        }
        return (1 + (a * temperature)) * r0;
      case 2:
        return (1 + (a * temperature)) * r0;
      case 3:
        if (temperature < 100) {
          return (1 + (a * temperature) + (b * temperature * temperature)) * r0;
        }
        return (1 +
                (a * temperature) +
                (b * temperature * temperature) +
                (c * temperature * temperature * (temperature - 100)))
            * r0;
      default:
        return (1 + (a * temperature)) * r0;
    }
  }
}

class NtcCalculatorSpec extends SensorCalculatorSpec {
  const NtcCalculatorSpec({
    required super.label,
    required super.minTemperature,
    required super.maxTemperature,
    required this.beta,
    required this.t0Celsius,
    required this.r0,
  }) : super(kind: SensorCalculatorKind.ntc);

  final double beta;
  final double t0Celsius;
  final double r0;

  @override
  SensorCalculationResult? resistanceToTemperature(double resistance) {
    if (resistance <= 0) {
      return null;
    }
    final t0Kelvin = t0Celsius + 273.15;
    final kelvin =
        1 / ((1 / t0Kelvin) + (math.log(resistance / r0) / beta));
    final celsius = kelvin - 273.15;
    if (celsius < minTemperature || celsius > maxTemperature) {
      return null;
    }
    return SensorCalculationResult(value: celsius, unit: '°C');
  }

  @override
  SensorCalculationResult? temperatureToResistance(double temperature) {
    if (temperature < minTemperature || temperature > maxTemperature) {
      return null;
    }
    final t0Kelvin = t0Celsius + 273.15;
    final kelvin = temperature + 273.15;
    final resistance = math.exp(beta * ((1 / kelvin) - (1 / t0Kelvin))) * r0;
    return SensorCalculationResult(value: resistance, unit: 'Ω');
  }
}

class SensorCalculatorRepository {
  SensorCalculatorRepository._();

  static final SensorCalculatorRepository instance = SensorCalculatorRepository._();

  SensorCalculatorSpec? forItem(
    SensorCatalogCategory category,
    SensorCatalogItem item,
  ) {
    if (category.type == 'RTD') {
      return _rtdSpec(category.id, item.title);
    }
    if (category.type == 'NTC') {
      return _ntcSpec(item.title);
    }
    return null;
  }

  RtdCalculatorSpec? _rtdSpec(String categoryId, String title) {
    final r0 = _extractNominalResistance(title);
    if (r0 == null) {
      return null;
    }

    switch (categoryId) {
      case 'rtd_platinum_alpha_391':
        return RtdCalculatorSpec(
          label: title,
          minTemperature: -200,
          maxTemperature: 850,
          r0: r0,
          a: 0.003969,
          b: -5.841e-7,
          c: -4.33e-12,
          mode: 0,
        );
      case 'rtd_pt_alpha_385':
        return RtdCalculatorSpec(
          label: title,
          minTemperature: -200,
          maxTemperature: 850,
          r0: r0,
          a: 0.0039083,
          b: -5.775e-7,
          c: -4.183e-12,
          mode: 0,
        );
      case 'rtd_copper_alpha_428':
        return RtdCalculatorSpec(
          label: title,
          minTemperature: -180,
          maxTemperature: 200,
          r0: r0,
          a: 0.00428,
          b: -6.2032e-7,
          c: 8.5154e-10,
          mode: 1,
        );
      case 'rtd_copper_alpha_426':
        return RtdCalculatorSpec(
          label: title,
          minTemperature: -50,
          maxTemperature: 200,
          r0: r0,
          a: 0.00426,
          b: 0,
          c: 0,
          mode: 2,
        );
      case 'rtd_nickel':
        return RtdCalculatorSpec(
          label: title,
          minTemperature: -60,
          maxTemperature: 180,
          r0: r0,
          a: 0.0054963,
          b: 6.7556e-6,
          c: 9.2004e-9,
          mode: 3,
        );
      default:
        return null;
    }
  }

  NtcCalculatorSpec? _ntcSpec(String title) {
    if (title.contains('1K')) {
      return const NtcCalculatorSpec(
        label: '1K B(25/100) 3950',
        minTemperature: -30,
        maxTemperature: 150,
        beta: 3950,
        t0Celsius: 25,
        r0: 1000,
      );
    }
    if (title.contains('10K')) {
      return const NtcCalculatorSpec(
        label: '10K B(25/100) 3950',
        minTemperature: -30,
        maxTemperature: 150,
        beta: 3950,
        t0Celsius: 25,
        r0: 10000,
      );
    }
    if (title.contains('100K')) {
      return const NtcCalculatorSpec(
        label: '100K B(25/100) 3950',
        minTemperature: -30,
        maxTemperature: 150,
        beta: 3950,
        t0Celsius: 25,
        r0: 100000,
      );
    }
    return null;
  }

  double? _extractNominalResistance(String title) {
    final match = RegExp(r'(\d+)').firstMatch(title);
    if (match == null) {
      return null;
    }
    return double.tryParse(match.group(1)!);
  }
}
