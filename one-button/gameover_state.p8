gameover_state = {
    init = function()
        update_high_scores(high_scores, score)
    end,

    update = function()
        if btnp(4) or btnp(5) then
            set_state("ingame")
        end
    end,

    draw = function()
        cls(sky_colour)

        print("game over!", 44, 48, 8)
        print("score: "..score, 44, 56, 8)

        high_score_y = 72
        print("high scores", 44, high_score_y, 7)
        for i, s in pairs(high_scores) do
            print(i..": "..s, 44, high_score_y + i * 7, 7)
        end

        if (debug) then
            print("p: "..player.x..", "..player.y..", "..player.r, 0, 0)
            print("o: "..debug_collider.x..", "..debug_collider.y..", "..debug_collider.w..", "..debug_collider.h, 0, 10, 0)
            check_player_obstacle_collision(player, debug_collider, true)
        end
    end
}

function update_high_scores(high_scores, new_score)
    local new_position = 1
    for i,s in ipairs(high_scores) do
        if new_score >= s then
            break
        else
            new_position += 1
        end
    end

    if new_position <= max_scores then
        add(high_scores, new_score, new_position)
    end
end
