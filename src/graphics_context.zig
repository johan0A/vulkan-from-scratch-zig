const std = @import("std");
const builtin = @import("builtin");
const glfw = @import("mach-glfw");
const vk = @import("vulkan.zig");
const Allocator = std.mem.Allocator;

const required_device_extensions = [_][*:0]const u8{vk.extensions.khr_swapchain.name};
const optional_device_extensions = [_][*:0]const u8{};

const optional_instance_extensions = [_][*:0]const u8{vk.extensions.khr_get_physical_device_properties_2.name};

/// To construct base, instance and device wrappers for vulkan-zig, you need to pass a list of 'apis' to it.
const apis: []const vk.ApiInfo = &.{
    // You can either add invidiual functions by manually creating an 'api'
    .{
        .base_commands = .{
            .createInstance = true,
        },
        .instance_commands = .{
            .createDevice = true,
        },
    },
    // Or you can add entire feature sets or extensions
    vk.features.version_1_0,
    vk.extensions.khr_surface,
    vk.extensions.khr_swapchain,
};

/// Next, pass the `apis` to the wrappers to create dispatch tables.
const BaseDispatch = vk.BaseWrapper(apis);
const InstanceDispatch = vk.InstanceWrapper(apis);
const DeviceDispatch = vk.DeviceWrapper(apis);

pub const GraphicsContext = struct {
    const Self = @This();

    const validation_layers = [_][]const u8{"VK_LAYER_KHRONOS_validation"};
    const use_validation_layers = builtin.mode == std.builtin.OptimizeMode.Debug;

    base_dispatch: BaseDispatch,
    instance_dispatch: InstanceDispatch,
    device_dispatch: DeviceDispatch,

    instance: vk.Instance,
    surface: vk.SurfaceKHR,
    phys_device: vk.PhysicalDevice,
    phys_device_props: vk.PhysicalDeviceProperties,
    phys_device_mem_props: vk.PhysicalDeviceMemoryProperties,

    device: vk.Device,
    graphics_queue: Queue,
    present_queue: Queue,

    allocator: Allocator,

    pub fn init(allocator: Allocator, app_name: [*:0]const u8, window: glfw.Window) !GraphicsContext {
        var self: GraphicsContext = undefined;
        self.allocator = allocator;
        self.base_dispatch = try BaseDispatch.load(@as(vk.PfnGetInstanceProcAddr, @ptrCast(&glfw.getInstanceProcAddress)));

        const app_info = vk.ApplicationInfo{
            .p_application_name = app_name,
            .application_version = vk.makeApiVersion(0, 0, 0, 0),
            .p_engine_name = app_name,
            .engine_version = vk.makeApiVersion(0, 0, 0, 0),
            .api_version = vk.API_VERSION_1_2,
        };

        const glfw_exts = glfw.getRequiredInstanceExtensions() orelse return blk: {
            const err = glfw.mustGetError();
            std.log.err("failed to get required vulkan instance extensions: error={s}", .{err.description});
            break :blk error.code;
        };

        var instance_extensions = try std.ArrayList([*:0]const u8).initCapacity(allocator, glfw_exts.len + 1);
        defer instance_extensions.deinit();
        try instance_extensions.appendSlice(glfw_exts);

        var count: u32 = undefined;
        _ = try self.base_dispatch.enumerateInstanceExtensionProperties(null, &count, null);

        const propsv = try allocator.alloc(vk.ExtensionProperties, count);
        defer allocator.free(propsv);

        _ = try self.base_dispatch.enumerateInstanceExtensionProperties(null, &count, propsv.ptr);

        for (optional_instance_extensions) |extension_name| {
            for (propsv) |prop| {
                const len = std.mem.indexOfScalar(u8, &prop.extension_name, 0).?;
                const prop_ext_name = prop.extension_name[0..len];
                if (std.mem.eql(u8, prop_ext_name, std.mem.span(extension_name))) {
                    try instance_extensions.append(@ptrCast(extension_name));
                    break;
                }
            }
        }

        if (use_validation_layers and !try self.checkValidationLayerSupport()) {
            std.log.err("validation layers requested, but not available!", .{});
            return error.ValidationLayersNotAvailable;
        }

        self.instance = try self.base_dispatch.createInstance(&vk.InstanceCreateInfo{
            .flags = if (builtin.os.tag == .macos) .{
                .enumerate_portability_bit_khr = true,
            } else .{},
            .p_application_info = &app_info,
            .enabled_layer_count = if (use_validation_layers) validation_layers.len else 0,
            .pp_enabled_layer_names = if (use_validation_layers) @ptrCast(&validation_layers) else undefined,
            .enabled_extension_count = @intCast(instance_extensions.items.len),
            .pp_enabled_extension_names = @ptrCast(instance_extensions.items),
        }, null);

        self.instance_dispatch = try InstanceDispatch.load(self.instance, self.base_dispatch.dispatch.vkGetInstanceProcAddr);
        errdefer self.instance_dispatch.destroyInstance(self.instance, null);

        self.surface = try createSurface(self.instance, window);
        errdefer self.instance_dispatch.destroySurfaceKHR(self.instance, self.surface, null);

        const candidate = try pickPhysicalDevice(self.instance_dispatch, self.instance, allocator, self.surface);
        self.phys_device = candidate.pdev;
        self.phys_device_props = candidate.props;
        self.device = try initializeCandidate(allocator, self.instance_dispatch, candidate);
        self.device_dispatch = try DeviceDispatch.load(self.device, self.instance_dispatch.dispatch.vkGetDeviceProcAddr);
        errdefer self.device_dispatch.destroyDevice(self.device, null);

        self.graphics_queue = Queue.init(self.device_dispatch, self.device, candidate.queues.graphics_family);
        self.present_queue = Queue.init(self.device_dispatch, self.device, candidate.queues.present_family);

        self.phys_device_mem_props = self.instance_dispatch.getPhysicalDeviceMemoryProperties(self.phys_device);

        return self;
    }

    pub fn deinit(self: Self) void {
        self.device_dispatch.destroyDevice(self.device, null);
        self.instance_dispatch.destroySurfaceKHR(self.instance, self.surface, null);
        self.instance_dispatch.destroyInstance(self.instance, null);
    }

    pub fn deviceName(self: *const Self) []const u8 {
        return std.mem.sliceTo(&self.phys_device_props.device_name, 0);
    }

    pub fn findMemoryTypeIndex(self: Self, memory_type_bits: u32, flags: vk.MemoryPropertyFlags) !u32 {
        for (self.phys_device_mem_props.memory_types[0..self.phys_device_mem_props.memory_type_count], 0..) |mem_type, i| {
            if (memory_type_bits & (@as(u32, 1) << @truncate(i)) != 0 and mem_type.property_flags.contains(flags)) {
                return @truncate(i);
            }
        }

        return error.NoSuitableMemoryType;
    }

    pub fn allocate(self: Self, requirements: vk.MemoryRequirements, flags: vk.MemoryPropertyFlags) !vk.DeviceMemory {
        return try self.device_dispatch.allocateMemory(self.device, &.{
            .allocation_size = requirements.size,
            .memory_type_index = try self.findMemoryTypeIndex(requirements.memory_type_bits, flags),
        }, null);
    }

    fn checkValidationLayerSupport(self: Self) !bool {
        var layer_count: u32 = undefined;
        _ = try self.base_dispatch.enumerateInstanceLayerProperties(&layer_count, null);

        const available_layers = try self.allocator.alloc(vk.LayerProperties, layer_count);
        defer self.allocator.free(available_layers);

        _ = try self.base_dispatch.enumerateInstanceLayerProperties(&layer_count, @ptrCast(available_layers));

        for (validation_layers) |layer_name| {
            for (available_layers) |layer_properties| {
                if (std.mem.eql(u8, layer_properties.layer_name[0..layer_name.len], layer_name)) {
                    break;
                }
            } else {
                return false;
            }
        }
        return true;
    }
};

