part of event_commander;

/**
 * Classes intending to be used with the [UndoRedoService] must implement this
 * interface, so that its instances may be restored to states on the Undo Stack.
 */
abstract class Undoable {
    void restoreTo(EntityState state);
}

/**
 * An implementation of a [Memento](http://en.wikipedia.org/wiki/Memento_pattern)
 * for use by the [UndoRedoService].
 *
 * Used to store property values of objects. May represent the entire state
 * of an object, or only a partial state containing a subset of the object's
 * properties.
 *
 * Should only be used for classes that implement Undoable
 */
class EntityState<UndoableType extends Undoable> {
    UndoableType
        _original;
    Map
        _state = {};

    EntityState({UndoableType original, Map<String, dynamic> state}) :
        _original = original,
        _state = state;

    /// Use when saving partial states (i.e. not all the properties of an entity)
    EntityState.change(this._original, this._state);

    UndoableType get
    original => _original;

    Set get
    properties => _state.keys;

    operator
    [] (String key) => _state[key];

    bool
    contains(String key) => _state.containsKey(key);

    dynamic
    getOrDefaultTo(String key, default_value) => contains(key) ? _state[key] : default_value;

    void
    forEach(void f(property, value)) => _state.forEach(f);

    /// Creates a new EntityState only with the differences between this instance and the 'other' instance
    EntityState
    diff(EntityState other_state) {
        if (other_state.original != _original)
            throw "Evaluating changes from different objects is undefined";

        var changed_values = {};
        other_state.forEach((key, value) {
            if (this.contains(key) && this[key] != other_state[key])
                changed_values[key] = this[key];
        });

        return new EntityState.change(_original, changed_values);
    }

    toString() => "<${_original.runtimeType}>$_state";
}