
Player :: struct {
    #as using base: Entity;
    speed: Vector2;
    sprite: Sprite;

    emitter: *Particle_Emitter;

    move_started: bool;
    radius: float;
}

init_player :: (player: *Player, x: float, y: float) {
    player.x = x + 8;
    player.y = y + 8;

    player.sprite = make_sprite("data/sprites/player.png");
    player.sprite.origin = .{.5, .5};
    player.radius = 3;

    {
        player.emitter = New(Particle_Emitter);
        using player.emitter;

        position = player.position;

        fadeout_period = .2;
        particles_per_second = 100;

        speed0 = 5;
        speed1 = 10;

        size0 = 0.008;
        size1 = 0.010;

        lifetime0 = 0.2;
        lifetime1 = 1.4;

        color0 = ColorLerp(BLACK, WHITE, 0.75);
        color1 = ColorLerp(BLACK, WHITE, 0.25);

        array_add(*live_emitters, player.emitter);
    }
}

update_player :: (using player: *Player) {
    speed.y += gravity * time.delta;
    position += speed * time.delta;

    if input.jump.down {
        consume_buffer(*input.down);
        speed.y = jump_speed;
    }

    emitter.position = position;
}

draw_player :: (using player: *Player) {
    draw_sprite(sprite, position, .{32, 32});
}

#scope_file

move_speed:     float : 200;
jump_speed:     float : -800;
gravity:        float : 1000;
