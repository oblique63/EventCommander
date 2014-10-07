part of event_commander.event_bus;

abstract class Event {
    /// The set of Events whose listeners will also be notified on calling this Event type
    Set<Type>
        parents = new Set.from([Event]);

    /// Whether the Event has been sent to all it's listeners yet
    bool
        dispatched = false;
}
