library event_commander.test;

import 'package:event_commander/event_commander.dart';
import 'package:unittest/unittest.dart';

part 'mock_events.dart';
part 'mock_commands.dart';

EventBus
    event_bus;
Commander
    commander;
UndoRedoService
    undo_service;
List<String>
    event_messages;

expectMessageCountToBe(int n) => expect(event_messages, hasLength(n));


main() => doTests();

doTests() {
    setUp(() {
        event_bus = new EventBus();
        commander = new Commander(event_bus);
        undo_service = commander.undo_service;
        event_messages = [];
    });

    group('EventBus', () {
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
                expect(listener.isActive, isTrue);
                expect(listener.listens_to, TestEvent);
                expectMessageCountToBe(1);

                listener.stopListening();
                expect(event_bus.hasListener(listener), isFalse);
                expect(listener.isActive, isFalse);

                return event_bus.signal(event);
            })
            .then((_) {
                expectMessageCountToBe(1); // Expect no change
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

    group('Commander', () {
        setUp(() {
            event_bus.on(CommandEvent, (event) => event_messages.add('command'));
        });

        test('fires Events from Commands', () {
            commander.execute(basicCommand())
            .whenComplete(() {
                expectMessageCountToBe(1);
            });
        });

        test('can assign multiple instances to an EventBus', () {
            Commander commander2 = new Commander(event_bus);

            commander.execute(basicCommand())
            .then((_) => commander2.execute(basicCommand()))
            .whenComplete(() {
                expectMessageCountToBe(2);
            });
        });

        test('commands return correct values', () {
            commander.execute(squareCommand(2))
            .then((result) {
                expect(result, 4);
            });
        });
    });

    group('UndoRedoService', () {
        TestEntity test_entity;
        int original_id = 1;

        setUp(() {
            test_entity = new TestEntity(original_id, 'a test');
        });

        test('stores EntityStates from Commands', () {
            expect(undo_service.isEmpty, isTrue);

            commander.execute(saveEntityState(test_entity))
            .whenComplete(() {
                expect(undo_service.stack_size, 1);
            });
        });

        test('undoes changes', () {
            commander.executeSequence([saveEntityState(test_entity), modifyEntityId(test_entity)])
            .then((_){
                expect(test_entity.id, isNot(original_id));
                expect(undo_service.canUndo, isTrue);

                return undo_service.undo();
            })
            .whenComplete((){
                expect(test_entity.id, original_id);
            });
        });

        test('redoes changes', () {
            var modified_id;

            commander.executeSequence([saveEntityState(test_entity), modifyEntityId(test_entity)])
            .then((_){
                expect(test_entity.id, isNot(original_id));
                expect(undo_service.canRedo, isFalse);

                modified_id = test_entity.id;
                return undo_service.undo();
            })
            .then((_){
                expect(test_entity.id, original_id);
                expect(undo_service.canRedo, isTrue);

                return undo_service.redo();
            })
            .whenComplete((){
                expect(test_entity.id, isNot(original_id));
                expect(test_entity.id, modified_id);
            });
        });

        test('clears states', () {
            var commands = [saveEntityState(test_entity), modifyEntityId(test_entity)];

            commander.executeSequence(commands)
            .whenComplete((){
                expect(undo_service.stack_size, commands.length);

                undo_service.clear();
                expect(undo_service.isEmpty, isTrue);
                expect(undo_service.stack_size, 0);
            });
        });
    });
}