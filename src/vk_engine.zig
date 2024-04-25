// #include "vk_engine.h"

// #include <SDL.h>
// #include <SDL_vulkan.h>

// #include <vk_types.h>
// #include <vk_initializers.h>

// void VulkanEngine::init() {
// 	// We initialize SDL and create a window with it.
// 	SDL_Init(SDL_INIT_VIDEO);
// 	SDL_WindowFlags window_flags = (SDL_WindowFlags)(SDL_WINDOW_VULKAN);
// 	_window = SDL_CreateWindow(
// 		"Vulkan Engine",
// 		SDL_WINDOWPOS_UNDEFINED,
// 		SDL_WINDOWPOS_UNDEFINED,
// 		_windowExtent.width,
// 		_windowExtent.height,
// 		window_flags
// 	);
// 	//everything went fine
// 	_isInitialized = true;
// }
// void VulkanEngine::cleanup() {
// 	if (_isInitialized) {
// 		SDL_DestroyWindow(_window);
// 	}
// }

// void VulkanEngine::draw() {}

// void VulkanEngine::run() {
// 	SDL_Event e;
// 	bool bQuit = false;
// 	//main loop
// 	while (!bQuit) {
// 		//Handle events on queue
// 		while (SDL_PollEvent(&e) != 0) {
// 			//close the window when user alt-f4s or clicks the X button
// 			if (e.type == SDL_QUIT) bQuit = true;
// 		}
// 		draw();
// 	}
// }

const std = @import("std");
const vk = @import("vulkan");
const glfw = @import("mach-glfw");

const Self = @This();

window: glfw.Window,
extent: vk.Extent2D,

pub fn init(window_height: u32, window_width: u32) !Self {
    glfw.setErrorCallback(struct {
        fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
            std.log.err("glfw: {}: {s}\n", .{ error_code, description });
        }
    }.errorCallback);

    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}\n", .{glfw.getErrorString()});
        return error.glfwInitializationFailed;
    }
    const extent = vk.Extent2D{ .width = window_width, .height = window_height };

    const window = glfw.Window.create(
        extent.width,
        extent.height,
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

    return .{
        .window = window,
        .extent = extent,
    };
}

pub fn draw() !void {}

pub fn run(self: Self) !void {
    while (!self.window.shouldClose()) {
        glfw.pollEvents();
    }
}

pub fn deInit(self: Self) void {
    glfw.terminate();
    self.window.destroy();
}