pub const Queue = struct {
    handle: vk.Queue,
    family: u32,

    fn init(vkd: DeviceDispatch, dev: vk.Device, family: u32) Queue {
        return .{
            .handle = vkd.getDeviceQueue(dev, family, 0),
            .family = family,
        };
    }
};

fn createSurface(instance: vk.Instance, window: glfw.Window) !vk.SurfaceKHR {
    var surface: vk.SurfaceKHR = undefined;
    if ((glfw.createWindowSurface(instance, window, null, &surface)) != @intFromEnum(vk.Result.success)) {
        return error.SurfaceInitFailed;
    }

    return surface;
}

fn initializeCandidate(allocator: Allocator, vki: InstanceDispatch, candidate: DeviceCandidate) !vk.Device {
    const priority = [_]f32{1};
    const qci = [_]vk.DeviceQueueCreateInfo{
        .{
            .queue_family_index = candidate.queues.graphics_family,
            .queue_count = 1,
            .p_queue_priorities = &priority,
        },
        .{
            .queue_family_index = candidate.queues.present_family,
            .queue_count = 1,
            .p_queue_priorities = &priority,
        },
    };

    const queue_count: u32 = if (candidate.queues.graphics_family == candidate.queues.present_family)
        1 // nvidia
    else
        2; // amd

    var device_extensions = try std.ArrayList([*:0]const u8).initCapacity(allocator, required_device_extensions.len);
    defer device_extensions.deinit();

    try device_extensions.appendSlice(required_device_extensions[0..required_device_extensions.len]);

    var count: u32 = undefined;
    _ = try vki.enumerateDeviceExtensionProperties(candidate.pdev, null, &count, null);

    const propsv = try allocator.alloc(vk.ExtensionProperties, count);
    defer allocator.free(propsv);

    _ = try vki.enumerateDeviceExtensionProperties(candidate.pdev, null, &count, propsv.ptr);

    for (optional_device_extensions) |extension_name| {
        for (propsv) |prop| {
            if (std.mem.eql(u8, prop.extension_name[0..prop.extension_name.len], std.mem.span(extension_name))) {
                try device_extensions.append(extension_name);
                break;
            }
        }
    }

    return try vki.createDevice(candidate.pdev, &.{
        .queue_create_info_count = queue_count,
        .p_queue_create_infos = &qci,
        .enabled_extension_count = required_device_extensions.len,
        .pp_enabled_extension_names = @as([*]const [*:0]const u8, @ptrCast(device_extensions.items)),
    }, null);
}

