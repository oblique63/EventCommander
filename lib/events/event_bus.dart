part of event_commander.event_bus;

class EventBus {
    final Map < Type, List<EventHandler> >
        _event_subscribers = {};
    final Map< Type, StreamController<Event> >
        _controllers = {};

    EventListener
    on(Type event_type, EventHandler handler) {
        _addSubscriber(event_type, handler);

        if (!_hasControllerFor(event_type))
            _addControllerFor(event_type);

        return new EventListener(this, event_type, handler);
    }

    Future
    signal(Event event) {
        return new Future.sync(() {
            var event_type = event.runtimeType;
            if (_hasControllerFor(event_type))
                _controllers[event_type].add(event);
        });
    }

    void
    stopListener(EventListener listener) {
        Type event_type = listener.listening_to;
        EventHandler handler = listener.handler;

        if (_hasSubscriber(event_type, handler))
            _event_subscribers[event_type].remove(handler);
    }

    void
    clearAllListeners() {
        _event_subscribers.forEach((event, subscription_list) => subscription_list.clear());
    }

    void
    reset() {
        _event_subscribers.clear();
        _controllers.clear();
    }

    bool
    hasListener(EventListener listener) => _hasSubscriber(listener.listening_to, listener.handler);


    _hasSubscriber(Type event_type, EventHandler handler) =>
        _event_subscribers.containsKey(event_type) &&
        _event_subscribers[event_type].contains(handler);

    _addSubscriber(Type event_type, handler) {
        _event_subscribers.putIfAbsent(event_type, () => []);
        _event_subscribers[event_type].add(handler);
    }

    _hasControllerFor(Type event_type) => _controllers.containsKey(event_type);

    _addControllerFor(Type event_type) {
        // Creating this many controllers may or may not be a source of performance issues later...
        _controllers[event_type] = new StreamController<Event>();
        _controllers[event_type].stream.listen(_dispatchEvent);
    }

    _dispatchEvent(Event event) {
        var event_types = new List.from(event.parents)..add(event.runtimeType)..reversed;

        event_types.forEach((event_type) {
            if (_event_subscribers.containsKey(event_type))
                _event_subscribers[event_type].forEach((EventHandler subscriber) => subscriber(event));
        });
    }
}