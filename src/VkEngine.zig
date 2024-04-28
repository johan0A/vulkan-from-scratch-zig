const std = @import("std");
const vk = @import("vulkan");
const glfw = @import("mach-glfw");

const Swapchain = @import("swapchain.zig").Swapchain;
const GraphicsContext = @import("graphics_context.zig").GraphicsContext;

const Self = @This();

const app_name = "PLACEHOLDER_TITLE";

allocator: std.mem.Allocator,

window: glfw.Window,
extent: vk.Extent2D,

instance: vk.Instance,
debug_messenger: vk.DebugUtilsMessengerEXT,

gc: GraphicsContext,
swapchain: Swapchain,


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

    self.gc = try GraphicsContext.init(allocator, app_name, self.window);

    self.swapchain = try Swapchain.init(&self.gc, allocator, self.extent);

    // try self.initCommands();

    // try self.initSyncStructures();

    return self;
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
    self.swapchain.deinit();
    self.gc.deinit();
    self.window.destroy();
    glfw.terminate();
}