const DeviceCandidate = struct {
    pdev: vk.PhysicalDevice,
    props: vk.PhysicalDeviceProperties,
    queues: QueueAllocation,
};

const QueueAllocation = struct {
    graphics_family: u32,
    present_family: u32,
};

fn pickPhysicalDevice(
    vki: InstanceDispatch,
    instance: vk.Instance,
    allocator: Allocator,
    surface: vk.SurfaceKHR,
) !DeviceCandidate {
    var device_count: u32 = undefined;
    _ = try vki.enumeratePhysicalDevices(instance, &device_count, null);

    const pdevs = try allocator.alloc(vk.PhysicalDevice, device_count);
    defer allocator.free(pdevs);

    _ = try vki.enumeratePhysicalDevices(instance, &device_count, pdevs.ptr);

    for (pdevs) |pdev| {
        if (try checkSuitable(vki, pdev, allocator, surface)) |candidate| {
            return candidate;
        }
    }

    return error.NoSuitableDevice;
}

fn checkSuitable(
    vki: InstanceDispatch,
    pdev: vk.PhysicalDevice,
    allocator: Allocator,
    surface: vk.SurfaceKHR,
) !?DeviceCandidate {
    const props = vki.getPhysicalDeviceProperties(pdev);

    if (!try checkExtensionSupport(vki, pdev, allocator)) {
        return null;
    }

    if (!try checkSurfaceSupport(vki, pdev, surface)) {
        return null;
    }

    if (try allocateQueues(vki, pdev, allocator, surface)) |allocation| {
        return DeviceCandidate{
            .pdev = pdev,
            .props = props,
            .queues = allocation,
        };
    }

    return null;
}

fn allocateQueues(vki: InstanceDispatch, pdev: vk.PhysicalDevice, allocator: Allocator, surface: vk.SurfaceKHR) !?QueueAllocation {
    var family_count: u32 = undefined;
    vki.getPhysicalDeviceQueueFamilyProperties(pdev, &family_count, null);

    const families = try allocator.alloc(vk.QueueFamilyProperties, family_count);
    defer allocator.free(families);
    vki.getPhysicalDeviceQueueFamilyProperties(pdev, &family_count, families.ptr);

    var graphics_family: ?u32 = null;
    var present_family: ?u32 = null;

    for (families, 0..) |properties, i| {
        const family: u32 = @intCast(i);

        if (graphics_family == null and properties.queue_flags.graphics_bit) {
            graphics_family = family;
        }

        if (present_family == null and (try vki.getPhysicalDeviceSurfaceSupportKHR(pdev, family, surface)) == vk.TRUE) {
            present_family = family;
        }
    }

    if (graphics_family != null and present_family != null) {
        return QueueAllocation{
            .graphics_family = graphics_family.?,
            .present_family = present_family.?,
        };
    }

    return null;
}

fn checkSurfaceSupport(vki: InstanceDispatch, pdev: vk.PhysicalDevice, surface: vk.SurfaceKHR) !bool {
    var format_count: u32 = undefined;
    _ = try vki.getPhysicalDeviceSurfaceFormatsKHR(pdev, surface, &format_count, null);

    var present_mode_count: u32 = undefined;
    _ = try vki.getPhysicalDeviceSurfacePresentModesKHR(pdev, surface, &present_mode_count, null);

    return format_count > 0 and present_mode_count > 0;
}

fn checkExtensionSupport(
    vki: InstanceDispatch,
    pdev: vk.PhysicalDevice,
    allocator: Allocator,
) !bool {
    var count: u32 = undefined;
    _ = try vki.enumerateDeviceExtensionProperties(pdev, null, &count, null);

    const extension_props = try allocator.alloc(vk.ExtensionProperties, count);
    defer allocator.free(extension_props);

    _ = try vki.enumerateDeviceExtensionProperties(pdev, null, &count, extension_props.ptr);

    for (required_device_extensions) |ext| {
        for (extension_props) |extension_prop| {
            if (std.mem.eql(u8, std.mem.span(ext), std.mem.sliceTo(&extension_prop.extension_name, 0))) {
                break;
            }
        } else {
            return false;
        }
    }

    return true;
}
