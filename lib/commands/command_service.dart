part of event_commander;

abstract class CommandService {
    EventBus
        event_bus;
    UndoRedoService
        undo_service;

    Future<dynamic>
    execute(CommandResult command) {
        return new Future.sync(() => _processCommandResult(command));
    }

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

        if (command_result.events.isNotEmpty)
            command_result.events.forEach((event) => event_bus.signal(event));

        return command_result.return_value;
    }

    List<Type>
    _eventTypesFor(CommandResult command_result) => command_result.events.map((e) => e.runtimeType).toList();
}