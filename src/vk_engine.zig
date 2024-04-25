// ﻿//> includes
// #include "vk_engine.h"

// #include <SDL.h>
// #include <SDL_vulkan.h>

// #include <vk_initializers.h>
// #include <vk_types.h>

// #include <chrono>
// #include <thread>
// //< includes

// //> init
// constexpr bool bUseValidationLayers = false;

// VulkanEngine* loadedEngine = nullptr;

// VulkanEngine& VulkanEngine::Get() { return *loadedEngine; }
// void VulkanEngine::init()
// {
//     // only one engine initialization is allowed with the application.
//     assert(loadedEngine == nullptr);
//     loadedEngine = this;

//     // We initialize SDL and create a window with it.
//     SDL_Init(SDL_INIT_VIDEO);

//     SDL_WindowFlags window_flags = (SDL_WindowFlags)(SDL_WINDOW_VULKAN);

//     _window = SDL_CreateWindow(
//         "Vulkan Engine",
//         SDL_WINDOWPOS_UNDEFINED,
//         SDL_WINDOWPOS_UNDEFINED,
//         _windowExtent.width,
//         _windowExtent.height,
//         window_flags);

//     // everything went fine
//     _isInitialized = true;
// }
// //< init

// //> extras
// void VulkanEngine::cleanup()
// {
//     if (_isInitialized) {

//         SDL_DestroyWindow(_window);
//     }

//     // clear engine pointer
//     loadedEngine = nullptr;
// }

// void VulkanEngine::draw()
// {
//     // nothing yet
// }
// //< extras

// //> drawloop
// void VulkanEngine::run()
// {
//     SDL_Event e;
//     bool bQuit = false;

//     // main loop
//     while (!bQuit) {
//         // Handle events on queue
//         while (SDL_PollEvent(&e) != 0) {
//             // close the window when user alt-f4s or clicks the X button
//             if (e.type == SDL_QUIT)
//                 bQuit = true;

//             if (e.type == SDL_WINDOWEVENT) {
//                 if (e.window.event == SDL_WINDOWEVENT_MINIMIZED) {
//                     stop_rendering = true;
//                 }
//                 if (e.window.event == SDL_WINDOWEVENT_RESTORED) {
//                     stop_rendering = false;
//                 }
//             }
//         }

//         // do not draw if we are minimized
//         if (stop_rendering) {
//             // throttle the speed to avoid the endless spinning
//             std::this_thread::sleep_for(std::chrono::milliseconds(100));
//             continue;
//         }

//         draw();
//     }
// }
// //< drawloop

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
