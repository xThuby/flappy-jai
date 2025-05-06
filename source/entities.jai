

Entity_Flags :: enum u32 {
    NONE;
    HIDDEN;
}

Entity :: struct {
    id: u64; @NoSerialize
    name: string; @NoSerialize
    active: bool; @NoSerialize
    flags: Entity_Flags;
    x, y: float;
    #place x;
    position: Vector2; @NoSerialize
}

