part of event_commander.test;

class TestEntity implements Undoable {
    int id;
    String description;
    TestEntity(this.id, this.description);

    void
    restoreTo(EntityState<TestEntity> state) {
        id = state.getOrDefaultTo('id', id);
        description = state.getOrDefaultTo('description', description);
    }
}

basicCommand() {
    return new CommandResult(events: [new CommandEvent()]);
}

CommandResult<int>
squareCommand(int n) {
    return new CommandResult(return_value: n*n, events: [new CommandEvent()]);
}

saveEntityState(TestEntity entity) {
    var state = new EntityState(entity, {'id': entity.id, 'description': entity.description});
    return new CommandResult(undoable: true, state: state, events: [new CommandEvent()]);
}

modifyEntityId(TestEntity entity) {
    entity.id += 1;
    var state = new EntityState.change(entity, {'id': entity.id});
    return new CommandResult(undoable: true, state: state, events: [new CommandEvent()]);
}

saveAndModifyId(TestEntity entity) {
    var command_sequence = [
        saveEntityState(entity),
        modifyEntityId(entity)
    ];

    return new CommandResult(execute_first: command_sequence);
}

saveAndModifyIdTwice(TestEntity entity) {
    var prerequisite_commands = [ saveAndModifyId(entity) ];
    entity.id *= 3;

    return new CommandResult(execute_first: prerequisite_commands, events: [new CommandEvent()]);
}