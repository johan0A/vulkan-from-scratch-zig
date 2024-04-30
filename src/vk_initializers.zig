const std = @import("std");
const vk = @import("vulkan.zig");

const GraphicsContext = @import("graphics_context.zig").GraphicsContext;

// VkCommandPoolCreateInfo vkinit::command_pool_create_info(uint32_t queueFamilyIndex,
//     VkCommandPoolCreateFlags flags /*= 0*/)
// {
//     VkCommandPoolCreateInfo info = {};
//     info.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
//     info.pNext = nullptr;
//     info.queueFamilyIndex = queueFamilyIndex;
//     info.flags = flags;
//     return info;
// }

const Self = @This();

gc: GraphicsContext,

fn commandPoolCreateInfo(queueFamilyIndex: u32, flags: vk.CommandPoolCreateFlags) !vk.CommandPoolCreateInfo {
    return vk.CommandPoolCreateInfo{
        .flags = flags,
        .queue_family_index = queueFamilyIndex,
    };
}

// VkCommandBufferAllocateInfo vkinit::command_buffer_allocate_info(
//     VkCommandPool pool, uint32_t count /*= 1*/)
// {
//     VkCommandBufferAllocateInfo info = {};
//     info.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
//     info.pNext = nullptr;

//     info.commandPool = pool;
//     info.commandBufferCount = count;
//     info.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
//     return info;
// }

fn commandBufferAllocateInfo(pool: vk.CommandPool, count: u32) !vk.CommandBufferAllocateInfo {
    return vk.CommandBufferAllocateInfo{
        .command_pool = pool,
        .command_buffer_count = count,
        .level = .primary,
    };
}

// VkCommandBufferBeginInfo vkinit::command_buffer_begin_info(VkCommandBufferUsageFlags flags /*= 0*/)
// {
//     VkCommandBufferBeginInfo info = {};
//     info.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
//     info.pNext = nullptr;

//     info.pInheritanceInfo = nullptr;
//     info.flags = flags;
//     return info;
// }

fn commandBufferBeginInfo(flags: vk.CommandBufferUsageFlags) !vk.CommandBufferBeginInfo {
    return vk.CommandBufferBeginInfo{
        .flags = flags,
    };
}

// VkFenceCreateInfo vkinit::fence_create_info(VkFenceCreateFlags flags /*= 0*/)
// {
//     VkFenceCreateInfo info = {};
//     info.sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
//     info.pNext = nullptr;

//     info.flags = flags;

//     return info;
// }

fn fenceCreateInfo(flags: vk.FenceCreateFlags) !vk.FenceCreateInfo {
    return vk.FenceCreateInfo{
        .flags = flags,
    };
}

// VkSemaphoreCreateInfo vkinit::semaphore_create_info(VkSemaphoreCreateFlags flags /*= 0*/)
// {
//     VkSemaphoreCreateInfo info = {};
//     info.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
//     info.pNext = nullptr;
//     info.flags = flags;
//     return info;
// }

fn semaphoreCreateInfo(flags: vk.SemaphoreCreateFlags) !vk.SemaphoreCreateInfo {
    return vk.SemaphoreCreateInfo{
        .flags = flags,
    };
}

// VkSemaphoreSubmitInfo vkinit::semaphore_submit_info(VkPipelineStageFlags2 stageMask, VkSemaphore semaphore)
// {
// 	VkSemaphoreSubmitInfo submitInfo{};
// 	submitInfo.sType = VK_STRUCTURE_TYPE_SEMAPHORE_SUBMIT_INFO;
// 	submitInfo.pNext = nullptr;
// 	submitInfo.semaphore = semaphore;
// 	submitInfo.stageMask = stageMask;
// 	submitInfo.deviceIndex = 0;
// 	submitInfo.value = 1;

// 	return submitInfo;
// }

fn semaphoreSubmitInfo(stageMask: vk.PipelineStageFlags2, semaphore: vk.Semaphore) !vk.SemaphoreSubmitInfo {
    return vk.SemaphoreSubmitInfo{
        .semaphore = semaphore,
        .stage_mask = stageMask,
        .device_index = 0,
        .value = 1,
    };
}

