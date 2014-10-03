part of event_commander;

class Commander extends Object with CommandService {
    final EventBus
        event_bus;
    final UndoRedoService
        undo_service = new UndoRedoService();

    Commander(this.event_bus);
}