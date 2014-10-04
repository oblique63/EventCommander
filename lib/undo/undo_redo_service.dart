part of event_commander;

class UndoRedoService {
    final _StateStack
        _state_stack;

    UndoRedoService() : _state_stack = new _StateStack();

    int get
    stack_size => _state_stack.saved_states;

    bool get
    isEmpty => _state_stack.isEmpty;

    bool get
    canUndo => !isEmpty;

    bool get
    canRedo => _state_stack.canMoveForward;

    void
    recordState(EntityState state) => _state_stack.add(state);

    void
    undo() => _state_stack.moveBack();

    void
    redo() => _state_stack.moveForward();

    void
    clear() => _state_stack.clear();
}