// VkCommandBufferSubmitInfo vkinit::command_buffer_submit_info(VkCommandBuffer cmd)
// {
// 	VkCommandBufferSubmitInfo info{};
// 	info.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_SUBMIT_INFO;
// 	info.pNext = nullptr;
// 	info.commandBuffer = cmd;
// 	info.deviceMask = 0;

// 	return info;
// }

fn commandBufferSubmitInfo(command_buffer: vk.CommandBuffer) !vk.SubmitInfo {
    return vk.SubmitInfo{
        .p_command_buffers = &command_buffer,
    };
}

// VkSubmitInfo2 vkinit::submit_info(VkCommandBufferSubmitInfo* cmd, VkSemaphoreSubmitInfo* signalSemaphoreInfo,
//     VkSemaphoreSubmitInfo* waitSemaphoreInfo)
// {
//     VkSubmitInfo2 info = {};
//     info.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO_2;
//     info.pNext = nullptr;

//     info.waitSemaphoreInfoCount = waitSemaphoreInfo == nullptr ? 0 : 1;
//     info.pWaitSemaphoreInfos = waitSemaphoreInfo;

//     info.signalSemaphoreInfoCount = signalSemaphoreInfo == nullptr ? 0 : 1;
//     info.pSignalSemaphoreInfos = signalSemaphoreInfo;

//     info.commandBufferInfoCount = 1;
//     info.pCommandBufferInfos = cmd;

//     return info;
// }

fn submitInfo(
    command_buffer: vk.SubmitInfoCommandBuffer,
    signal_semaphore_info: ?vk.SemaphoreSubmitInfo,
    wait_semaphore_info: ?vk.SemaphoreSubmitInfo,
) !vk.SubmitInfo {
    return vk.SubmitInfo2{
        .p_command_buffers = &command_buffer,
        .wait_semaphore_info_count = wait_semaphore_info orelse 0,
        .p_wait_semaphore_infos = wait_semaphore_info orelse null,
        .signal_semaphore_info_count = signal_semaphore_info orelse 0,
        .p_signal_semaphore_infos = signal_semaphore_info orelse null,
    };
}

// VkPresentInfoKHR vkinit::present_info()
// {
//     VkPresentInfoKHR info = {};
//     info.sType =  VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
//     info.pNext = 0;

//     info.swapchainCount = 0;
//     info.pSwapchains = nullptr;
//     info.pWaitSemaphores = nullptr;
//     info.waitSemaphoreCount = 0;
//     info.pImageIndices = nullptr;

//     return info;
// }

fn presentInfo() !vk.PresentInfoKHR {
    return vk.PresentInfoKHR{
        .swapchain_count = 0,
        .p_swapchains = null,
        .p_wait_semaphores = null,
        .wait_semaphore_count = 0,
        .p_image_indices = null,
    };
}

// VkRenderingAttachmentInfo vkinit::attachment_info(
//     VkImageView view, VkClearValue* clear ,VkImageLayout layout /*= VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL*/)
// {
//     VkRenderingAttachmentInfo colorAttachment {};
//     colorAttachment.sType = VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO;
//     colorAttachment.pNext = nullptr;

//     colorAttachment.imageView = view;
//     colorAttachment.imageLayout = layout;
//     colorAttachment.loadOp = clear ? VK_ATTACHMENT_LOAD_OP_CLEAR : VK_ATTACHMENT_LOAD_OP_LOAD;
//     colorAttachment.storeOp = VK_ATTACHMENT_STORE_OP_STORE;
//     if (clear) {
//         colorAttachment.clearValue = *clear;
//     }

//     return colorAttachment;
// }

fn attachmentInfo(
    view: vk.ImageView,
    clear: vk.ClearValue,
    layout: ?vk.ImageLayout,
) !vk.RenderingAttachmentInfo {
    return vk.RenderingAttachmentInfo{
        .image_view = view,
        .image_layout = layout orelse .color_attachment_optimal,
        .load_op = if (clear) vk.AttachmentLoadOp.clear else vk.AttachmentLoadOp.load,
        .store_op = .store,
        .clear_value = clear,
    };
}

