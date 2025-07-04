import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:snapchef/viewmodels/main_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateNiceMocks([
  MockSpec<SharedPreferences>(),
])
import 'main_viewmodel_test.mocks.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class DummyContext extends Mock implements BuildContext {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MainViewModel', () {
    late MainViewModel vm;

    setUp(() {
      vm = MainViewModel();
    });

    test('initial selectedIndex is 0', () {
      expect(vm.selectedIndex, 0);
    });

    test('currentScreen and appBarTitle match selectedIndex', () {
      expect(vm.appBarTitle, 'Fridge');
      expect(vm.currentScreen.runtimeType.toString(), contains('FridgeScreen'));
      vm.onItemTapped(1);
      expect(vm.appBarTitle, 'Cookbook');
      expect(
          vm.currentScreen.runtimeType.toString(), contains('CookbookScreen'));
      vm.onItemTapped(2);
      expect(vm.appBarTitle, 'Profile');
      expect(
          vm.currentScreen.runtimeType.toString(), contains('ProfileScreen'));
      vm.onItemTapped(3);
      expect(vm.appBarTitle, 'Notifications');
      expect(vm.currentScreen.runtimeType.toString(),
          contains('NotificationsScreen'));
    });

    test('onItemTapped updates selectedIndex and notifies listeners', () {
      var notified = false;
      vm.addListener(() {
        notified = true;
      });
      vm.onItemTapped(2);
      expect(vm.selectedIndex, 2);
      expect(notified, isTrue);
    });

    testWidgets('logout clears SharedPreferences and navigates to login',
        (tester) async {
      final mockPrefs = MockSharedPreferences();
      SharedPreferences.setMockInitialValues({});
      when(mockPrefs.clear()).thenAnswer((_) async => true);

      final mockObserver = MockNavigatorObserver();
      final vm = MainViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await vm.logout(context);
                },
                child: const Text('Logout'),
              );
            },
          ),
          navigatorObservers: [mockObserver],
          routes: {
            '/login': (context) => const Scaffold(body: Text('Login')),
          },
        ),
      );

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      
      verify(mockObserver.didReplace(
        newRoute: anyNamed('newRoute'),
        oldRoute: anyNamed('oldRoute'),
      )).called(1);

      expect(find.text('Login'), findsOneWidget);
    });
  });
}
