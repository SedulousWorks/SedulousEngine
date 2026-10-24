// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Hosting - :vg_shaders partition: the VG shaders a host draws the GUI with.
//
// VgShaderSet names them (the vertex and fragment shaders every draw needs, and those of the
// gradients, the distance-field text, box shadows, analytic boxes, layers and blurs, each optional:
// a missing one leaves its draws to a fallback, as VG's renderer has it). VgShaderLibrary resolves
// them from an application's data mount through the shared shader host: cooked from
// Shaders/shaders.dpak in a build that ships, compiled from Shaders/ in development. A test hands
// GuiHost a set of its own instead.

module;
#include "Core/Prelude.h"

export module foundation.gui.hosting:vg_shaders;

import foundation.core;
import foundation.rhi;
import foundation.vfs;
import foundation.shaders;
import foundation.shaders.system;

using namespace foundation::core;
namespace core = foundation::core;
namespace rhi = foundation::rhi;
namespace shaders = foundation::shaders;

export namespace foundation::gui
{
    struct VgShaderSet
    {
        rhi::ShaderModule* Vertex = nullptr;
        rhi::ShaderModule* Fragment = nullptr;
        rhi::ShaderModule* GradientRadial = nullptr;
        rhi::ShaderModule* GradientConic = nullptr;
        rhi::ShaderModule* DistanceField = nullptr;
        rhi::ShaderModule* BoxShadow = nullptr;
        rhi::ShaderModule* BoxVertex = nullptr;
        rhi::ShaderModule* BoxFragment = nullptr;
        rhi::ShaderModule* Layer = nullptr;
        rhi::ShaderModule* BlurVertex = nullptr;
        rhi::ShaderModule* BlurFragment = nullptr;

        /// Whether anything can be drawn: the two every draw needs are there.
        [[nodiscard]] bool IsUsable() const noexcept { return Vertex != nullptr && Fragment != nullptr; }
    };

    /// The VG shaders from an application's data mount. Owns them: it outlives the hosts that draw
    /// with them.
    class VgShaderLibrary
    {
    public:
        explicit VgShaderLibrary(IAllocator& allocator) noexcept : m_host(allocator) {}

        /// Resolves the set for `device` from `data` (borrowed while the library lives); false when
        /// neither a compiler with sources nor a cooked pack is there, or the two needed are not.
        bool Load(rhi::Device& device, foundation::vfs::IFileSystem& data)
        {
            if (!m_host.Initialize(device, data))
                return false;
            const auto variant = [this](core::StringView name, shaders::ShaderStage stage)
            { return m_host.GetVariant(name, stage, shaders::ShaderFlags::None); };
            m_set.Vertex = variant(u8"vg", shaders::ShaderStage::Vertex);
            m_set.Fragment = variant(u8"vg", shaders::ShaderStage::Fragment);
            m_set.GradientRadial = variant(u8"vg_grad_radial", shaders::ShaderStage::Fragment);
            m_set.GradientConic = variant(u8"vg_grad_conic", shaders::ShaderStage::Fragment);
            m_set.DistanceField = variant(u8"vg_df", shaders::ShaderStage::Fragment);
            m_set.BoxShadow = variant(u8"vg_shadow", shaders::ShaderStage::Fragment);
            m_set.BoxVertex = variant(u8"vg_box", shaders::ShaderStage::Vertex);
            m_set.BoxFragment = variant(u8"vg_box", shaders::ShaderStage::Fragment);
            m_set.Layer = variant(u8"vg_layer", shaders::ShaderStage::Fragment);
            m_set.BlurVertex = variant(u8"vg_blur", shaders::ShaderStage::Vertex);
            m_set.BlurFragment = variant(u8"vg_blur", shaders::ShaderStage::Fragment);
            return m_set.IsUsable();
        }

        [[nodiscard]] const VgShaderSet& Set() const noexcept { return m_set; }

    private:
        shaders::ShaderSystemHost m_host; // owns the modules the set names
        VgShaderSet m_set;
    };
}
