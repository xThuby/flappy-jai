#import "Basic";
#import "Math";

/*
    A collection of very handy easing functions.
    Made the names more sensible and ported to The Language (Jai) by @xThuby
    Original C# source: https://gist.github.com/Fonserbc/3d31a25e87fdaa541ddf
*/

#scope_file
s : float = 1.70158;
s2 : float = 2.5949095;

mix :: (a: float, b: float, t: float) -> float {
    return (1.0-t) * a + t * b;
}

#scope_export

smooth2_start :: (t: float) -> float {
    return t * t;
}

smooth2_stop :: (t: float) -> float {
    return 1.0 - (1.0 - t) * (1.0 - t);
}

smooth3_start :: (t: float) -> float {
    return t * t * t;
}

smooth3_stop :: (t: float) -> float {
    return 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t);
}

smooth3_step :: (t: float) -> float {
    start := t * t * t;
    stop := 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t);
    return (1.0 - t) * start + t * stop;
}

smooth4_start :: (t: float) -> float {
    return t * t * t * t;
}

smooth4_stop :: (t: float) -> float {
    return 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t) * (1.0 - t);
}

smooth4_step :: (t: float) -> float {
    start := t * t * t * t;
    stop := 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t) * (1.0 - t);
    return (1.0 - t) * start + t * stop;
}

smooth5_start :: (t: float) -> float {
    return t * t * t * t * t;
}

smooth5_stop :: (t: float) -> float {
    return 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t) * (1.0 - t) * (1.0 - t);
}

smooth5_step :: (t: float) -> float {
    start := t * t * t * t * t;
    stop := 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t) * (1.0 - t) * (1.0 - t);
    return (1.0 - t) * start + t * stop;
}

sinus_start :: (t: float) -> float {
    return 1.0 - cos(t * PI / 2.0);
}

sinus_stop :: (t: float) -> float {
    return sin(t * PI / 2.0);
}

sinus_step :: (t: float) -> float {
    return 0.5 * (1.0 - cos(PI * t));
}

expo_start :: (t: float) -> float {
    return ifx t == 0.0 then 0.0 else pow(1024.0, t - 1.0);
}

expo_stop :: (t: float) -> float {
    return ifx t == 1.0 then 1.0 else 1.0 - pow(2.0, -10.0 * t);
}

expo_step :: (t: float) -> float {
    if (t == 0.0)
        return 0.0;
    if (t == 1.0)
        return 1.0;
    t2 := t * 2.0;
    if (t2 < 1.0) {
        return 0.5 * pow(1024.0, t2 - 1.0);
    }
    return 0.5 * (-pow(2.0, -10.0 * (t2 - 1.0)) + 2.0);
}

elastic_start :: (t: float) -> float {
    if (t == 0)
        return 0;
    if (t == 1)
        return 1;

    t2 := t - 1.0;
    return -pow(2.0, 10.0 * t2) * sin((t2 - 0.1) * (2.0 * PI) / 0.4);
}

elastic_stop :: (t: float) -> float {
    if (t == 0)
    return 0;
    if (t == 1)
    return 1;
    return pow(2.0, -10.0 * t) * sin((t - 0.1) * (2.0 * PI) / 0.4) + 1.0;
}

elastic_step :: (t: float) -> float {
    t2 := t * 2;
    if (t2 < 1.0) {
        t2 -= 1.0;
        return -0.5
        * pow(2.0, 10.0 * t2)
        * sin((t2 - 0.1) * (2.0 * PI) / 0.4);
    }
    t2 -= 1.0;
    return pow(2.0, -10.0 * t2) * sin((t2 - 0.1) * (2.0 * PI) / 0.4) * 0.5 + 1.0;
}

back_start :: (t: float) -> float {
    return t * t * ((s + 1.0) * t - s);
}

back_stop :: (t: float) -> float {
    return 1.0 - back_start(1.0-t);
}

back_step :: (t: float) -> float {
    t2 := t*2;
    if (t2 < 1.0) {
        return 0.5 * (t2 * t2 * ((s2 + 1.0) * t2 - s2));
    }
    t2 -= 2.0;
    return 0.5 * (t2 * t2 * ((s2 + 1.0) * t2 + s2) + 2.0);
}

bounce_start :: (t: float) -> float {
    return 1.0 - bounce_stop(1.0 - t);
}

bounce_stop :: (t: float) -> float {
    if (t < (1 / 2.75)) {
        return 7.5625 * t * t;
    } else if (t < (2 / 2.75)) {
        t2 := t - (1.5 / 2.75);
        return 7.5625 * (t2) * t2 + 0.75;
    } else if (t < (2.5 / 2.75)) {
        t2 := t - (2.25 / 2.75);
        return 7.5625 * t2 * t2 + 0.9375;
    } else {
        t2 := t - (2.625 / 2.75);
        return 7.5625 * t2 * t2 + 0.984375;
    }
}

bounce_step :: (t: float) -> float {
    if (t < 0.5) {
        return bounce_start(t * 2) * 0.5;
    }
    return bounce_stop(t * 2 - 1) * 0.5 + 0.5;
}
