// //> main
// #include <vk_engine.h>

// int main(int argc, char* argv[])
// {
// 	VulkanEngine engine;

// 	engine.init();

// 	engine.run();

// 	engine.cleanup();

// 	return 0;
// }
// //< main

const std = @import("std");
const vk_engine = @import("VkEngine.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) std.debug.print("Allocator leaked!\n", .{});
    const allocator = gpa.allocator();

    const engine = try vk_engine.init(800, 800, allocator);
    try engine.run();
    engine.deInit();
}
