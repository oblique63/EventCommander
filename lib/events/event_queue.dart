part of event_commander.event_bus;

class EventQueue<EventType extends Event> {
    Queue<EventType>
        _queue = new Queue();
    EventListener
        _listener;

    /**
     * Note: Event types specified using generics will override any values passed to the 'queue_on' parameter
     */
    EventQueue(EventBus event_bus, {Type queue_on: Event}) {
        if (EventType != dynamic) {
            _listener = event_bus.on(EventType, (event) => _queue.addLast(event));
        }
        else {
            _listener = event_bus.on(queue_on, (event) => _queue.addLast(event));
        }
    }

    int get
    length => _queue.length;

    /// What type of [Events] get added to the queue
    Type get
    queues_on => _listener.listens_to;

    bool get
    isActive => _listener.isActive;

    bool get
    isEmpty => _queue.isEmpty;

    bool get
    hasNext => !_queue.isEmpty;

    /// Get the Event at the start of the queue
    EventType
    peekNext() => _queue.first;

    /// Get the Event at the end of the queue
    EventType
    peekLast() => _queue.last;

    /// Remove and return the Event at the start of the queue
    EventType
    popNext() => _queue.removeFirst();

    /// Remove and return the Event at the end of the queue
    EventType
    popLast() => _queue.removeLast();

    void
    clear() => _queue.clear();

    void
    stopReceivingEvents() => _listener.stopListening();

    String
    toString() {
        var queue_type = "EventQueue<$queues_on>";
        var events = _queue.map((Event e) => e.runtimeType);
        return "$queue_type$events";
    }
}
