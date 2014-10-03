part of event_commander;


abstract class Undoable {
    void
    restoreFrom(EntityState state);
}

class EntityState<UndoableType extends Undoable> {
    UndoableType
        _original;
    Map
        _state = {};

    EntityState({UndoableType original, Map<String, dynamic> state}) :
        _original = original,
        _state = state;

    EntityState.change(this._original, this._state);

    UndoableType get
    original => _original;

    operator
    [] (String key) => _state[key];

    bool
    contains(String key) => _state.containsKey(key);

    Set get
    properties => _state.keys;

    void
    forEach(void f(property, value)) => _state.forEach(f);

    EntityState
    changedFrom(EntityState other_state) {
        if (other_state.original != _original)
            throw "Evaluating changes from different objects is undefined";

        var changed_values = {};
        other_state.forEach((key, value) {
            if (this.contains(key) && this[key] != other_state[key])
                changed_values[key] = this[key];
        });

        return new EntityState.change(_original, changed_values);
    }

    toString() => "$_state";
}