const std = @import("std");
const log = @import("log.zig");
const math = @import("math.zig");
const Vec3 = math.Vec3;
const Vec2 = math.Vec2;
const Mat4 = math.Mat4;

pub fn logVec3(name: []const u8, vec: Vec3) void {
    log.info("{s}: ({d:.3}, {d:.3}, {d:.3})", .{ name, vec.x, vec.y, vec.z });
}
