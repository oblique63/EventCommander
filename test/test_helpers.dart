part of event_commander.test;

after(future, void expectThings(return_value)) {
    if (future is List) {
        future = Future.wait(future, eagerError: true);
    }
    else if (future is! Future) {
        future = new Future(() => future);
    }

    expect(future, completion((return_value) {
        expectThings(return_value);
        return true;
    }));
}