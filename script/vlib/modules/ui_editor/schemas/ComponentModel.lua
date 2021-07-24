---- TODOTODOTODO
-- This should be all the model stuff, for Portholes and other animated UI using in-game skeletons, models, and VMD's

return {
    {
        version = 119,
        fields = {
            {
                name = "filepath",
                type = "utf8",
            },
            {
                name = "id",
                type = "utf8",
            },
            {
                name = "is_visible",
                type = "Boolean",
            },
            {
                name = "animation_path",
                type = {"Collection", {type = "utf8", override_fields = {[1] = {key = "skeleton_type", type = "utf8"}}}}
            }
        }
    }
}