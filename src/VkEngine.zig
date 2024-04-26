const std = @import("std");
const vk = @import("vulkan");
const glfw = @import("mach-glfw");

const Self = @This();

window: glfw.Window,
extent: vk.Extent2D,


allocator: std.mem.Allocator,

pub fn init(window_height: u32, window_width: u32, allocator: std.mem.Allocator) !Self {
    var self: Self = undefined;

    self.allocator = allocator;

    glfw.setErrorCallback(struct {
        fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
            std.log.err("glfw: {}: {s}\n", .{ error_code, description });
        }
    }.errorCallback);

    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}\n", .{glfw.getErrorString()});
        return error.glfwInitializationFailed;
    }
    self.extent = vk.Extent2D{ .width = window_width, .height = window_height };

    self.window = glfw.Window.create(
        self.extent.width,
        self.extent.height,
        "PLACEHOLDER_TITLE",
        null,
        null,
        .{
            .client_api = .no_api,
        },
    ) orelse {
        std.log.err("failed to initialize GLFW: {?s}\n", .{glfw.getErrorString()});
        return error.glfwWindowCreateFail;
    };

    return self;
}
pub fn run(self: Self) !void {
    while (!self.window.shouldClose()) {
        // Don't present render while the window is minimized
        const size = self.window.getSize();
        if (size.width == 0 or size.height == 0) {
            glfw.pollEvents();
            continue;
        }
        glfw.pollEvents();
    }
}

pub fn deInit(self: Self) void {
    self.window.destroy();
    glfw.terminate();
}
