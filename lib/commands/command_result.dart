part of event_commander;

typedef CommandResult Command();

/// A generic ReturnType can be listed, but it is only for documentation
class CommandResult<ReturnType> {
    List<Event>
        events;
    ReturnType
        return_value;
    bool
        undoable;
    EntityState
        state;

    CommandResult({this.events: const [], this.return_value: null, this.undoable: false, this.state});
}