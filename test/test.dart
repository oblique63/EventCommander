library event_commander.test;

import 'dart:async';
import 'package:event_commander/event_commander.dart';
import 'package:unittest/unittest.dart';

part 'mock_events.dart';
part 'mock_commands.dart';
part 'test_helpers.dart';

EventBus
    event_bus;
Commander
    commander;
UndoRedoService
    undo_service;
List
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

            after(event_bus.signal(new TestEvent('testing')), (_) {
                expectMessageCountToBe(1);
                expect(event_messages.first, "TestEvent: 'testing'");
            });
        });

        test('listeners stop listening', () {
            var listener = event_bus.on(TestEvent, (event) => event_messages.add(event.description));
            var event = new TestEvent('testing');
            event_bus.suppress_warnings = true; // because 'event' will be signaled twice

            after(event_bus.signal(event), (_) {
                expect(listener.isActive, isTrue);
                expect(listener.listens_to, TestEvent);
                expectMessageCountToBe(1);

                listener.stopListening();
                expect(event_bus.hasListener(listener), isFalse);
                expect(listener.isActive, isFalse);

                after(event_bus.signal(event), (_) {
                    expectMessageCountToBe(1); // Expect no change
                });
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

            after([event_bus.signal(event1), event_bus.signal(event2)], (_) {
                expect(event1_messages, hasLength(2));
                expect(event2_messages, hasLength(1));
            });
        });

        test('can fire Multi-Events', () {
            event_bus.on(TestEvent, (event) => event_messages.add(event.description));
            event_bus.on(AlternateEvent, (event) => event_messages.add(event.number));

            after(event_bus.signal(new MultiEvent(1, 'event')), (_) {
                expectMessageCountToBe(2);
            });
        });

        test('only calles each EventHandler only once', () {
            // Because the same eventHandlers will be set to listen to multiple events of the same super-type:
            event_bus.suppress_warnings = true;

            // Each of these handlers should contribute only 1 message to the message List...
            eventHandler(Event event) => event_messages.add(event);
            eventHandler2(Event event) => event_messages.add(event);

            // Despite being assigned multiple times each
            event_bus..on(TestEvent, eventHandler)
                     ..on(MultiEvent, eventHandler)
                     ..on(GrandChildEvent, eventHandler)
                     ..on(TestEvent, eventHandler2)
                     ..on(AlternateEvent, eventHandler2);

            after(event_bus.signal(new MultiEvent(1, 'event')), (_) {
                expectMessageCountToBe(2);
            });
        });
    });

    group('EventQueue', () {
        EventQueue<Event> event_queue;
        setUp(() {
            event_queue = new EventQueue(event_bus);
        });

        test('listens to and queues up Events', () {
            after(event_bus.signal(new TestEvent('test')), (_) {
                expect(event_queue, hasLength(1));
            });
        });

        test('listens for specific Events', () {
            var test_queue = new EventQueue(event_bus, queue_on: TestEvent);

            // Using generic shorthand syntax for 'queue_on' parameter
            var alternate_queue = new EventQueue<AlternateEvent>(event_bus);

            after(event_bus.signal(new TestEvent('test')), (_) {
                expect(test_queue, hasLength(1));
                expect(alternate_queue.isEmpty, isTrue);

                after(event_bus.signal(new AlternateEvent(1)),(_) {
                    expect(test_queue, hasLength(1)); // No change
                    expect(alternate_queue, hasLength(1));
                });
            });
        });

        test('multi-events only queue up once', () {
            // 2 different EventHandlers...
            event_bus.on(TestEvent, (event) => event_messages.add(event.description));
            event_bus.on(AlternateEvent, (event) => event_messages.add(event.number));

            // 1 Event
            after(event_bus.signal(new MultiEvent(1, 'multi')), (_) {
                expect(event_messages, hasLength(2));
                expect(event_queue, hasLength(1));
            });
        });

        test('pops Events', () {
            after(event_bus.signal(new TestEvent('test')), (_){
                expect(event_queue, hasLength(1));

                var peek = event_queue.peekNext();
                expect(event_queue, hasLength(1));

                var event = event_queue.popNext();
                expect(event, peek);
                expect(event is TestEvent, isTrue);
                expect(event_queue, hasLength(0));
            });
        });

        test('clears Events', () {
            after([event_bus.signal(new TestEvent('event')),
                   event_bus.signal(new AlternateEvent(2))], (_) {

                expect(event_queue, hasLength(2));

                event_queue.clear();
                expect(event_queue.isEmpty, isTrue);
                expect(event_queue.hasNext, isFalse);
                expect(event_queue, hasLength(0));
            });
        });

        test('stops receiving events', () {
            after(event_bus.signal(new TestEvent('test')), (_) {
                expect(event_queue, hasLength(1));

                event_queue.clear();
                event_queue.stopReceivingEvents();

                after(event_bus.signal(new TestEvent('test')), (_) {
                    expect(event_queue.isEmpty, isTrue);
                    expect(event_queue.isActive, isFalse);
                });
            });
        });

        test("doesn't add duplicate events", () {
            var event = new TestEvent('single event');
            event_bus.suppress_warnings = true; // because 'event' will be signaled twice

            after([event_bus.signal(event), event_bus.signal(event)], (_) {
                expect(event_queue, hasLength(1));
            });
        });
    });

    group('Commander', () {
        EventQueue events;
        expectEventCountToBe(int n) => expect(events, hasLength(n));

        setUp(() {
            events = new EventQueue<CommandEvent>(event_bus);
        });

        test('fires Events from Commands', () {
            after(commander.execute(basicCommand()), (_) {
                expectEventCountToBe(1);
            });
        });

        test('can assign multiple instances to an EventBus', () {
            Commander commander2 = new Commander(event_bus);

            after([commander.execute(basicCommand()),
                   commander2.execute(basicCommand())], (_) {

                expectEventCountToBe(2);
            });
        });

        test('commands return correct values', () {
            after(commander.execute(squareCommand(2)), (result) {
                expect(result, 4);
            });
        });

        test('executes sequences', () {
            after(commander.executeSequence([squareCommand(2), squareCommand(3)]), (List results) {
                expect(results[0], 4);
                expect(results[1], 9);
                expectEventCountToBe(2);
            });
        });

        test('executes prerequisite commands', () {
            var original_id = 1;
            var test_entity = new TestEntity(original_id, 'test');

            // executes 2 commands via 'execute_first' property in CommandResult
            after(commander.execute(saveAndModifyId(test_entity)), (_) {
                expectEventCountToBe(2);
                events.clear();
                test_entity = new TestEntity(1, 'test');

                // executes 2 prerequisite commands, and fires an event for itself
                after(commander.execute(saveAndModifyIdTwice(test_entity)), (_) {
                    expectEventCountToBe(3);
                    expect(test_entity.id, (original_id + 1) * 3);
                });
            });
        });
    });

    group('UndoRedoService', () {
        TestEntity test_entity;
        int original_id = 1;

        setUp(() {
            undo_service.clear();
            test_entity = new TestEntity(original_id, 'a test');
        });

        test('stores EntityStates from Commands', () {
            expect(undo_service.isEmpty, isTrue);

            after(commander.execute(saveEntityState(test_entity)), (_) {
                expect(undo_service.stack_size, 1);
            });
        });

        test('undoes changes', () {
            after(commander.executeSequence([saveEntityState(test_entity), modifyEntityId(test_entity)]), (_) {
                expect(test_entity.id, isNot(original_id));
                expect(undo_service.canUndo, isTrue);

                undo_service.undo();

                expect(test_entity.id, original_id);
            });
        });

        test('redoes changes', () {
            var modified_id;

            after(commander.executeSequence([saveEntityState(test_entity), modifyEntityId(test_entity)]), (_) {
                expect(test_entity.id, isNot(original_id));
                expect(undo_service.canRedo, isFalse);

                modified_id = test_entity.id;
                undo_service.undo();

                expect(test_entity.id, original_id);
                expect(undo_service.canRedo, isTrue);

                undo_service.redo();

                expect(test_entity.id, isNot(original_id));
                expect(test_entity.id, modified_id);
            });
        });

        test('clears states', () {
            var commands = [saveEntityState(test_entity), modifyEntityId(test_entity)];

            after(commander.executeSequence(commands), (_) {
                expect(undo_service.stack_size, commands.length);

                undo_service.clear();
                expect(undo_service.isEmpty, isTrue);
                expect(undo_service.stack_size, 0);
            });
        });
    });
}