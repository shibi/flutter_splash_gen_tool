import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:splash_genx/main.dart';
import 'package:splash_genx/models/editor_state.dart';
import 'package:splash_genx/ui/controls_panel.dart';

Future<void> _openSplashEditor(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SplashGenXApp());
  await tester.tap(find.text('Create Splash Icon'));
  await tester.pumpAndSettle();
}

EditorState _state(WidgetTester tester) => Provider.of<EditorState>(
  tester.element(find.byType(ControlsPanel)),
  listen: false,
);

Finder _panelScrollable() => find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

void main() {
  test('hex codes parse with or without # and in short form', () {
    expect(parseHexColor('355070'), const Color(0xFF355070));
    expect(parseHexColor('#e56b6f'), const Color(0xFFE56B6F));
    expect(parseHexColor('#abc'), const Color(0xFFAABBCC));
    expect(parseHexColor('12345'), isNull);
    expect(parseHexColor('GGGGGG'), isNull);
    expect(parseHexColor(''), isNull);
  });

  testWidgets('background swatch opens the colour picker', (tester) async {
    await _openSplashEditor(tester);
    await tester.tap(find.byTooltip('Pick background colour'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Background colour'), findsWidgets);
  });

  testWidgets('typing a hex code sets background and foreground', (
    tester,
  ) async {
    await _openSplashEditor(tester);
    final background = find.widgetWithText(TextField, 'Background hex');
    expect(
      find.descendant(of: background, matching: find.text('FFFFFF')),
      findsOneWidget,
    );

    await tester.enterText(background, '355070');
    await tester.pump();
    expect(_state(tester).backgroundColor, const Color(0xFF355070));

    // Incomplete codes leave the colour alone and say why.
    await tester.enterText(background, '35');
    await tester.pump();
    expect(_state(tester).backgroundColor, const Color(0xFF355070));
    expect(find.text('Use 6 hex digits'), findsOneWidget);

    final foreground = find.widgetWithText(TextField, 'Foreground hex');
    await tester.scrollUntilVisible(
      foreground,
      200,
      scrollable: _panelScrollable(),
    );
    await tester.enterText(foreground, '#E56B6F');
    await tester.pump();
    expect(_state(tester).tintColor, const Color(0xFFE56B6F));
    expect(_state(tester).tintEnabled, isTrue);
  });

  testWidgets('scale percentage can be typed', (tester) async {
    await _openSplashEditor(tester);
    final state = _state(tester);
    state.setImage(img.Image(width: 400, height: 300), 'a.png');
    await tester.pump();

    final field = find.descendant(
      of: find.byType(ControlsPanel),
      matching: find.widgetWithText(TextField, '%'),
    );
    await tester.enterText(field, '150');
    await tester.pump();
    expect(state.scale, closeTo(1.5, 1e-9));

    // Out-of-range values stop at the slider limits.
    await tester.enterText(field, '5000');
    await tester.pump();
    expect(state.scale, state.maxScale);
  });

  testWidgets('scaffold layer is off by default and can be turned on', (
    tester,
  ) async {
    await _openSplashEditor(tester);
    final state = _state(tester);
    expect(state.scaffoldEnabled, isFalse);
    expect(find.text('Transparent scaffold'), findsNothing);

    final label = find.text('Scaffold layer');
    await tester.scrollUntilVisible(label, 200, scrollable: _panelScrollable());
    final row = find.ancestor(of: label, matching: find.byType(Row)).first;
    await tester.tap(find.descendant(of: row, matching: find.byType(Switch)));
    await tester.pump();
    expect(state.scaffoldEnabled, isTrue);
    expect(state.scaffoldRect, const Rect.fromLTWH(192, 192, 768, 768));

    final hex = find.widgetWithText(TextField, 'Scaffold hex');
    await tester.scrollUntilVisible(hex, 200, scrollable: _panelScrollable());
    await tester.enterText(hex, '355070');
    await tester.pump();
    expect(state.scaffoldColor, const Color(0xFF355070));
  });
}
