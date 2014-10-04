part of event_commander.event_bus;

typedef void EventHandler(Event event);

class EventListener {
    EventBus
        _listener_event_bus;
    Type
        _listen_event;
    EventHandler
        _handler;

    EventListener(this._listener_event_bus, this._listen_event, this._handler);

    Type get
    listening_to => _listen_event;

    EventHandler get
    handler => _handler;

    void
    stopListening() {
        _listener_event_bus.stopListener(this);
    }
}