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
const vk_engine = @import("vk_engine.zig");

pub fn main() !void {
    const engine = try vk_engine.init(800, 800);
    try engine.run();
    engine.deInit();
}
