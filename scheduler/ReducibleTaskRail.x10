package scheduler;

public struct ReducibleTaskRail implements Reducible[Rail[Task]] {

    public def zero():Rail[Task] = new Rail[Task]();
    
    public operator this(a:Rail[Task], b:Rail[Task]):Rail[Task] {
        if(a.size == 0L) return b;
        if(b.size == 0L) return a;
        val result = new Rail[Task](a.size+b.size);
        Rail.copy(a, 0, result, 0, a.size);
        Rail.copy(b, 0, result, a.size, b.size);
        return result;
    }
}

