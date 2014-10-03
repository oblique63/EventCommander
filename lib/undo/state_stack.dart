part of event_commander;

class _StateStack {
    List<EntityState>
        _saved_states = [];
    int
        _state_position = -1;

    int get
    saved_states => _saved_states.length;

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
        if (_state_position-1 < 0)
            throw "No previous state in Undo stack";

        _restoreStateTo(_state_position - 1);
    }

    void
    moveForward() {
        if (_state_position+1 >= _saved_states.length)
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
        Undoable object = current_state._original;
        EntityState new_state = requested_state.changedFrom(current_state);

        object.restoreFrom(new_state);
        _state_position = new_state_position;
    }
}