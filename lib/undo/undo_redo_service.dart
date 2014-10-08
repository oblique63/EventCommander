part of event_commander;

/**
 * The undo service provided is a standard linear, stack-like implementation using the
 * [Memento Pattern](http://en.wikipedia.org/wiki/Memento_pattern). Modifications made
 * after an `undo()` call will overwrite any possible `redo()` states.
 */
class UndoRedoService {
    final _StateStack
        _state_stack;

    UndoRedoService() : _state_stack = new _StateStack();

    /// The number of states currently stored in the Undo Stack
    int get
    stack_size => _state_stack.saved_states;

    bool get
    isEmpty => _state_stack.isEmpty;

    bool get
    canUndo => !isEmpty;

    bool get
    canRedo => _state_stack.canMoveForward;

    /// Adds a state onto the stack
    void
    recordState(EntityState state) => _state_stack.add(state);

    void
    undo() => _state_stack.moveBack();

    void
    redo() => _state_stack.moveForward();

    /// Removes all states stored on the stack
    void
    clear() => _state_stack.clear();

    String
    toString({int show, bool latest_first: true}) =>
            "UndoStates >> ${_state_stack.toString(show: show, latest_first: latest_first)}";
}