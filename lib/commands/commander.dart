part of event_commander;

/**
 * In charge of notifying the [EventBus] and [UndoRedoService] of actions performed by [Commands].
 */
class Commander {
    final EventBus
        event_bus;
    final UndoRedoService
        undo_service = new UndoRedoService();

    Commander(this.event_bus);

    /// Future returns the `return_value` specified by the [CommandResult] instance
    Future<dynamic>
    execute(CommandResult command) {
        return new Future.sync(() => _processCommandResult(command));
    }


    /**
     * Executes the given sequence of Commands in order.
     * Future returns a List of the `return_value`s specified by each of the [CommandResult] instances
     */
    Future<List>
    executeSequence(List<CommandResult> commands) {
        return new Future.sync(() {
            var results = [];
            commands.forEach((command) => results.add( _processCommandResult(command) ));
            return results;
        });
    }

    dynamic
    _processCommandResult(CommandResult command_result) {
        if (command_result.undoable) {
            if (command_result.state == null)
                throw "Undoable command for [${_eventTypesFor(command_result).join(", ")}] must declare an EntityState in its CommandResult";

            undo_service.recordState(command_result.state);
        }
        else if (command_result.state != null) {
            throw "Non-undoable Command contained an EntityState: ${command_result.state}";
        }

        if (command_result.events.isNotEmpty)
            command_result.events.forEach((event) => event_bus.signal(event));

        return command_result.return_value;
    }

    List<Type>
    _eventTypesFor(CommandResult command_result) => command_result.events.map((e) => e.runtimeType).toList();
}