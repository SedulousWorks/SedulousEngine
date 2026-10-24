// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :transformable partition
//
// Transformable: 2D position / rotation / scale with a lazily-recomputed combined
// Transform2D (+ its inverse). The math base of Node. Ported from eepp's
// Math::Transformable (include/eepp/math/transformable.hpp); rotation is RADIANS (eepp
// used degrees), and the setters are virtual so Node can hook invalidation.

module;
#include "Core/Prelude.h"

export module foundation.gui:transformable;

import foundation.core; // Float2
import :transform2d;

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    class Transformable
    {
    public:
        Transformable() = default;
        virtual ~Transformable() = default;

        virtual void SetPosition(core::Float2 position)
        {
            m_position = position;
            MarkDirty();
        }
        virtual void SetRotation(f32 radians)
        {
            m_rotation = radians;
            MarkDirty();
        }
        virtual void SetScale(core::Float2 factors)
        {
            m_scale = factors;
            MarkDirty();
        }
        void SetScale(f32 x, f32 y) { SetScale(core::Float2{x, y}); }
        virtual void SetScaleOrigin(core::Float2 origin)
        {
            m_scaleOrigin = origin;
            MarkDirty();
        }
        virtual void SetRotationOrigin(core::Float2 origin)
        {
            m_rotationOrigin = origin;
            MarkDirty();
        }

        [[nodiscard]] core::Float2 GetPosition() const noexcept { return m_position; }
        [[nodiscard]] f32 GetRotation() const noexcept { return m_rotation; }
        [[nodiscard]] core::Float2 GetScale() const noexcept { return m_scale; }
        [[nodiscard]] core::Float2 GetScaleOrigin() const noexcept { return m_scaleOrigin; }
        [[nodiscard]] core::Float2 GetRotationOrigin() const noexcept { return m_rotationOrigin; }

        /// A further transform about `origin` (local units), after the position, scale and rotation:
        /// CSS's `transform` with its `transform-origin`.
        void SetExtraTransform(const Transform2D& transform, core::Float2 origin)
        {
            m_extra = transform;
            m_extraOrigin = origin;
            MarkDirty();
        }
        [[nodiscard]] const Transform2D& GetExtraTransform() const noexcept { return m_extra; }

        // Relative moves.
        void Move(core::Float2 offset) { SetPosition(m_position + offset); }
        void Rotate(f32 radians) { SetRotation(m_rotation + radians); }
        void Scale(core::Float2 factor) { SetScale(m_scale * factor); }

        [[nodiscard]] const Transform2D& GetTransform() const
        {
            if (m_transformDirty)
            {
                // Post-multiply order (eepp): T(pos) * [scale about origin] * [rotate about origin].
                Transform2D t;
                t.Translate(m_position);
                if (!(m_scale.x == 1.0f && m_scale.y == 1.0f))
                {
                    t.Translate(m_scaleOrigin);
                    t.Scale(m_scale);
                    t.Translate(-m_scaleOrigin);
                }
                if (m_rotation != 0.0f)
                {
                    t.Translate(m_rotationOrigin);
                    t.Rotate(m_rotation);
                    t.Translate(-m_rotationOrigin);
                }
                if (!m_extra.IsIdentity())
                {
                    t.Translate(m_extraOrigin);
                    t.Combine(m_extra);
                    t.Translate(-m_extraOrigin);
                }
                m_transform = t;
                m_transformDirty = false;
                m_inverseDirty = true;
            }
            return m_transform;
        }

        [[nodiscard]] const Transform2D& GetInverseTransform() const
        {
            if (m_inverseDirty || m_transformDirty)
            {
                m_inverse = GetTransform().GetInverse();
                m_inverseDirty = false;
            }
            return m_inverse;
        }

    protected:
        void MarkDirty() noexcept
        {
            m_transformDirty = true;
            m_inverseDirty = true;
        }

        core::Float2 m_position{0.0f, 0.0f};
        core::Float2 m_scale{1.0f, 1.0f};
        core::Float2 m_scaleOrigin{0.0f, 0.0f};
        core::Float2 m_rotationOrigin{0.0f, 0.0f};
        f32 m_rotation = 0.0f; // radians

        mutable Transform2D m_transform{};
        mutable Transform2D m_inverse{};
        mutable bool m_transformDirty = true;
        mutable bool m_inverseDirty = true;
        Transform2D m_extra{};
        core::Float2 m_extraOrigin{};
    };
}
