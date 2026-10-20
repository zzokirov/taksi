import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barber_booking/main.dart';

void main() {
  testWidgets('Barber Booking App smoke test', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: BarberBookingApp(),
      ),
    );

    // Verify that the app launches and displays the brand title
    expect(find.text('Barber Booking'), findsWidgets);
  });
}
