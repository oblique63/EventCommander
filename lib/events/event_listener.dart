part of event_commander.event_bus;

/**
 * The function that gets called whenever an [Event] is signaled
 * by the [EventBus].
 */
typedef void EventHandler(Event event);

/**
 * Container for EventHandlers that are registered to an [EventBus].
 * Manages the EventHandler's subscription to Events.
 */
class EventListener {
    EventBus
        _listener_event_bus;
    Type
        _listen_event;
    EventHandler
        _handler;

    EventListener(this._listener_event_bus, this._listen_event, this._handler);

    Type get
    listens_to => _listen_event;

    EventHandler get
    handler => _handler;

    bool get
    isActive => _listener_event_bus.hasListener(this);

    void
    stopListening() {
        _listener_event_bus.stopListener(this);
    }
}