// VkRenderingAttachmentInfo vkinit::depth_attachment_info(
//     VkImageView view, VkImageLayout layout /*= VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL*/)
// {
//     VkRenderingAttachmentInfo depthAttachment {};
//     depthAttachment.sType = VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO;
//     depthAttachment.pNext = nullptr;

//     depthAttachment.imageView = view;
//     depthAttachment.imageLayout = layout;
//     depthAttachment.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;
//     depthAttachment.storeOp = VK_ATTACHMENT_STORE_OP_STORE;
//     depthAttachment.clearValue.depthStencil.depth = 0.f;

//     return depthAttachment;
// }

fn depthAttachmentInfo(view: vk.ImageView, layout: ?vk.ImageLayout) !vk.RenderingAttachmentInfo {
    return vk.RenderingAttachmentInfo{
        .image_view = view,
        .image_layout = layout orelse .color_attachment_optimal,
        .load_op = .clear,
        .store_op = .store,
        .clear_value = vk.ClearValue{
            .depth_stencil = vk.ClearDepthStencilValue{
                .depth = 0.0,
                .stencil = 0,
            },
        },
    };
}

// VkRenderingInfo vkinit::rendering_info(VkExtent2D renderExtent, VkRenderingAttachmentInfo* colorAttachment,
//     VkRenderingAttachmentInfo* depthAttachment)
// {
//     VkRenderingInfo renderInfo {};
//     renderInfo.sType = VK_STRUCTURE_TYPE_RENDERING_INFO;
//     renderInfo.pNext = nullptr;

//     renderInfo.renderArea = VkRect2D { VkOffset2D { 0, 0 }, renderExtent };
//     renderInfo.layerCount = 1;
//     renderInfo.colorAttachmentCount = 1;
//     renderInfo.pColorAttachments = colorAttachment;
//     renderInfo.pDepthAttachment = depthAttachment;
//     renderInfo.pStencilAttachment = nullptr;

//     return renderInfo;
// }

fn renderingInfo(
    render_extent: vk.Extent2D,
    color_attachment: vk.RenderingAttachmentInfo,
    depth_attachment: vk.RenderingAttachmentInfo,
) !vk.RenderingInfo {
    return vk.RenderingInfo{
        .render_area = vk.Rect2D{
            .offset = vk.Offset2D{ .x = 0, .y = 0 },
            .extent = render_extent,
        },
        .layer_count = 1,
        .color_attachment_count = 1,
        .p_color_attachments = &color_attachment,
        .p_depth_attachment = &depth_attachment,
    };
}

// VkImageSubresourceRange vkinit::image_subresource_range(VkImageAspectFlags aspectMask)
// {
//     VkImageSubresourceRange subImage {};
//     subImage.aspectMask = aspectMask;
//     subImage.baseMipLevel = 0;
//     subImage.levelCount = VK_REMAINING_MIP_LEVELS;
//     subImage.baseArrayLayer = 0;
//     subImage.layerCount = VK_REMAINING_ARRAY_LAYERS;

//     return subImage;
// }

fn imageSubresourceRange(aspect_mask: vk.ImageAspectFlags) !vk.ImageSubresourceRange {
    return vk.ImageSubresourceRange{
        .aspect_mask = aspect_mask,
        .base_mip_level = 0,
        .level_count = vk.REMAINING_ARRAY_LAYERS,
        .base_array_layer = 0,
        .layer_count = vk.REMAINING_MIP_LEVELS,
    };
}

// VkDescriptorSetLayoutBinding vkinit::descriptorset_layout_binding(VkDescriptorType type, VkShaderStageFlags stageFlags,
//     uint32_t binding)
// {
//     VkDescriptorSetLayoutBinding setbind = {};
//     setbind.binding = binding;
//     setbind.descriptorCount = 1;
//     setbind.descriptorType = type;
//     setbind.pImmutableSamplers = nullptr;
//     setbind.stageFlags = stageFlags;

