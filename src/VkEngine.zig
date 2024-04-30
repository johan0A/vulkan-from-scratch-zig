const std = @import("std");
const glfw = @import("mach-glfw");

const Swapchain = @import("swapchain.zig").Swapchain;
const GraphicsContext = @import("graphics_context.zig").GraphicsContext;
const vk = @import("vulkan.zig");
const vk_initializers = @import("vk_initializers.zig");

const Self = @This();

const FrameData = struct {
    command_pool: vk.CommandPool,
    main_command_buffer: vk.CommandBuffer,
    swapchain_semaphore: vk.Semaphore,
    render_semaphore: vk.Semaphore,
    render_fence: vk.Fence,
};

const frame_overlap = 2;
const app_name = "PLACEHOLDER_TITLE";

allocator: std.mem.Allocator,

window: glfw.Window,

extent: vk.Extent2D,
debug_messenger: vk.DebugUtilsMessengerEXT,

gc: GraphicsContext,
swapchain: Swapchain,

frames: [frame_overlap]FrameData,
frame_number: u32,

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

    // self.swapchain = try Swapchain.init(&self.gc, allocator, self.extent);

    try self.initCommands();

    // try self.initSyncStructures();

    return self;
}

pub fn initCommands(self: *Self) !void {
    const commandPoolInfo = vk.CommandPoolCreateInfo{
        .flags = .{ .reset_command_buffer_bit = true },
        .queue_family_index = self.gc.graphics_queue.family,
    };
    for (&self.frames) |*frame| {
        frame.command_pool = try self.gc.device_dispatch.createCommandPool(
            self.gc.device,
            &commandPoolInfo,
            null,
        );
        errdefer self.gc.device_dispatch.destroyCommandPool(self.gc.device, frame.command_pool, null);

        const cmd_alloc_info = vk_initializers.commandBufferAllocateInfo(frame.command_pool, 1);

        try self.gc.device_dispatch.allocateCommandBuffers(
            self.gc.device,
            &cmd_alloc_info,
            @ptrCast(&frame.main_command_buffer),
        );
    }
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

pub fn getCurrentFrame(self: Self) *FrameData {
    return &self.frames[self.frame_number % frame_overlap];
}

pub fn deInit(self: Self) !void {
    try self.gc.device_dispatch.deviceWaitIdle(self.gc.device);
    for (self.frames) |frame| {
        self.gc.device_dispatch.destroyCommandPool(self.gc.device, frame.command_pool, null);
    }
    // self.swapchain.deinit();
    self.gc.deinit();
    self.window.destroy();
    glfw.terminate();
}
