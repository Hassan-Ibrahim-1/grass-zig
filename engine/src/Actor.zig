const std = @import("std");
const Allocator = std.mem.Allocator;
const engine = @import("engine.zig");
const Mesh = engine.Mesh;
const RenderItem = engine.RenderItem;
const Transform = engine.Transform;

const Actor = @This();

transform: Transform = Transform{},
render_item: RenderItem,
/// don't mutate this yourself
id: usize = 0,

pub fn init(allocator: Allocator) Actor {
    return Actor{
        .render_item = RenderItem.init(allocator),
    };
}

pub fn deinit(self: *Actor) void {
    self.render_item.deinit();
}