//     return setbind;
// }

fn descriptorSetLayoutBinding(
    descriptor_type: vk.DescriptorType,
    stage_flags: vk.ShaderStageFlags,
    binding: u32,
) !vk.DescriptorSetLayoutBinding {
    return vk.DescriptorSetLayoutBinding{
        .binding = binding,
        .descriptor_count = 1,
        .descriptor_type = descriptor_type,
        .stage_flags = stage_flags,
    };
}

// VkDescriptorSetLayoutCreateInfo vkinit::descriptorset_layout_create_info(VkDescriptorSetLayoutBinding* bindings,
//     uint32_t bindingCount)
// {
//     VkDescriptorSetLayoutCreateInfo info = {};
//     info.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
//     info.pNext = nullptr;

//     info.pBindings = bindings;
//     info.bindingCount = bindingCount;
//     info.flags = 0;

//     return info;
// }

fn descriptorSetLayoutCreateInfo(
    bindings: []vk.DescriptorSetLayoutBinding,
) !vk.DescriptorSetLayoutCreateInfo {
    return vk.DescriptorSetLayoutCreateInfo{
        .p_bindings = bindings.ptr,
        .binding_count = bindings.len,
    };
}

// VkWriteDescriptorSet vkinit::write_descriptor_image(VkDescriptorType type, VkDescriptorSet dstSet,
//     VkDescriptorImageInfo* imageInfo, uint32_t binding)
// {
//     VkWriteDescriptorSet write = {};
//     write.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
//     write.pNext = nullptr;

//     write.dstBinding = binding;
//     write.dstSet = dstSet;
//     write.descriptorCount = 1;
//     write.descriptorType = type;
//     write.pImageInfo = imageInfo;

//     return write;
// }

fn writeDescriptorImage(
    descriptor_type: vk.DescriptorType,
    dst_set: vk.DescriptorSet,
    image_info: vk.DescriptorImageInfo,
    binding: u32,
) !vk.WriteDescriptorSet {
    return vk.WriteDescriptorSet{
        .dst_binding = binding,
        .dst_set = dst_set,
        .descriptor_count = 1,
        .descriptor_type = descriptor_type,
        .p_image_info = &image_info,
    };
}

// VkWriteDescriptorSet vkinit::write_descriptor_buffer(VkDescriptorType type, VkDescriptorSet dstSet,
//     VkDescriptorBufferInfo* bufferInfo, uint32_t binding)
// {
//     VkWriteDescriptorSet write = {};
//     write.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
//     write.pNext = nullptr;

//     write.dstBinding = binding;
//     write.dstSet = dstSet;
//     write.descriptorCount = 1;
//     write.descriptorType = type;
//     write.pBufferInfo = bufferInfo;

//     return write;
// }

fn writeDescriptorBuffer(
    descriptor_type: vk.DescriptorType,
    dst_set: vk.DescriptorSet,
    buffer_info: vk.DescriptorBufferInfo,
    binding: u32,
) !vk.WriteDescriptorSet {
    return vk.WriteDescriptorSet{
        .dst_binding = binding,
        .dst_set = dst_set,
        .descriptor_count = 1,
        .descriptor_type = descriptor_type,
        .p_buffer_info = &buffer_info,
    };
}

// VkDescriptorBufferInfo vkinit::buffer_info(VkBuffer buffer, VkDeviceSize offset, VkDeviceSize range)
// {
//     VkDescriptorBufferInfo binfo {};
//     binfo.buffer = buffer;
//     binfo.offset = offset;
//     binfo.range = range;
//     return binfo;
// }

fn bufferInfo(buffer: vk.Buffer, offset: vk.DeviceSize, range: vk.DeviceSize) !vk.DescriptorBufferInfo {
    return vk.DescriptorBufferInfo{
        .buffer = buffer,
        .offset = offset,
        .range = range,
    };
}

