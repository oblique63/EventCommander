part of event_commander.test;

class TestEntity {
    int id;
    String description;
    TestEntity(this.id, this.description);
}

basicCommand() {
    return new CommandResult(events: [new CommandEvent()]);
}

messageCommand(String message) {
    logMessage(message);
    return new CommandResult(events: [new CommandEvent()]);
}

CommandResult<int>
squareCommand(int n) {
    return new CommandResult(return_value: n*n, events: [new CommandEvent()]);
}