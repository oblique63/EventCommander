part of event_commander.event_bus;

typedef void EventHandler(Event event);

class EventListener {
    EventHandler _handler;
    Type _listen_event;
    EventBus _listener_event_bus;

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