// VkImageCreateInfo vkinit::image_create_info(VkFormat format, VkImageUsageFlags usageFlags, VkExtent3D extent)
// {
//     VkImageCreateInfo info = {};
//     info.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
//     info.pNext = nullptr;

//     info.imageType = VK_IMAGE_TYPE_2D;

//     info.format = format;
//     info.extent = extent;

//     info.mipLevels = 1;
//     info.arrayLayers = 1;

//     //for MSAA. we will not be using it by default, so default it to 1 sample per pixel.
//     info.samples = VK_SAMPLE_COUNT_1_BIT;

//     //optimal tiling, which means the image is stored on the best gpu format
//     info.tiling = VK_IMAGE_TILING_OPTIMAL;
//     info.usage = usageFlags;

//     return info;
// }

fn imageCreateInfo(
    format: vk.Format,
    usage_flags: vk.ImageUsageFlags,
    extent: vk.Extent3D,
) !vk.ImageCreateInfo {
    return vk.ImageCreateInfo{
        .image_type = .@"2d",
        .format = format,
        .extent = extent,
        .mip_levels = 1,
        .array_layers = 1,
        .samples = .{ .@"1_bit" = true },
        .tiling = .optimal,
        .usage = usage_flags,
    };
}

// VkImageViewCreateInfo vkinit::imageview_create_info(VkFormat format, VkImage image, VkImageAspectFlags aspectFlags)
// {
//     // build a image-view for the depth image to use for rendering
//     VkImageViewCreateInfo info = {};
//     info.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
//     info.pNext = nullptr;

//     info.viewType = VK_IMAGE_VIEW_TYPE_2D;
//     info.image = image;
//     info.format = format;
//     info.subresourceRange.baseMipLevel = 0;
//     info.subresourceRange.levelCount = 1;
//     info.subresourceRange.baseArrayLayer = 0;
//     info.subresourceRange.layerCount = 1;
//     info.subresourceRange.aspectMask = aspectFlags;

//     return info;
// }

fn imageViewCreateInfo(
    format: vk.Format,
    image: vk.Image,
    aspect_flags: vk.ImageAspectFlags,
) !vk.ImageViewCreateInfo {
    return vk.ImageViewCreateInfo{
        .view_type = .@"2d",
        .image = image,
        .format = format,
        .subresource_range = vk.ImageSubresourceRange{
            .base_mip_level = 0,
            .level_count = 1,
            .base_array_layer = 0,
            .layer_count = 1,
            .aspect_mask = aspect_flags,
        },
    };
}

// VkPipelineLayoutCreateInfo vkinit::pipeline_layout_create_info()
// {
//     VkPipelineLayoutCreateInfo info {};
//     info.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
//     info.pNext = nullptr;

//     // empty defaults
//     info.flags = 0;
//     info.setLayoutCount = 0;
//     info.pSetLayouts = nullptr;
//     info.pushConstantRangeCount = 0;
//     info.pPushConstantRanges = nullptr;
//     return info;
// }

fn pipelineLayoutCreateInfo() !vk.PipelineLayoutCreateInfo {
    return vk.PipelineLayoutCreateInfo{};
}

// VkPipelineShaderStageCreateInfo vkinit::pipeline_shader_stage_create_info(VkShaderStageFlagBits stage,
//     VkShaderModule shaderModule,
//     const char * entry)
// {
//     VkPipelineShaderStageCreateInfo info {};
//     info.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
//     info.pNext = nullptr;

//     // shader stage
//     info.stage = stage;
//     // module containing the code for this shader stage
//     info.module = shaderModule;
//     // the entry point of the shader
//     info.pName = entry;
//     return info;
// }

fn pipelineShaderStageCreateInfo(
    stage: vk.ShaderStageFlagBits,
    shader_module: vk.ShaderModule,
    entry: []const u8,
) !vk.PipelineShaderStageCreateInfo {
    return vk.PipelineShaderStageCreateInfo{
        .stage = stage,
        .module = shader_module,
        .p_name = entry,
    };
}
