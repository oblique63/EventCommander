part of event_commander.event_bus;

class EventBus {
    final Map < Type, List<EventHandler> >
        _event_subscribers = {};
    final Map< Type, StreamController<Event> >
        _controllers = {};
    bool
        suppress_warnings = false;

    /**
     * Subscribes [EventHandlers] to receive [Events] sent to the EventBus instance.
     * The given EventHandler will be called whenever an applicable Event is signaled.
     */
    EventListener
    on(Type event_type, EventHandler handler) {
        if (event_type == null)
            throw "EventHandler tried to register for 'null' event type";

        _addSubscriber(event_type, handler);

        if (!_hasController(event_type))
            _addControllerFor(event_type);

        return new EventListener(this, event_type, handler);
    }

    /// Sends the given [Event] to [EventHandlers] listening for events of that type
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

    /// Checks whether the given [EventListener] instance is registered with the EventBus instance.
    bool
    hasListener(EventListener listener) => _hasSubscriber(listener.listens_to, listener.handler);

    /**
     * Prevents the given [EventListener] (and its associated [EventHandler])
     * from being called and receiving further Events. This unregisters the
     * EventListener from the EventBus.
     */
    void
    stopListener(EventListener listener) {
        Type event_type = listener.listens_to;
        EventHandler handler = listener.handler;

        if (_hasSubscriber(event_type, handler))
            _event_subscribers[event_type].remove(handler);
    }

    // TODO: implement resumeListener(EventListener), to reuse existing listener instances

    /// Unregisters all active [EventListeners] from the EventBus
    void
    clearAllListeners() {
        _event_subscribers.forEach((event, subscription_list) => subscription_list.clear());
    }


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
        if (event.dispatched) return;

        var event_types = _eventsToSignal(event);
        var called_handlers = [];
        var logged_warning = false;

        event_types.forEach((event_type) {
            if (_event_subscribers.containsKey(event_type)) {

                for (EventHandler handler in _event_subscribers[event_type]) {
                    if (!called_handlers.contains(handler)) {
                        handler(event);
                        called_handlers.add(handler);
                    }
                    else if (!suppress_warnings && !logged_warning) {
                        print("WARNING: Same EventHandler function/instance added for multiple events in $event_types");
                        logged_warning = true;
                    }
                }
            }
        });

        event.dispatched = true;
    }

    List<Type>
    _eventsToSignal(Event event) {
        var events = new List.from(event.parents);
        events.add(event.runtimeType);
        return events.reversed.toList();
    }
}