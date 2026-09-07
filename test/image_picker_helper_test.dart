import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ppkd_absen_app/core/utils/image_picker_helper.dart';

void main() {
  testWidgets('showSourcePicker displays without DecoratedBox/ListTile assertion',
      (WidgetTester tester) async {
    ImagePickerAction? selectedAction;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selectedAction = await ImagePickerHelper.showSourcePicker(
                  context,
                  showDeleteOption: true,
                );
              },
              child: const Text('Open Picker'),
            ),
          ),
        ),
      ),
    );

    // Tap button to open bottom sheet
    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Verify all 3 options exist
    expect(find.text('Pilih Foto Profil'), findsOneWidget);
    expect(find.text('Ambil Foto (Kamera)'), findsOneWidget);
    expect(find.text('Pilih dari Galeri'), findsOneWidget);
    expect(find.text('Hapus Foto Profil'), findsOneWidget);

    // Tap Delete option
    await tester.tap(find.text('Hapus Foto Profil'));
    await tester.pumpAndSettle();

    // Confirm that ImagePickerAction.delete was returned
    expect(selectedAction, equals(ImagePickerAction.delete));
  });

  testWidgets('showSourcePicker omits delete option when showDeleteOption is false',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ImagePickerHelper.showSourcePicker(
                context,
                showDeleteOption: false,
              ),
              child: const Text('Open Picker'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih Foto Profil'), findsOneWidget);
    expect(find.text('Ambil Foto (Kamera)'), findsOneWidget);
    expect(find.text('Pilih dari Galeri'), findsOneWidget);
    expect(find.text('Hapus Foto Profil'), findsNothing);
  });
}
