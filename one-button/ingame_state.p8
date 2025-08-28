local obstacle_width = 8
local slowdown_factor = 0.9
local obstacle_pairs = {}
local was_pressed = false

ingame_state = {
    init = function()
        reset_game()
    end,

    update = function()
        if (btn(2)) then
            if (was_pressed == false) then
                player.speed = 2.5
                was_pressed = true
            end
        else
            was_pressed = false
        end

        player.speed = player.speed * slowdown_factor
        player.y -= player.speed + player.gravity

        foreach(obstacle_pairs, update_obstacle_pair)

        score += scroll_speed

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

    top.h = calc_obstacle_height()
    bottom.h = calc_obstacle_height()
    bottom.y = 128 - bottom.h
end

function draw_obstacle(o)
    rectfill(o.x, o.y, o.x + o.w - 1, o.y + o.h - 1, o.c)
    rect(o.x, o.y, o.x + o.w - 1, o.y + o.h - 1, 0)
end

function draw_player(p)
    circfill(p.x, p.y, p.r, p.c)
end

function reset_game()
    scroll_speed = 1
    sky_colour = 12

    player = {
        x = 64,
        y = 64,
        r = 3,
        r_collision = 2,
        c = 7,
        speed = 1,
        gravity = -1.2,
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
        calculate_obstacle_pair_height(obstacle_pair)

        add(obstacles, new_obstacle_top)
        add(obstacles, new_obstacle_bottom)
        add(obstacle_pairs, obstacle_pair)
    end
end

function calc_obstacle_height()
    return 16 + flr(rnd(6)) * 8
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
