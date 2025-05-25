Config = {
    MaxDistance = 10.0, -- Audio range (meters)
    Cooldown = 180000, -- Cooldown (milliseconds, 60 seconds)
    AnimationDuration = 10000, -- Flute animation cycle (milliseconds, 10 seconds)
    SnakeDuration = 30000, -- Max time snakes are active (milliseconds, 30 seconds)
    MaxSnakes = 5, -- Number of snakes to spawn
    Tunes = {
        {
            name = "Mystic Call",
            desc = "Snakes circle around you",
            url = "https://www.youtube.com/watch?v=ifM4dYU5dJo", 
            behavior = "circle",
            radius = 2.0
        },
        {
            name = "Serpent March",
            desc = "Snakes follow in a line",
            url = "https://www.youtube.com/watch?v=ifM4dYU5dJo",
            behavior = "follow",
            spacing = 1.0
        },
        {
            name = "Wild Dance",
            desc = "Snakes sway randomly",
            url = "https://www.youtube.com/watch?v=ifM4dYU5dJo",
            behavior = "random",
            radius = 2.0
        }
    },
    VolumeSettings = {
        BaseVolume = 0.5,
        MinDistance = 0.0,
        MaxDistance = 50.0
    },
    PropSettings = {
        flute = {
            model = "s_blakesleetube01x", 
            boneName = "PH_L_Hand",
            position = { x = 0.1, y = 0.0, z = 0.1 },
            rotation = { pitch = 0.0, roll = 1.0, yaw = 0.0 }
        }
    },
    Animation = {
        dict = "mech_skin@cat@carried@human",
        name = "grip_lt_shoulder"
    }
}
