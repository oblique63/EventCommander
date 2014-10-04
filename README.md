Event Commander
===============

[![Build Status](https://drone.io/github.com/oblique63/EventCommander/status.png)](https://drone.io/github.com/oblique63/EventCommander/latest)

An EventBus, EventQueue, [Command Pattern](http://en.wikipedia.org/wiki/Command_pattern), and Undo-Redo library for [Dart](https://www.dartlang.org/).

##### Conventions
Throughout this doc, properties/methods of classes will be listed in the following format:

`property_or_method : [modifiers] Type/ReturnType`


## Event Bus
The `EventBus` is the backbone for all of the Command/Undo communication behind the scenes,
but may be used on its own to fire and listen to (a.k.a. 'publish/subscribe') Events.

#### Basic usage

```dart
var event_bus = new EventBus();

event_bus.on(MyEventType, (MyEventType event) => doSomething());
...
event_bus.signal(new MyEventType()); // doSomething() will be called
```

#### EventHandler
A function that accepts an `Event`, and is meant to be called whenever an event of the appropriate type is fired.

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

```dart
var queue = new EventQueue(event_bus, queue_on: MyEvent);

// Alternative declaration using generics (yields same result as above)
var queue = new EventQueue<MyEvent>(event_bus);
// Note: Event types specified using generics will override any values passed to the 'queue_on' parameter
```

#### Sample usage
```dart
while(true) {
    if (event_queue.hasNext) {
       Event event = event_queue.popNext();
       doSomethingWith(event);
       ...
       // Alternatively, you do not have to remove the events from the queue to examine them:
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
```

Events support a multiple-inheritance scheme whereby listeners for a particular Event Type
may also be notified of other Events implementing/extending that Event Type interface.
This is accomplished by adding super-class/parent events to a `Set<Type> parents` property
in your `Event` class.

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
    this.parents.addAll([MyEvent, MyOtherEvent]);
  }
}
...
event_bus.on(MyEvent, (MyEvent e) => doA(e.description));
event_bus.on(MyOtherEvent, (MyOtherEvent e) => doB(e.number));
...
event_bus.signal(new MultiEvent(1, 'event')); // triggers both doA() and doB()
```


## Commands
A `Command` is just a function that executes a task, and returns a `CommandResult`.

#### Sample Usage
```dart
basicCommand() {
    doSomething();
    return new CommandResult(events: [new DidSomethingEvent()]);
}
...
Commander commander = new Commander(event_bus);
...
// This will call doSomething(), and fire a DidSomethingEvent
commander.execute(basicCommand());
// Notice how 'basicCommand' is called before passing it to execute()
```

#### CommandResult
All the following properties of a `CommandResult` may be set in the constructor as named parameters (as shown above):

* `return_value : dynamic` -
The return value of a command. What will be returned in a `Future` when `Commander.execute()` is called.

* `events : List<Event>` -
A list of events the command should signal. `EventListeners` registered to the `Commander`'s `event_bus`
will be notified when the command is executed.

* `undoable : bool` -
Whether the command can be undone. If `true`, it must also assign an `EntityState` to the `state` parameter.

* `state : EntityState` -
A snapshot of the changes made by the command on some entity/object (described further below).
Only used when `undoable` is `true`.


#### Commander
The object in charge of notifying the `EventBus` and Undo Stack of actions performed by `Commands`.
Each `Commander` instance must be instantiated with the `EventBus` it will send `Events` to.

* `execute(CommandResult result) : Future<dynamic>` -
Despite it's name, this does not actually call your `Command` function (you must call it yourself, as demonstrated
in the example above), it only propagates the result to the associated `EventBus` and logs any state changes to the
`UndoRedoService`. It will return whatever your `Command` listed as its `return_value`, wrapped in a `Future`.
  * _Example:_ `commander.execute(squareCommand(2)).then((result) => result == 4)` will be `true`

* `executeSequence(List<CommandResult> results) : Future< List<dynamic> >` -
Executes a sequence of `Commands` in the order given. Returns a `Future` with a list of each command's `return_value`
in the order executed.
  * _Example:_ `commander.executeSequence([squareCommand(2), squareCommand(3)])` will return `[4, 9]` inside a `Future`

* `event_bus : final EventBus` -
The `EventBus` all the command events will be sent to. Will have been defined in the constructor.

* `undo_service : UndoRedoService` -
The object in charge of managing state. A new `UndoRedoService` instance is created for each `Commander`.


### Undo/Redo
Undo functionality can be implemented easily once state management behaviors are encapsulated as `Command` functions.
The undo service provided is a standard linear, stack-like implementation using the [Memento Pattern](http://en.wikipedia.org/wiki/Memento_pattern).
Modifications made after an `undo()` call will overwrite any possible `redo()` states.

#### Undoable
TODO

#### EntityState
TODO

#### UndoRedoService
Each `Commander` instance manages an `UndoRedoService`. If you want to be able to undo states for certain components
separately, you should create a new `Commander` for each of the components whose state you wish to track.

## Install

Add `event_commander` to your `pubspec.yaml` file to install it from pub:

    dependencies:
      event_commander: any

or keep up with the latest developments on this git repo:

    dependencies:
      event_commander:
        git: https://github.com/oblique63/EventCommander.git

then just run `$ pub get` and you'll be all set to go.

__EventCommander__ has no additional/external dependencies, and is compatible with both client-side and server-side code.

### Import
For _Event Bus_ and _Event Queue_ features only:

`import 'package:event_commander/event_bus.dart';`


For _Event Bus_, _Event Queue_, and _Command/Undo_ features:

`import 'package:event_commander/event_commander.dart';`