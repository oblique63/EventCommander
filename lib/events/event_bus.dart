part of event_commander.event_bus;

class EventBus {
    final Map < Type, List<EventHandler> >
        _event_subscribers = {};
    final Map< Type, StreamController<Event> >
        _controllers = {};

    EventListener
    on(Type event_type, EventHandler handler) {
        _addSubscriber(event_type, handler);

        if (!_hasController(event_type))
            _addControllerFor(event_type);

        return new EventListener(this, event_type, handler);
    }

    Future
    signal(Event event) {
        return new Future.sync(() {
            var event_types = _eventsToSignal(event);

            if (event_types.any(_hasController)) {
                var to_signal = event_types.firstWhere(_hasController);
                _controllers[to_signal].add(event);
            }
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

    bool
    hasListener(EventListener listener) => _hasSubscriber(listener.listening_to, listener.handler);

    bool
    _hasController(Type event_type) => _controllers.containsKey(event_type);

    bool
    _hasSubscriber(Type event_type, EventHandler handler) =>
        _event_subscribers.containsKey(event_type) &&
        _event_subscribers[event_type].contains(handler);

    void
    _addSubscriber(Type event_type, handler) {
        _event_subscribers.putIfAbsent(event_type, () => []);
        _event_subscribers[event_type].add(handler);
    }

    void
    _addControllerFor(Type event_type) {
        // Creating this many controllers may or may not be a source of performance issues later...
        _controllers[event_type] = new StreamController<Event>();
        _controllers[event_type].stream.listen(_dispatchEvent);
    }

    void
    _dispatchEvent(Event event) {
        if (!event.dispatched) {
            var event_types = _eventsToSignal(event);

            event_types.forEach((event_type) {
                if (_event_subscribers.containsKey(event_type))
                    _event_subscribers[event_type].forEach((EventHandler subscriber) => subscriber(event));
            });

            event.dispatched = true;
        }
    }

    List<Type>
    _eventsToSignal(Event event) {
        return new List.from(event.parents)
            ..add(event.runtimeType)
            ..reversed;
    }
}