part of event_commander.event_bus;

abstract class Event {
    Set<Type> parents = new Set.from([Event]);
    bool dispatched = false;
}
