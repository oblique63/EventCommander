part of event_commander.test;

class TestEvent extends Event {
    String description;
    TestEvent(this.description);
}

class ChildEvent extends TestEvent {
    ChildEvent(String description) : super(description) {
        this.parents.add(TestEvent);
    }
}

class AlternateEvent extends Event {
    int number;
    AlternateEvent(this.number);
}

class MultiEvent extends Event implements TestEvent, AlternateEvent {
    int number;
    String description;

    MultiEvent(this.number, this.description) {
        this.parents.addAll([TestEvent, AlternateEvent]);
    }
}

class CommandEvent extends Event {
}