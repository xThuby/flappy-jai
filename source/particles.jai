
Particle_Emitter :: struct {
    position : Vector2;
    velocity : Vector2;

    particles: [..] Particle;
    fadeout_period : float = 0.1;
    particles_per_second : float = 150;

    speed0 : float = 0;
    speed1 : float = 0.1;

    size0 : float = 0.001;
    size1 : float = 0.005;

    drag0 : float = 0.9999;
    drag1: float = 0.9;

    lifetime0: float = 0.4;
    lifetime1: float = 1.0;

    emitter_lifetime := -1.0;

    theta0: float = 0;
    theta1: float = TAU;

    color0: Color;
    color1: Color;

    elapsed : float = 0;
    remainder : float = 0;

    producing := true;
}

Particle :: struct {
    position: Vector2;
    velocity: Vector2;

    size     := 0.0;
    lifetime := 2.0;
    drag     := 1.0;

    elapsed  := 0.0;

    color:   Color;
}

deinit :: (emitter: *Particle_Emitter) {
    array_free(emitter.particles);
}

update_emitter :: (emitter: *Particle_Emitter) {
    sim_particle :: (p: *Particle, dt: float) {
       p.position += p.velocity * dt;

        // @Incomplete: Apply correct drag over time.
        p.velocity *= p.drag;
        p.elapsed  += time.delta;
    }

    for * p: emitter.particles {
        sim_particle(p, time.delta);

        if p.elapsed > p.lifetime {
            remove p;
        }
    }

    dt_per_particle := 1.0 / emitter.particles_per_second;

    emitter.elapsed += time.delta;
    emitter.remainder += time.delta;

    if emitter.emitter_lifetime >= 0 then {
        emitter.emitter_lifetime -= time.delta;
        if emitter.emitter_lifetime < 0 then emitter.producing = false;
    }


    spawn_particle :: (emitter: *Particle_Emitter) -> *Particle {
        p := array_add(*emitter.particles);

        p.position = emitter.position;
        p.velocity = emitter.velocity;

        p.size = random_get_within_range(emitter.size0, emitter.size1);
        p.drag = random_get_within_range(emitter.drag0, emitter.drag1);
        p.lifetime = random_get_within_range(emitter.lifetime0, emitter.lifetime1);

        color_t := random_get_within_range(0, 1);
        p.color = ColorLerp(emitter.color0, emitter.color1, color_t);

        speed := random_get_within_range(emitter.speed0, emitter.speed1);
        theta := random_get_within_range(emitter.theta0, emitter.theta1);

        ct := cos(theta);
        st := sin(theta);

        v_rel: Vector2 = ---;
        v_rel.x = speed * ct;
        v_rel.y = speed * st;

        p.velocity += v_rel;

        return p;
    }

    if emitter.producing then {
        while emitter.remainder > dt_per_particle {
            emitter.remainder -= dt_per_particle;
            p := spawn_particle(emitter);
            sim_particle(p, emitter.remainder);
        }
    } else {
        if emitter.particles.count == 0 then {
            array_ordered_remove_by_value(*live_emitters, emitter);  // Ordered remove, because we spawn some emitters in specific orders.
            deinit(emitter);
            free(emitter);
        }
    }
}


draw_emitter :: (emitter: *Particle_Emitter) {

    for * emitter.particles {
        alpha := 1.0;

        // Fade particle if it's time to do so.
        tail_time := it.lifetime - it.elapsed;
        if tail_time < emitter.fadeout_period {
            t := tail_time / emitter.fadeout_period;
            if t < 0 then t = 0;
            if t > 1 then t = 1;

            alpha = t;
        }

        c := it.color;
        c.a = xx (c.a * alpha);

        pos := it.position;
        s := it.size;
        src_rect := Rectangle.{0, 0, xx contrail_map.width, xx contrail_map.height};
        dst_rect := Rectangle.{pos.x-s/2.0, pos.y-s/2.0, s, s};
        DrawTexturePro(contrail_map, src_rect, dst_rect, .{0, 0}, 0, c);
    }
}
