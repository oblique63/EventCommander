part of event_commander;


typedef CommandResult Command();

/**
 * The object that must be returned by [Commands] to properly process them.
 * The data stored in this object will be used to notify the [EventBus] of [Events],
 * and the [UndoRedoService] of state changes.
 *
 * A generic ReturnType can be listed to show what `Commander.execute()` will return
 * in a [Future], but it is only for documentation
 */
class CommandResult<ReturnType> {
    final List<Event>
        events;
    final ReturnType
        return_value;
    final bool
        undoable;
    final EntityState
        state;
    final List<CommandResult>
        execute_first;

    CommandResult({this.events: const [], this.return_value: null, this.undoable: false, this.state, this.execute_first: const []});
}