from caravan import Server,Task

with Server.start():
    t = Task.create("cat _input.json > _output.json", {"foo":1, "bar":2, "baz":3})
    Server.await_task(t)
    print(t.output())
