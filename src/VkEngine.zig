const std = @import("std");
const vk = @import("vulkan");
const glfw = @import("mach-glfw");

const device_builder = @import("device_builder.zig");
const instance_builder = @import("instance_builder.zig");
const swapchain_builder = @import("swapchain_builder.zig");

const Self = @This();

const app_name = "PLACEHOLDER_TITLE";

window: glfw.Window,
extent: vk.Extent2D,

instance: vk.Instance,
debug_messenger: vk.DebugUtilsMessengerEXT,
chosenGPU: vk.PhysicalDevice,
device: vk.Device,
surface: vk.SurfaceKHR,

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
        app_name,
        null,
        null,
        .{
            .client_api = .no_api,
        },
    ) orelse {
        std.log.err("failed to initialize GLFW: {?s}\n", .{glfw.getErrorString()});
        return error.glfwWindowCreateFail;
    };

    try self.initVulkan();

    try self.initSwapChain();

    try self.initCommands();

    try self.initSyncStructures();

    return self;
}

pub fn initVulkan(self: *Self) !void {
    self.instance = try instance_builder.get_instance(self.allocator, app_name);
}

pub fn initSwapChain(self: Self) !void {
    _ = self;
}

pub fn initCommands(self: Self) !void {
    _ = self;
}

pub fn initSyncStructures(self: Self) !void {
    _ = self;
}

pub fn draw(self: Self) !void {
    _ = self;
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
