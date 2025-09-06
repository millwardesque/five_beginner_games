local default_gravity = -1.4
local force_obstacle_height_to_zero = true
local skip_gravity = true
local obstacle_width = 16
local jump_impulse = 10.0
local slowdown_factor = 0.6
local obstacle_pairs = {}
local was_pressed = false
local player_has_started = false

ingame_state = {
    init = function()
        reset_game()
    end,

    update = function()
        if (btn(2)) then
            if (was_pressed == false) then
                player.speed = jump_impulse
                was_pressed = true

                if (player_has_started == false) then
                    force_obstacle_height_to_zero = false
                    player.gravity = default_gravity
                    player_has_started = true
                end
            end
        else
            was_pressed = false
        end

        player.speed = player.speed * slowdown_factor
        player.y -= player.speed + player.gravity

        foreach(obstacle_pairs, update_obstacle_pair)

        if (player_has_started) then
            score += scroll_speed
        end

        for o in all(obstacles) do
            if check_player_obstacle_collision(player, o) then
                set_state('gameover')
                debug_collider = o
                break
            end
        end
    end,

    draw = function()
        cls(sky_colour)

        foreach(obstacles, draw_obstacle)
        draw_player(player)

        rectfill(0, 0, 127, 7, 0)
        print("Score: "..score, 1, 1, 7)
    end
}

function update_obstacle_pair(p)
    local top = p.top
    local bottom = p.bottom
    top.x -= scroll_speed
    bottom.x -= scroll_speed

    local is_offscreen = top.x + top.w <= 0

    -- If we've scrolled offscreen, wrap to the beginning and generate new heights
    if (is_offscreen) then
        top.x = 128
        bottom.x = 128
        calculate_obstacle_pair_height(p)
    end
end

function calculate_obstacle_pair_height(p)
    local top = p.top
    local bottom = p.bottom
    local hidden_threshold = max(0.7 - 0.0001 * score, 0)
    local is_hidden = rnd() < hidden_threshold or force_obstacle_height_to_zero;

    if (is_hidden) then
        top.h = 0
        bottom.y = 128
        bottom.h = 0
        return
    end

    local min_gap = min(16 + 100 / (score + 1), 32)
    local max_gap = min(max(96 * 100 / (score + 1), min_gap), 96)
    local step_size = 8
    local max_steps = (max_gap - min_gap) / step_size
    max_steps += 1 -- Account for rnd being exclusive and thus never returning 1
    local num_steps = flr(rnd() * max_steps)

    local gap_size = min_gap + num_steps * step_size
    local gap_y = 64 - flr(gap_size / 2)

    top.h = gap_y
    bottom.y = gap_y + gap_size
    bottom.h = 128 - bottom.y

end

function draw_obstacle(o)
    rectfill(o.x, o.y, o.x + o.w - 1, o.y + o.h - 1, o.c)
    rect(o.x, o.y, o.x + o.w - 1, o.y + o.h - 1, 0)
end

function draw_player(p)
    circfill(p.x, p.y, p.r, p.c)
end

function reset_game()
    was_pressed = false
    player_has_started = false
    force_obstacle_height_to_zero = true
    skip_gravity = true

    scroll_speed = 1
    sky_colour = 12

    player = {
        x = 64,
        y = 64,
        r = 3,
        r_collision = 2,
        c = 7,
        speed = 0,
        gravity = 0,
        acceleration = 0
    }

    score = 0

    -- Generate obstacles
    obstacles = {}
    obstacle_pairs = {}
    local columns = 128 / obstacle_width
    for i = 0, columns do
        local x = i * obstacle_width
        local color = 1 + i % 15
        local new_obstacle_top = {
            x = x,
            w = obstacle_width,
            y = 0,
            h = 0,
            c = color,
        }

        local new_obstacle_bottom = {
            x = x,
            y = 128,
            w = obstacle_width,
            h = 0,
            c = color,
        }
        local obstacle_pair = {top = new_obstacle_top, bottom = new_obstacle_bottom}
        add(obstacles, new_obstacle_top)
        add(obstacles, new_obstacle_bottom)
        add(obstacle_pairs, obstacle_pair)
    end
end

function check_player_obstacle_collision(p, o, debug)
    local test_x = p.x
    local test_y = p.y

    if p.x > o.x + o.w then
        test_x = o.x + o.w
    elseif p.x < o.x then
        test_x = o.x
    end

    if p.y > o.y + o.h then
        test_y = o.y + o.h
    elseif p.y < o.y then
        test_y = o.y
    end

    local dist_x = p.x - test_x
    local dist_y = p.y - test_y
    local distance = sqrt((dist_x * dist_x) + (dist_y * dist_y))

    if debug then
        print(test_x..", "..test_y..", "..dist_x..", "..dist_y..", "..distance..", "..p.r_collision)
    end

    return distance <= p.r_collision
end
