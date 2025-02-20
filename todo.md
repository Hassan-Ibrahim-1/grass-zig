-- window functions
-- logging functions
-- separate build.zig - so that engine can refer to its root
-- shader struct

axis of rotation in matrices. can only rotate around x y or z rn

-- something is extremely messed up with movement.
-- sensitivity is too high for x and too low for y
-- some weird distortion when moving


-- resource finder -
--    instead of doing "../app/engine" just create a function that does that

Asset manager - goes through selected directories and loads
textures and models. deinit the asset manager to release everything
strips extensions
store in a hashmap(string, data) (or multiple hashmaps)

-- Handling new lines in text.zig

figure out how to make renderText always render after everything else
could use an arraylist of TextInfo. render that at the end of a frame


write the custom renderer. follow what the raylib renderer does
easy way to create windows
write convenience functions like dragfloat3 etc
resizing windows and moving them around
registering clicks for buttons
getting input for text
color picker

# UI
-- Finish input.zig before touching this
-- Finish camera stuff
-- rendering text

-- transforms
-- input handling
-- camera

-- Vertex
-- meshes


framebuffers
ui
color for each vertex?
shadows
collision
geometry shaders
pbr

# By the end of the weekend:
    * finish up basic renderer and opengl abstractions
    * add instancing support
    * remake the grass instancing test but with a better algorithm
    * Add better lighting support to the grass.
    * Normal maps should help
    * ignore model loading just for now
    * Maybe mix grass with basic terrain gen and water? (would require framebuffer support)

# FINISH THESE UP
-- textures
-- material
-- Actor
-- assimp (not strictly important)
loading textures from gltfs
-- lighting
-- Scene
-- renderer backend to abstract opengl
-- skyboxes
-- imgui

hot reloading (not strictly important)
VertexBuffer Attributes

imgui utils


make smaller structs that each sub system would use
    - the render takes in a render item (material, transform, mesh)
    - editor takes in a name and then you can add different components 
        in like material, transform, RenderItem etc,

