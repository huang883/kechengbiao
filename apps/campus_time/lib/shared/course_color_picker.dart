import 'package:flutter/material.dart';

import 'ui.dart';

String colorHex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
Color? parseCourseHex(String input) {
  var value = input.trim().replaceFirst(RegExp(r'^#'), '');
  if (RegExp(r'^[0-9a-fA-F]{3}$').hasMatch(value)) {
    value = value.split('').map((c) => '$c$c').join();
  }
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value)) return null;
  return Color(0xFF000000 | int.parse(value, radix: 16));
}

Color readableCourseText(Color background) {
  final luminance = background.computeLuminance();
  return (luminance + 0.05) / 0.05 >= 1.05 / (luminance + 0.05)
      ? Colors.black
      : Colors.white;
}

/// HSV interaction inspired by mchome/flutter_colorpicker; independent implementation.
class CourseColorPicker extends StatefulWidget {
  final String name;
  final Color initial;
  const CourseColorPicker({
    super.key,
    required this.name,
    required this.initial,
  });
  @override
  State<CourseColorPicker> createState() => _CourseColorPickerState();
}

class _CourseColorPickerState extends State<CourseColorPicker> {
  late HSVColor hsv = HSVColor.fromColor(widget.initial);
  late final hex = TextEditingController(text: colorHex(widget.initial));
  String? error;
  void choose(HSVColor value) => setState(() {
    hsv = value;
    hex.text = colorHex(value.toColor());
    error = null;
  });
  @override
  void dispose() {
    hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('课程颜色 · ${widget.name}'),
    content: SizedBox(
      width: 320,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hsv.toColor(),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black12),
              ),
              child: Text(
                widget.name,
                style: TextStyle(
                  color: readableCourseText(hsv.toColor()),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                void update(Offset position) => choose(
                  hsv
                      .withSaturation(
                        (position.dx / constraints.maxWidth).clamp(0.0, 1.0),
                      )
                      .withValue((1 - position.dy / 150).clamp(0.0, 1.0)),
                );
                return GestureDetector(
                  key: const ValueKey('color-plane'),
                  onPanDown: (d) => update(d.localPosition),
                  onPanUpdate: (d) => update(d.localPosition),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: (hsv.saturation * (constraints.maxWidth - 14))
                              .clamp(0.0, constraints.maxWidth - 14),
                          top: (1 - hsv.value) * 136,
                          child: IgnorePointer(
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: readableCourseText(hsv.toColor()),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            _slider('色相', hsv.hue, 360, (v) => choose(hsv.withHue(v))),
            _slider(
              '饱和度',
              hsv.saturation,
              1,
              (v) => choose(hsv.withSaturation(v)),
            ),
            _slider('明度', hsv.value, 1, (v) => choose(hsv.withValue(v))),
            TextField(
              key: const ValueKey('course-hex'),
              controller: hex,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'HEX 色值',
                hintText: '#247B68',
                helperText: '支持 #RRGGBB 或 #RGB，可省略 #',
                errorText: error,
              ),
              onChanged: (text) {
                final color = parseCourseHex(text);
                setState(() {
                  error = color == null ? '请输入 3 位或 6 位十六进制色值' : null;
                  if (color != null) hsv = HSVColor.fromColor(color);
                });
              },
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final color in coursePalette)
                  Semantics(
                    label: '快捷颜色 $color',
                    button: true,
                    child: InkWell(
                      onTap: () =>
                          choose(HSVColor.fromColor(courseColor(color))),
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: CircleAvatar(
                          backgroundColor: courseColor(color),
                          radius: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(
        onPressed: () {
          final color = parseCourseHex(hex.text);
          if (color == null) {
            setState(() => error = '请输入有效 HEX 色值');
            return;
          }
          Navigator.pop(context, colorHex(color));
        },
        child: const Text('保存'),
      ),
    ],
  );
  Widget _slider(
    String label,
    double value,
    double max,
    ValueChanged<double> changed,
  ) => Row(
    children: [
      SizedBox(width: 50, child: Text(label)),
      Expanded(
        child: Slider(
          value: value,
          max: max,
          label: value.toStringAsFixed(2),
          semanticFormatterCallback: (v) => '$label ${v.toStringAsFixed(2)}',
          onChanged: changed,
        ),
      ),
    ],
  );
}
