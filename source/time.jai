

Time_State :: struct {
    unscaled_delta: float;
    delta: float;
    now: float;
    last: float;

    time_scale: float = 1.0;
}

time_init :: (frame_rate: int) {
    SetTargetFPS(xx frame_rate);
}

time_update :: () {
    using time;

    now = xx GetTime();
    unscaled_delta = (now - last);
    delta = unscaled_delta * time_scale;
    last = now;
}
