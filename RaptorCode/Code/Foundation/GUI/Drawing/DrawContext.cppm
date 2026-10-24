// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :draw_context partition
//
// DrawContext: the renderer seam eepp's UI lacked. eepp widgets/drawables draw straight
// through global Primitives / GlobalBatchRenderer / GLi; here every draw call routes
// through a VGContext instead. Thin wrapper (mirrors foundation.ui's UIDrawContext) adding
// clip / transform / opacity stacking and the DPI scale; the font service is not wired
// in here.

module;
#include "Core/Prelude.h"

export module foundation.gui:draw_context;

import foundation.core; // Float4x4
import foundation.vg;   // VGContext
import :rect;
import :transform2d;
import :picture_baker; // IPictureBaker

using namespace foundation::core;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    class DrawContext
    {
    public:
        explicit DrawContext(vg::VGContext& context, f32 dpiScale = 1.0f) noexcept
            : m_vg(&context), m_dpiScale(dpiScale)
        {
        }

        // The underlying vector-graphics context (the actual draw surface).
        [[nodiscard]] vg::VGContext& VG() const noexcept { return *m_vg; }
        [[nodiscard]] f32 DpiScale() const noexcept { return m_dpiScale; }
        /// The host's baker (a root's DrawFrame sets its GUI's): vector pictures drawn as baked
        /// textures; null draws them as paths.
        void SetPictureBaker(IPictureBaker* baker) noexcept { m_baker = baker; }
        [[nodiscard]] IPictureBaker* PictureBaker() const noexcept { return m_baker; }

        // Clip stack (device/local rect).
        void PushClip(const Rect& rect) { m_vg->PushClipRect(rect.ToRectangle()); }
        void PopClip() { m_vg->PopClip(); }

        // Opacity stack (multiplies down the subtree).
        void PushOpacity(f32 opacity) { m_vg->PushOpacity(opacity); }
        void PopOpacity() { m_vg->PopOpacity(); }

        // Save/restore the whole VG state (transform + clip + opacity + blend).
        void Save() { m_vg->PushState(); }
        void Restore() { m_vg->PopState(); }

        /// Device pixels per local unit under the current transform (its area scale's root), for
        /// sizes VG takes in device pixels: a blur's sigma.
        [[nodiscard]] f32 DeviceScale() const noexcept
        {
            const Float4x4 m = m_vg->GetTransform();
            return Sqrt(Abs(m(0, 0) * m(1, 1) - m(0, 1) * m(1, 0)));
        }

        // Concatenate a local transform onto the current one (child-local applied first).
        void ConcatTransform(const Transform2D& transform)
        {
            m_vg->SetTransform(transform.ToMatrix() * m_vg->GetTransform());
        }

        // What a draw did (E8a): the nodes it drew and the ones it culled.
        /// Whether a rect in the current space can put anything under the clip, with a margin for
        /// what no ink box measures (text effects an ancestor sets, glyphs past their advance,
        /// anti-aliasing). True with culling off.
        [[nodiscard]] bool IsVisible(const Rect& local) const
        {
            if (!m_culling)
                return true;
            constexpr f32 kMargin = 32.0f;
            return m_vg->IsRectVisible(Rectangle{local.x - kMargin, local.y - kMargin, local.width + 2.0f * kMargin,
                                                 local.height + 2.0f * kMargin});
        }
        /// What of the current local space can show (E15): the clip mapped back, grown by the
        /// margin IsVisible allows. False when everything can show (no clip, or culling off): a
        /// node with many children then draws them all.
        [[nodiscard]] bool GetVisibleBounds(Rect& out) const
        {
            Rectangle clip{};
            if (!m_culling || !m_vg->GetLocalClipBounds(clip))
                return false;
            constexpr f32 kMargin = 32.0f; // IsVisible's
            out = Rect{clip.x - kMargin, clip.y - kMargin, clip.width + 2.0f * kMargin, clip.height + 2.0f * kMargin};
            return true;
        }
        /// Off, every node draws, whatever the clip (the culling test's reference).
        void SetCulling(bool culling) noexcept { m_culling = culling; }
        [[nodiscard]] bool IsCulling() const noexcept { return m_culling; }
        /// The host's frame being drawn (SceneRoot::DrawFrame numbers them; 0 for a draw outside one):
        /// each node drawn notes it, so an animation knows whether its node showed.
        void SetFrame(u32 frame) noexcept { m_frame = frame; }
        [[nodiscard]] u32 Frame() const noexcept { return m_frame; }
        /// Where a node drawn that invalidated itself since its last draw notes its bounds in the
        /// world (the debug overlay's redraw flash); none by default.
        void SetRedrawRecorder(Array<Rect>* recorder) noexcept { m_redraws = recorder; }
        [[nodiscard]] bool RecordsRedraws() const noexcept { return m_redraws != nullptr; }
        void RecordRedraw(const Rect& world)
        {
            if (m_redraws != nullptr)
                m_redraws->PushBack(world);
        }
        /// Where the frame notes what it changed (E15: damage, in device pixels); none by default.
        void SetDamageRecorder(Array<Rect>* recorder) noexcept { m_damage = recorder; }
        void RecordDamage(const Rect& device)
        {
            if (m_damage != nullptr)
                m_damage->PushBack(device);
        }
        [[nodiscard]] bool RecordsDamage() const noexcept { return m_damage != nullptr; }
        /// `local` in device pixels under the current transform: the bounds of its corners.
        [[nodiscard]] Rect DeviceRect(const Rect& local) const
        {
            const core::Float4x4 m = m_vg->GetTransform();
            const core::Float2 corners[4] = {core::TransformPoint2D(core::Float2{local.x, local.y}, m),
                                             core::TransformPoint2D(core::Float2{local.Right(), local.y}, m),
                                             core::TransformPoint2D(core::Float2{local.x, local.Bottom()}, m),
                                             core::TransformPoint2D(core::Float2{local.Right(), local.Bottom()}, m)};
            core::Float2 mn = corners[0], mx = corners[0];
            for (const core::Float2& c : corners)
            {
                mn = core::Float2{core::Min(mn.x, c.x), core::Min(mn.y, c.y)};
                mx = core::Float2{core::Max(mx.x, c.x), core::Max(mx.y, c.y)};
            }
            return Rect{mn.x, mn.y, mx.x - mn.x, mx.y - mn.y};
        }
        void CountDrawn() noexcept { ++m_nodesDrawn; }
        void CountCulled() noexcept { ++m_nodesCulled; }
        [[nodiscard]] u32 NodesDrawn() const noexcept { return m_nodesDrawn; }
        [[nodiscard]] u32 NodesCulled() const noexcept { return m_nodesCulled; }

    private:
        vg::VGContext* m_vg;
        f32 m_dpiScale;
        IPictureBaker* m_baker = nullptr;
        u32 m_nodesDrawn = 0;
        u32 m_nodesCulled = 0;
        bool m_culling = true;
        u32 m_frame = 0;
        Array<Rect>* m_redraws = nullptr;
        Array<Rect>* m_damage = nullptr; // what the frame changed (E15)
    };
}
