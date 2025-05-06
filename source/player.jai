
Player :: struct {
    #as using base: Entity;
    speed: Vector2;
    sprite: Sprite;

    emitter: *Particle_Emitter;

    move_started: bool;
    radius: float;
}

init_player :: (player: *Player, x: float, y: float) {
    player.x = x;
    player.y = y;

    player.sprite = make_sprite("data/sprites/player.png");
    player.sprite.origin = .{.5, .5};
    player.radius = 3;

    {
        player.emitter = New(Particle_Emitter);
        using player.emitter;

        position = player.position;

        fadeout_period = .2;
        particles_per_second = 100;

        speed0 = .2;
        speed1 = .5;

        size0 = 0.20;
        size1 = 0.35;

        lifetime0 = 0.2;
        lifetime1 = 1.4;

        color0 = ColorLerp(BLACK, WHITE, 0.75);
        color1 = ColorLerp(BLACK, WHITE, 0.25);

        array_add(*live_emitters, player.emitter);
    }
}

blah: float = 0;
update_player :: (using player: *Player) {
    // speed.y += gravity * time.delta;
    // position += speed * time.delta;
    //
    // if input.jump.down {
    //     consume_buffer(*input.down);
    //     speed.y = jump_speed;
    // }
    c := cos(time.now * PI * .5);
    s := sin(time.now * PI * .5);
    player.position.y = c * playfield_height / 2;
    player.position.x = s * playfield_width / 2;

    emitter.position = position;
}

draw_player :: (using player: *Player) {
    draw_sprite(sprite, position, .{1, 1});
}

#scope_file

move_speed:     float : 200;
jump_speed:     float : -160;
gravity:        float : 200;
