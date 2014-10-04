part of event_commander;

typedef CommandResult Command();

/// A generic ReturnType can be listed, but it is only for documentation
class CommandResult<ReturnType> {
    bool undoable;
    EntityState state;
    List<Event> events;
    ReturnType return_value;

    CommandResult({this.undoable: false, this.state, this.events: const [], this.return_value: null});
}