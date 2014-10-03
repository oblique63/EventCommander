library event_commander.test;

import 'package:event_commander/event_commander.dart';
import 'package:unittest/unittest.dart';

part 'mock_events.dart';

EventBus event_bus;
Commander commander;
UndoRedoService undo_service;
List<String> event_messages;

expectMessageCountToBe(int n) => expect(event_messages, hasLength(n));


main() {
    setUp(() {
        event_bus = new EventBus();
        commander = new Commander(event_bus);
        undo_service = commander.undo_service;
        event_messages = [];
    });

    group('Event Bus', () {
        test('registers Event Handler', () {
            EventHandler handler = (Event event) => event_messages.add("Something Happened!");

            EventListener listener = event_bus.on(Event, handler);

            expect(event_bus.hasListener(listener), isTrue);
            expectMessageCountToBe(0);
        });

        test('fires Events', () {
            var handler = (TestEvent event) {
                event_messages.add("TestEvent: '${event.description}'");
            };

            event_bus.on(TestEvent, handler);

            event_bus.signal(new TestEvent('testing'))
            .whenComplete(() {
                expectMessageCountToBe(1);
                expect(event_messages.first, "TestEvent: 'testing'");
            });
        });

        test('listeners stop listening', () {
            var listener = event_bus.on(TestEvent, (event) => event_messages.add(event.description));
            var event = new TestEvent('testing');

            event_bus.signal(event)
            .then((_) {
                expectMessageCountToBe(1);
                listener.stopListening();
                return event_bus.signal(event);
            })
            .then((_) {
                expectMessageCountToBe(1);
            });
        });

        test('events are inherited', () {
            var event1 = new TestEvent('event1');
            var event2 = new ChildEvent('event2');

            expect(event1 is ChildEvent, isFalse);
            expect(event2 is TestEvent, isTrue);

            var event1_messages = [];
            var event2_messages = [];
            event_bus.on(TestEvent, (event) => event1_messages.add(event.description));
            event_bus.on(ChildEvent, (event) => event2_messages.add(event.description));

            event_bus.signal(event1)
            .then((_) => event_bus.signal(event2))
            .then((_) {
                expect(event1_messages, hasLength(2));
                expect(event2_messages, hasLength(1));
            });
        });

        test('can fire Multi-Events', () {
            event_bus.on(TestEvent, (event) => event_messages.add(event.description));
            event_bus.on(AlternateEvent, (event) => event_messages.add(event.number));

            event_bus.signal(new MultiEvent(1, 'event'))
            .whenComplete(() {
                expectMessageCountToBe(2);
            });
        });
    });

    group('Command Service', () {

    });

    group('Undo-Redo Service', () {

    });
}