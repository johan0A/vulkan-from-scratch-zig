const std = @import("std");
const builtin = @import("builtin");
const glfw = @import("mach-glfw");
const vk = @import("vulkan");
const Allocator = std.mem.Allocator;

const optional_instance_extensions = [_][*:0]const u8{
    vk.extension_info.khr_get_physical_device_properties_2.name,
};

const BaseDispatch = vk.BaseWrapper(.{
    .createInstance = true,
    .enumerateInstanceExtensionProperties = true,
    .getInstanceProcAddr = true,
});

pub fn get_instance(allocator: Allocator, app_name: [*:0]const u8) !vk.Instance {
    const vkb = try BaseDispatch.load(@as(vk.PfnGetInstanceProcAddr, @ptrCast(&glfw.getInstanceProcAddress)));

    const glfw_exts = glfw.getRequiredInstanceExtensions() orelse {
        const err = glfw.mustGetError();
        std.log.err("failed to get required vulkan instance extensions: error={s}", .{err.description});
        return error.code;
    };

    var instance_extensions = try std.ArrayList([*:0]const u8).initCapacity(allocator, glfw_exts.len + 1);
    defer instance_extensions.deinit();
    try instance_extensions.appendSlice(glfw_exts);

    var count: u32 = undefined;
    _ = try vkb.enumerateInstanceExtensionProperties(null, &count, null);

    const propsv = try allocator.alloc(vk.ExtensionProperties, count);
    defer allocator.free(propsv);

    _ = try vkb.enumerateInstanceExtensionProperties(null, &count, propsv.ptr);

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

    const app_info = vk.ApplicationInfo{
        .p_application_name = app_name,
        .application_version = vk.makeApiVersion(0, 0, 0, 0),
        .p_engine_name = app_name,
        .engine_version = vk.makeApiVersion(0, 0, 0, 0),
        .api_version = vk.makeApiVersion(0, 1, 1, 0),
    };

    return try vkb.createInstance(&vk.InstanceCreateInfo{
        .flags = if (builtin.os.tag == .macos) .{
            .enumerate_portability_bit_khr = true,
        } else .{},
        .p_application_info = &app_info,
        .enabled_layer_count = 0,
        .pp_enabled_layer_names = undefined,
        .enabled_extension_count = @intCast(instance_extensions.items.len),
        .pp_enabled_extension_names = @ptrCast(instance_extensions.items),
    }, null);
}
