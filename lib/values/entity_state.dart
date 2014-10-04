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
    final UndoableType
        _entity;
    final Map<String, dynamic>
        _state;

    EntityState(this._entity, this._state);

    /// Use when saving partial states (i.e. not all the properties of an entity)
    EntityState.change(this._entity, this._state);

    UndoableType get
    entity => _entity;

    Set get
    properties => _state.keys.toSet();

    operator
    [] (String property) => _state[property];

    bool
    contains(String property) => _state.containsKey(property);

    dynamic
    getOrDefaultTo(String property, default_value) => contains(property) ? _state[property] : default_value;

    void
    forEach(void f(property, value)) => _state.forEach(f);

    /// Creates a new EntityState only with the differences between this instance and the 'other' instance
    EntityState
    diff(EntityState other_state) {
        if (other_state.entity != _entity)
            throw "Evaluating state changes from different objects is undefined";

        var changed_values = {};
        other_state.forEach((key, value) {
            if (this.contains(key) && this[key] != other_state[key])
                changed_values[key] = this[key];
        });

        return new EntityState.change(_entity, changed_values);
    }

    String
    toString() {
        var entity_string = _entity != null ? _entity.runtimeType : 'EntityState';
        return "<$entity_string>$_state";
    }
}