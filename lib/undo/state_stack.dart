part of event_commander;

/**
 * Linear Undo/Redo stack implementation.
 */
class _StateStack {
    final List<EntityState>
        _saved_states = [];
    int
        _state_position = -1;

    int get
    saved_states => _saved_states.length;

    bool get
    isEmpty => _saved_states.isEmpty;

    bool get
    canMoveForward => _state_position < _saved_states.length-1;

    bool get
    canMoveBack => saved_states > 1;

    void
    add(EntityState state) {
        if (_state_position < saved_states-1) {
            _saved_states.removeRange(_state_position, saved_states-1);
        }
        _saved_states.add(state);
        _state_position += 1;
    }

    void
    moveBack() {
        if (!canMoveBack)
            throw "No previous state in Undo stack";

        _restoreStateTo(_state_position - 1);
    }

    void
    moveForward() {
        if (!canMoveForward)
            throw "Already in last state of Undo stack";

        _restoreStateTo(_state_position + 1);
    }

    void
    clear() {
        _state_position = -1;
        _saved_states.clear();
    }

    _restoreStateTo(int new_state_position) {
        var current_state = _saved_states[_state_position];
        var requested_state = _saved_states[new_state_position];
        Undoable object = current_state.entity;
        EntityState new_state = requested_state.diff(current_state);

        object.restoreTo(new_state);
        _state_position = new_state_position;
    }

    String
    toString({int show, bool latest_first: true}) {

        var output = "Position: $_state_position, Stack";
        var print_states = _saved_states;

        if (latest_first) {
            output += " (bottom->top)";
            print_states = _saved_states.reversed;
        }
        output += ":\n\t";

        if (show != null && show > 1) {
            print_states = print_states.getRange(0, show);
        }

        return output + "${print_states.join('\n\t')}";
    }
}