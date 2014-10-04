part of event_commander.test;

class TestEntity extends Undoable {
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
    return new CommandResult(return_value: n*n);
}

saveEntityState(TestEntity entity) {
    var state = new EntityState(original: entity, state: {'id': entity.id, 'description': entity.description});
    return new CommandResult(undoable: true, state: state);
}

modifyEntityId(TestEntity entity) {
    entity.id += 1;
    var state = new EntityState.change(entity, {'id': entity.id});
    return new CommandResult(undoable: true, state: state);
}