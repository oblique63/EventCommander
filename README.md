Event Commander
===============

[![Pub Package](http://img.shields.io/pub/v/box2d.svg?style=flat-square)](https://pub.dartlang.org/packages/event_commander)
[![Build Status](https://drone.io/github.com/oblique63/EventCommander/status.png)](https://drone.io/github.com/oblique63/EventCommander/latest)

An EventBus, EventQueue, [Command Pattern](http://en.wikipedia.org/wiki/Command_pattern), and Undo-Redo library for [Dart](https://www.dartlang.org/).

- [API Documentation](http://www.dartdocs.org/documentation/event_commander/latest)
- [Changelog](https://github.com/oblique63/EventCommander/blob/master/CHANGELOG.md)

#### TL;DR
- The `EventBus` is in charge of firing, and sending `Events` to functions (i.e. `EventHandlers`)  you register.
- You can make/compose your own `Event` types with multiple-inheritance so that `EventHandlers` can listen to subtypes of events.
- An `EventQueue` is used whenever you want to queue up events of a certain type, and handle them sequentially.
- Use `Commands` instead of `EventHandlers` when you want to keep track of the actions your application performs.
- _Undo/Redo_ abilities are a nice bonus you get from using `Commands`, but require your commands to take a snapshot of
the changes performed to your objects using a `Map`.


#### Conventions
Throughout this doc, properties/methods of classes will be listed in the following format:

`property_or_method : [modifiers] Type/ReturnType`


## Event Bus
The `EventBus` is the backbone for all of the EventQueue/Command/Undo-Redo communications behind the scenes,
but may be used on its own to fire and listen to (a.k.a. 'publish/subscribe') Events.

#### Basic usage

```dart
var event_bus = new EventBus();

event_bus.on(MyEventType, (MyEventType event) => doSomething());

event_bus.signal(new MyEventType()); // doSomething() will be called
```

Ideally, only one instance of an `EventBus` object should be needed for each major scope of your application
(e.g. client vs server). While using multiple instances is possible, it makes keeping track of events trickier,
as there is no global/static EventBus object listening to everything (this is a design choice to allow for more flexibility).
So passing references to a single main `EventBus` instance is the preferred means of usage.

#### EventHandler
A function that accepts an `Event`, and is meant to be called whenever an event of the appropriate type is fired.
Note: since `Events` allow for inheritance, `EventHandler` instances should not be reused to listen to multiple
events of the same super-type, since each EventHandler instance will only be called once per Event firing. Example:

```dart
myEventHandler(MyEvent event) => doSomething();

// Where MyChildEvent is a subtype of MyEvent
event_bus..on(MyEvent, myEventHandler)
         ..on(MyChildEvent, myEventHandler);

event_bus.signal(MyChildEvent);
// Will only call myEventHandler() once, despite other handlers for MyEvent
// also being called.

// To avoid this, simply assign a different function instance to each listener:
event_bus..on(MyEvent, (event) => doSomething())
         ..on(MyChildEvent, (event) => doSomething());

event_bus.signal(MyChildEvent);
// This time doSomething() will be called twice.
```

#### EventListener
* `listens_to : Type` - Property that lists what type of `Event` the listener is listening to.

* `handler : EventHandler` - The `EventHandler` function that is called whenever an `event` of the type
specified by `listens_to` is signaled.

* `stopListening() : void` - Unregisters the listener from its corresponding `EventBus`, and stops the `handler`
from being called and handling future events.

#### EventBus
* `on(Type event_type, void eventHandler(Event event)) : EventListener` -
Registers a function (`EventHandler`) to get called whenever an event of `event_type` is signaled.
Returns an `EventListener` that can be used to stop the registered `EventHandler` from handling events.

* `signal(Event event) : Future` -
Fires/propagates the event instance passed to it, and sends it to all the appropriate `EventHandlers` subscribed/listening
to events of that type. Returns a `Future` in case some computation needs to happen after all the corresponding
`EventHandlers` have been notified of the event.

* `stopListener(EventListener listener) : void` -
Same as `EventListener.stopListening()`. Unregisters an `EventHandler` function (via its corresponding `EventListener`)
from the `EventBus`. Stops the `EventHandler` from being called and receiving future events from this `EventBus` instance.

* `clearAllListeners() : void` -
Removes all `EventListeners`/`EventHandlers` from the `EventBus` instance.

* `hasListener(EventListener listener) : bool` -
Checks whether the given `listener` is registered with the `EventBus` instance.

## Event Queue
`EventQueue` is a basic [Event/Message Queue](http://gameprogrammingpatterns.com/event-queue.html) implementation
that populates itself based on `Events` sent to the `EventBus`. By default, an `EventQueue` will listen to all `Events`,
but each instance may be configured to only queue up specific event types upon creation:

`var queue = new EventQueue(event_bus, queue_on: MyEvent);`

Alternative declaration using generics (yields same result as above):

`var queue = new EventQueue<MyEvent>(event_bus);`

> __Note:__ Event types specified using generics will override any values passed to the 'queue_on' parameter

#### Sample usage
```dart
while(true) {
    if (event_queue.hasNext) {
       Event event = event_queue.popNext();
       doSomethingWith(event);

       // Alternatively, you do not have to remove events
       // from the queue to examine them:
       checkEvent(event_queue.peekNext());
    }
    // break out of the loop under some condition...
}

if (event_queue.isActive)
    event_queue.stopReceivingEvents();
```

## Events
Custom Events may be created by sub-classing the `Event` class, and may contain any assortment
of properties and behaviors like you would find in a regular Dart class.

```dart
class MyEvent extends Event {
  String description;
  MyEvent(this.description);
}

event_bus.on(MyEvent, (event) => doSomething());

event_bus.signal(new MyEvent('Something happened!')):
```

Notice that new instances of your Events should be created every time they're being signaled. This is because
modifying/reusing the same _exact_ instance of an `Event` object will break the expected functionality of `EventQueues`
(i.e. queueing up the same instance twice and modifying its state, effectively overwrites the event's history, since `EventQueue`
does not keep track of `Event` states and only contains references to the original event objects signaled).
Additionally, creating events is cheap, and guarding against signaling duplicate event instances helps catch bugs due to
accidental event firings. The `EventBus` will display a warning whenever it catches an `Event` instance getting
signaled multiple times.

> __Note:__ The `Event` super-class currently comes with a `dispatched : bool` property that signifies when the event
> instance has been sent out to its respective listeners. It can be manually set after each use to overcome the
> 'new-instance-per-signal()' policy, but doing so will break `EventQueues` as explained above. This feature is liable
> to be deprecated in future versions, so avoid usage of it at all costs.

Events also support a multiple-inheritance scheme whereby listeners for a particular Event Type
may be notified of other Events implementing/extending that same Event Type. This is accomplished
by adding super-class/parent events to a `Set<Type> parents` property in your `Event` class. Example:

```dart
class MyEvent extends Event {
  String description;
  MyEvent(this.description);
}

class MyOtherEvent extends Event {
  int number;
  MyOtherEvent(this.number);
}

// Class must commit to 'implement' MyElement and MyOtherElement to ensure that
// listeners of those events can make use of this event
class MultiEvent extends Event implements MyEvent, MyOtherElement {
  int number;
  String description;

  MyChildEvent(this.number, this.description) {
    // This is what will notify listeners of MyEvent and MyOtherEvent
    // whenever this event is called:
    this.parents.addAll([MyEvent, MyOtherEvent]);
  }
}

event_bus.on(MyEvent, (MyEvent e) => doA(e.description));
event_bus.on(MyOtherEvent, (MyOtherEvent e) => doB(e.number));

event_bus.signal(new MultiEvent(1, 'event')); // triggers both doA() and doB()
```

#### Best Practices
`Events` should be nothing more than simple lightweight wrappers with the real entity objects as properties,
so objects that need to be dealt with/mutated aren't tied to event instances themselves. In essence, `Events` are
just vehicles to get entities/data from one place to another, so they should not be used as a source of data on
their own. Example:

```dart
// Recommended Usage
class ChangeEntityEvent extends Event {
    MyEntity entity; // this is the entity/instance you wish to keep track of
    ChangeEntityEvent(this.entity);
}

// Not Recommended
class MyEntityEvent extends Event {
    int id;
    String name;
    // More entity data here...

    MyEntityEvent();
}
```

This leads to less reliance on `Event` instances, and easier tracking of entities/models.

#### Dynamic Events
These are not built-in classes/features of the library, but they may be useful in cases where event data can't be predicted.
Thanks to Dart's optional type system, handling dynamic data is simple, but may require additional checking from `EventHandlers`.

__DataEvent Pattern:__ An event for dealing with arbitrary data

```dart
class DataEvent extends Event {
    Map<String, dynamic> data;
    EntityEvent(this.data);
}

eventBus.signal(new EntityEvent({
    'entity': my_entity,
    'event_description': 'something happened'
}));

eventBus.on(EntityEvent, (event) {
    if (event.entities.containsKey('entity')) {
        doSomethingWith(event.entities['entity']);
        log(event['event_description']);
    }
});
```

__DynamicEvent Pattern:__ An event for dealing with arbitrary objects

```dart
class DynamicEvent extends Event {
    var entity;
    DynamicEvent(this.entity);
}

eventBus.signal(new DynamicEvent(my_entity));

eventBus.on(DynamicEvent, (event) {
    if (event.entity is MyEntity) {
        doSomethingWith(event.entity);
    }
});
```

## Commands
A `Command` is just a function that executes a task, and returns a `CommandResult`.

#### Sample Usage
```dart
basicCommand() {
    doSomething();
    return new CommandResult(events: [new DidSomethingEvent()]);
}

Commander commander = new Commander(event_bus);

// This will call doSomething(), and fire a DidSomethingEvent
commander.execute(basicCommand());
// Notice how 'basicCommand' is called before passing it to execute()
```

#### CommandResult
All the following properties of a `CommandResult` may be set in the constructor as named parameters (as shown above):

* `return_value : dynamic` -
The return value of a command. What will be returned in a `Future` when `Commander.execute()` is called.
Will return `null` by default.

* `events : List<Event>` -
A list of events the command should signal. `EventListeners` registered to the `Commander`'s `event_bus`
will be notified when the command is executed.

* `undoable : bool` -
Whether the command can be undone. If `true`, it must also assign an `EntityState` to the `state` parameter.

* `state : EntityState` -
A snapshot of the changes made by the command on some entity/object (described further below).
Only used when `undoable` is `true`.

* `execute_first : List<CommandResult>` -
A sequence of `CommandResults` that should be processed before the current command. Equivalent to calling
`commander.executeSequence(execute_first)`.


#### Commander
The object in charge of notifying the `EventBus` and Undo Stack of actions performed by `Commands`.
Each `Commander` instance must be instantiated with the `EventBus` it will send `Events` to.

* `execute(CommandResult result) : Future<dynamic>` -
Despite it's name, this does not actually call your `Command` function (you must call it yourself, as demonstrated
in the example above), it only propagates the result to the associated `EventBus` and logs any state changes to the
`UndoRedoService`. It will return whatever your `Command` listed as its `return_value`, wrapped in a `Future`.

> __Example:__ `commander.execute(squareCommand(2)).then((result) => result == 4)` will be `true`

* `executeSequence(List<CommandResult> results) : Future< List<dynamic> >` -
Executes a sequence of `Commands` in the order given. Returns a `Future` with a list of each command's `return_value`
in the order executed.

> __Example:__ `commander.executeSequence([squareCommand(2), squareCommand(3)])` will return `[4, 9]` inside a `Future`

* `event_bus : final EventBus` -
The `EventBus` all the command events will be sent to. Will have been defined in the constructor.

* `undo_service : UndoRedoService` -
The object in charge of managing state. A new `UndoRedoService` instance is created for each `Commander`.


### Undo/Redo
Undo functionality can be implemented easily once state management behaviors are encapsulated as `Command` functions.
The undo service provided is a standard linear, stack-like implementation using the [Memento Pattern](http://en.wikipedia.org/wiki/Memento_pattern).
Modifications made after an `undo()` call will overwrite any possible `redo()` states.

#### Undoable
Objects must implement the `Undoable` interface to work with the `UndoRedoService`. It only requires one method to be implemented:

 `restoreTo(EntityState state) : void`

This ensures that the object can understand and update itself from `EntityStates` when when requested to do so.

##### Sample Usage
```dart
class MyEntity implements Undoable {
    int id;
    String description;

    restoreTo(EntityState state) {
        id = state.getOrDefaultTo('id', id);
        description = state.getOrDefaultTo('description', description);
    }
}
```

#### EntityState
The 'memento' object used to store states on the Undo Stack. Requires a `Map` of an object's current state.

##### Sample Usage
```dart
changeDescriptionCommand(MyEntity entity, String new_description) {
    entity.description = new_description;
    EntityState<MyEntity> state = new EntityState.change(entity, {
        'description': entity.description
    });
    return new CommandResult(undoable: true, state: state);
}
```

* `EntityState<EntityType>({Undoable entity, Map<String, dynamic> state})` -
Default constructor, stores the original `entity` object alongside a `Map` of its properties.

* `EntityState.change(Undoable entity_object, Map<String, dynamic> state)` -
Identical to default constructor, used to explicitly denote state _changes_ of an entity
(i.e. only properties that have been changed should be included in the `state` map).

* `diff(EntityState other) : EntityState` -
Returns an `EntityState` with the values in `other` that are different from the current instance. _Example:_
```dart
var stateA = new EntityState(entity: my_entity, state: {'name': 'hello', 'id': 1});
var stateB = new EntityState(entity: my_entity, state: {'name': 'world', 'id': 1});

stateA.diff(stateB); // returns EntityState({'name': 'world'})
stateB.diff(stateA); // returns EntityState({'name': 'hello'})
```

* `getOrDefaultTo(String property, dynamic default_value) : dynamic` -
Checks whether the `EntityState` contains the `property` specified, otherwise returns the given `default_value`.

* `contains(String property) : bool` -
Checks whether the `EntityState` contains the `property` specified.

* `forEach(void f(property, value))` - Iterates over each property-value pair in the `EntityState`

* `properties : Set<String>` - The set of of the properties in the state

* `entity : Undoable` - The object the EntityState represents.


#### UndoRedoService
Each `Commander` instance manages an `UndoRedoService`. If you want to be able to undo states for certain components
separately, you should create a new `Commander` for each of the components whose state you wish to track. `UndoRedoServices`
can also be instantiated directly for manual `EntityState` management.

* `stack_size : int` - How many states are currently saved on the stack

* `canUndo : bool` - Whether calling `undo()` would be a valid operation in the current state

* `canRedo : bool` - Whether calling `redo()` would be a valid operation in the current state

* `recordState(EntityState state) : void` - Saves an `EntityState` onto the stack. Does not need to be called directly
when using a `Commander`

* `clear() : void` - Removes all the states currently stored on the stack

* `undo() : void` - Undoes the last command sent to the `Commander`

* `redo() : void` - Reapplies the last command that was undone


## Install

Add `event_commander` to your `pubspec.yaml` file to install it from pub:

    dependencies:
      event_commander: any

or keep up with the latest developments on this git repo:

    dependencies:
      event_commander:
        git: https://github.com/oblique63/EventCommander.git

then just run `$ pub get` and you'll be all set to go.

__EventCommander__ has no additional/external dependencies, does not rely on `dart:mirrors`, and is compatible with both _client-side_ and _server-side_ code.

### Import
For _Event Bus_ and _Event Queue_ features only:

`import 'package:event_commander/event_bus.dart';`


For _Event Bus_, _Event Queue_, and _Command/Undo_ features:

`import 'package:event_commander/event_commander.dart';`