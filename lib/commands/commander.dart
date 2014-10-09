part of event_commander;

/**
 * In charge of notifying the [EventBus] and [UndoRedoService] of actions performed by [Commands].
 */
class Commander {
    final EventBus
        event_bus;
    final UndoRedoService
        undo_service;
    bool
        suppress_warnings = false;

    Commander(this.event_bus) : undo_service = new UndoRedoService();

    /// Future returns the `return_value` specified by the [CommandResult] instance
    Future<dynamic>
    execute(CommandResult command) {
        return _processCommandResult(command);
    }


    /**
     * Executes the given sequence of Commands in order.
     * Future returns a List of the `return_value`s specified by each of the [CommandResult] instances
     */
    Future<List>
    executeSequence(List<CommandResult> commands) {
        return Future.wait(commands.map((command) => _processCommandResult(command)));
    }

    Future<dynamic>
    _processCommandResult(CommandResult command_result) {
        return _executePrerequisites(command_result)
        .then((_) => _recordCommandState(command_result))
        .then((_) => _signalCommandEvents(command_result))
        .then((_) => command_result.return_value);
    }

    Future
    _executePrerequisites(CommandResult command_result) {
        return executeSequence(command_result.execute_first);
    }

    Future
    _signalCommandEvents(CommandResult command_result) {
        return Future.forEach(command_result.events, (event) => event_bus.signal(event));
    }

    Future
    _recordCommandState(CommandResult command_result) {
        return new Future(() {
            if (command_result.undoable) {
                if (command_result.state == null)
                    throw "Undoable command for [${_eventTypesFor(command_result).join(", ")}] must declare an EntityState in its CommandResult";

                undo_service.recordState(command_result.state);
            }
            else if (command_result.state != null && !suppress_warnings) {
                print("[Commander] WARNING: Non-undoable Command contains an EntityState: ${command_result.state}");
            }
        });
    }

    List<Type>
    _eventTypesFor(CommandResult command_result) => command_result.events.map((e) => e.runtimeType).toList();
}