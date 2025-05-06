
// Simple copy paste from jai, but Vectors are ints
Vector2Int :: struct {
    x, y: int;

    #place x;
    component: [2] int = ---;
}

random_range :: (min: $T, max: T) -> T
#modify {
    ti := cast(*Type_Info)T;
    if ti.type == .INTEGER || ti.type == .FLOAT {
        return true;
    }
    return false, "Unsupported argument type to random_range.";
} {
    return cast(T)random_get_within_range(cast(float) min, cast(float) max);
}

to_vector2 :: (vector2_int: Vector2Int) -> Vector2 {
    return Vector2.{cast(float) vector2_int.x, cast(float) vector2_int.y};
}

sign :: (val: $T) -> int
#modify {
    ti := cast(*Type_Info)T;
    if ti.type == .INTEGER || ti.type == .FLOAT {
        return true;
    }
    return false, "Unsupported argument type to random_range.";
}{
    if val < 0 {
        return -1;
    }
    return 1;
}

approach :: (from: *float, target: float, max_delta: float) {
    if from.* > target {
        from.* = max(from.* - max_delta, target);
        return;
    }

    from.* = min(from.* + max_delta, target);
}

approach :: (from: *$R, target: R, max_delta: float)
#modify {
    return (R == Vector2) || (R == Vector3) || (R == Vector4);
} {
    if (from.* == target) return;

    diff := target - from.*;
    if (length_squared(diff) <= max_delta * max_delta) {
        from.* = target;
        return;
    }

    from.* += normalize(diff) * max_delta;
}

round :: (x: float) -> float {
    return floor(x + 0.5 * ifx x < 0 then -1 else 1);
}

snap :: (x: float, increment: float) -> float {
    return round(x / increment) * increment;
}
