import 'package:flutter_test/flutter_test.dart';
import 'package:hesaptakip/main.dart';

void main() {
  testWidgets('Hesap Takip Kart ve Bütçe Limiti Testi', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KrediKartiHesapTakipApp());

    // Başlık ve bütçe özeti kontrolleri
    expect(find.text('Kredi Kartı Harcamaları'), findsOneWidget);
    expect(find.text('Aylık Limit'), findsOneWidget);
    expect(find.text('Kalan Limit'), findsOneWidget);
    expect(find.text('Bütçe Kullanımı'), findsOneWidget);

    // Başlangıç harcama kayıtları
    expect(find.text('Migros Market'), findsOneWidget);
    expect(find.text('Shell Petrol'), findsOneWidget);
  });
}
