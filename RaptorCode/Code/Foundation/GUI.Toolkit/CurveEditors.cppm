// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI.Toolkit - :curve_editors partition
//
// The property grid's curve and gradient editors (T5 of Specs/gui-lab-evolution-3.md), and the
// default editors registered with a grid (they are the last of them, so the registration lives
// here). A curve or a gradient is one value (PropertyKind::Curve, ::Gradient; a Variant of Core's
// keys or a ColorGradient), mixed when the objects' differ:
//   - a row shows a preview (the curve drawn, the gradient's bar), hatched when mixed;
//   - a click on it opens the full view as a popup (a ruler and a curve view, or a gradient view),
//     every edit in it previewed on each object; closing it commits once (one undo entry, as a
//     colour's picker does), Escape gives the whole of it up.
// Which runtime types are curves or gradients is the application's to say (a reflected source's
// RegisterCurveType, RegisterGradientType); these editors know only the values.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"

export module foundation.gui.toolkit:curve_editors;

import foundation.core;
import foundation.vg;
import foundation.gui;
import :property_source;
import :property_editor;
import :property_editors;
import :time_axis;
import :curve_source;
import :curve_view;
import :gradient_view;

using namespace foundation::core;
namespace core = foundation::core;
namespace vg = foundation::vg;

export namespace foundation::gui
{
    /// A popup's panel holding an editor's full view.
    class PropertyViewPopup : public UIWidget
    {
        RTTI_OBJECT(PropertyViewPopup, UIWidget)
    public:
        PropertyViewPopup()
        {
            SetTag(core::StringView(u8"propertyviewpopup"));
            SetPadding(Thickness{8.0f, 8.0f, 8.0f, 8.0f});
            EditLayoutStyle([](LayoutStyle& s)
            {
                s.Direction = FlexDirection::Column;
                s.RowGap = 2.0f;
            });
        }

    protected:
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override
        {
            if (!BoxFills())
                ctx.VG().FillRect(localBounds.ToRectangle(), Color{0.18f, 0.20f, 0.25f, 1.0f});
            UIWidget::OnDraw(ctx, localBounds);
        }
    };

    namespace detail
    {
        // Diagonal lines over `box`: a row's mixed state, as a mixed swatch shows it.
        inline void DrawHatched(DrawContext& ctx, const Rect& box, Color line)
        {
            ctx.VG().FillRect(box.ToRectangle(), Color{0.3f, 0.32f, 0.36f, 1.0f});
            ctx.PushClip(box);
            vg::PathBuilder lines;
            for (f32 x = -box.height; x < box.width; x += 6.0f)
            {
                lines.MoveTo(box.x + x, box.Bottom());
                lines.LineTo(box.x + x + box.height, box.y);
            }
            ctx.VG().StrokePath(lines.ToPath(), line, vg::StrokeStyle(1.0f));
            ctx.PopClip();
        }
    }

    /// A row's picture of a curve or a gradient; a click on it reports.
    class PropertyValuePreview : public UIWidget
    {
        RTTI_OBJECT(PropertyValuePreview, UIWidget)
    public:
        PropertyValuePreview()
        {
            SetTag(core::StringView(u8"propertypreview"));
            SetTabFocusable(true);
        }
        void SetValue(const Variant& value, bool mixed)
        {
            m_value = value;
            m_mixed = mixed;
            Invalidate();
        }
        /// A curve's values from the bottom to the top (low == high: its keys' own).
        void SetValueRange(f32 low, f32 high)
        {
            m_low = low;
            m_high = high;
            Invalidate();
        }
        void SetOnClick(core::Function<void()> callback) { m_onClick = core::Move(callback); }
        [[nodiscard]] const Variant& GetValue() const noexcept { return m_value; }
        [[nodiscard]] bool IsMixed() const noexcept { return m_mixed; }

    protected:
        void OnMouseClick(const MouseEvent& event) override
        {
            if (event.Button != MouseButton::Left)
                return;
            event.Handled = true;
            if (m_onClick && IsTreeEnabled())
                m_onClick();
        }
        void OnKeyDown(const KeyEvent& event) override
        {
            const KeyCode key = static_cast<KeyCode>(event.KeyCode);
            if (event.Target == this && event.Modifiers == 0 && (key == KeyCode::Return || key == KeyCode::Space) && m_onClick && IsTreeEnabled())
            {
                event.Handled = true;
                m_onClick();
            }
        }
        void OnDraw(DrawContext& ctx, const Rect& localBounds) override
        {
            UIWidget::OnDraw(ctx, localBounds);
            const Rect box = GetContentBounds();
            if (box.width <= 0.0f || box.height <= 0.0f)
                return;
            if (m_mixed)
            {
                detail::DrawHatched(ctx, box, GetTextColor());
                return;
            }
            if (m_value.GetType() == Variant::Type::Gradient)
            {
                const ColorGradient& gradient = m_value.AsGradient();
                detail::DrawChecker(ctx, box);
                for (f32 x = 0.0f; x < box.width; x += 2.0f)
                    ctx.VG().FillRect(Rectangle{box.x + x, box.y, core::Min(2.0f, box.width - x), box.height}, gradient.Evaluate((x + 1.0f) / box.width));
                return;
            }
            const core::Span<const CurveKey> keys = m_value.AsCurve();
            if (keys.IsEmpty())
                return;
            // Across the keys' times (from 0), up the range or the values the curve reaches, found at
            // the points it is drawn through (a steep tangent's overshoot included); held in its box.
            const f32 end = core::Max(keys[keys.Size() - 1].time, 1e-3f);
            f32 low = m_low, high = m_high;
            if (high <= low)
            {
                low = high = keys[0].value;
                for (f32 x = 0.0f; x <= box.width; x += 2.0f)
                {
                    const f32 v = EvaluateCurve(keys, end * x / box.width);
                    low = core::Min(low, v);
                    high = core::Max(high, v);
                }
                if (high - low < 1e-4f)
                {
                    low -= 0.5f;
                    high += 0.5f;
                }
            }
            ctx.PushClip(box);
            const f32 inset = 2.0f;
            vg::PathBuilder line;
            for (f32 x = 0.0f; x <= box.width; x += 2.0f)
            {
                const f32 v = EvaluateCurve(keys, end * x / box.width);
                const f32 y = box.Bottom() - inset - (v - low) / (high - low) * (box.height - 2.0f * inset);
                if (x == 0.0f)
                    line.MoveTo(box.x + x, y);
                else
                    line.LineTo(box.x + x, y);
            }
            const PartStyle& part = GetPartStyle(u8"curve");
            Color stroke = part.HasBackground ? part.Box.BackgroundColor : Color{0.31f, 0.61f, 1.0f, 1.0f};
            stroke.a *= part.Opacity;
            ctx.VG().StrokePath(line.ToPath(), stroke, vg::StrokeStyle(1.5f));
            ctx.PopClip();
        }

    private:
        Variant m_value;
        bool m_mixed = false;
        f32 m_low = 0.0f;
        f32 m_high = 0.0f;
        core::Function<void()> m_onClick;
    };

    /// A curve's editor: its preview on the row, a ruler and a curve view in a popup.
    class CurvePropertyEditor : public PropertyEditor, public ICurveSourceClient
    {
        RTTI_OBJECT(CurvePropertyEditor, PropertyEditor)
    public:
        static constexpr f32 kViewWidth = 420.0f;
        static constexpr f32 kViewHeight = 220.0f;

        CurvePropertyEditor()
        {
            AddClass(core::StringView(u8"curve"));
            CurvePropertyEditor* self = this;
            m_preview = core::MakeRef<PropertyValuePreview>(MemoryAllocator());
            m_preview->EditLayoutStyle([](LayoutStyle& s) { s.Grow = 1.0f; });
            m_preview->SetOnClick([self]() { self->OpenView(); });
            AddChild(m_preview.Get());

            m_axis = core::MakeRef<TimeAxis>(MemoryAllocator());
            m_popup = core::MakeRef<PropertyViewPopup>(MemoryAllocator());
            m_ruler = core::MakeRef<TimeRuler>(MemoryAllocator());
            m_ruler->EditLayoutStyle([](LayoutStyle& s) { s.Width = LayoutLength::Px(kViewWidth); });
            m_ruler->SetTimeAxis(m_axis);
            m_popup->AddChild(m_ruler.Get());
            m_view = core::MakeRef<CurveView>(MemoryAllocator());
            m_view->EditLayoutStyle([](LayoutStyle& s)
            {
                s.Width = LayoutLength::Px(kViewWidth);
                s.Height = LayoutLength::Px(kViewHeight);
            });
            m_view->SetTimeAxis(m_axis);
            m_curves.AddCurve(CurveInfo{});
            m_view->SetSource(&m_curves);
            m_curves.AddClient(this);
            m_popup->AddChild(m_view.Get());
        }
        ~CurvePropertyEditor() override
        {
            m_view->SetSource(nullptr);
            m_curves.RemoveClient(this);
        }

        [[nodiscard]] PropertyValuePreview* GetPreview() const noexcept { return m_preview.Get(); }
        [[nodiscard]] CurveView* GetView() const noexcept { return m_view.Get(); }
        [[nodiscard]] TimeAxis* GetTimeAxis() const noexcept { return m_axis.Get(); }
        /// Whether the popup is open.
        [[nodiscard]] bool IsViewOpen() const
        {
            const EventDispatcher* dispatcher = m_popup->GetEventDispatcher();
            return dispatcher != nullptr && dispatcher->IsPopupOpen(*m_popup);
        }
        /// Opens the view on the curve shown; its edits preview, its closing commits.
        void OpenView()
        {
            EventDispatcher* dispatcher = GetEventDispatcher();
            if (dispatcher == nullptr || IsReadOnly() || IsViewOpen())
                return;
            ShareTextStyle(*m_popup, false);
            m_loading = true;
            m_curves.SetKeys(0, m_keys.AsSpan());
            m_loading = false;
            m_editing = false;
            m_view->SetSelection({});
            // Its time across the view (at least a second, a particle curve's 0 to 1), its values
            // up the range or what the curve reaches.
            const f32 end = m_keys.IsEmpty() ? 1.0f : core::Max(1.0f, m_keys.Back().time);
            m_axis->SetDuration(end);
            m_axis->SetScroll(0.0f);
            m_axis->SetPixelsPerSecond(kViewWidth / end);
            f32 low = m_info.HasRange ? static_cast<f32>(m_info.Min) : 0.0f;
            f32 high = m_info.HasRange ? static_cast<f32>(m_info.Max) : 1.0f;
            for (const CurveKey& key : m_keys)
            {
                low = core::Min(low, key.value);
                high = core::Max(high, key.value);
            }
            const f32 margin = (high - low) * 0.1f + 1e-3f;
            m_view->SetValueRange(low - margin, high + margin);
            PopupOptions options;
            options.Anchor = m_preview.Get();
            options.Placement = PopupPlacement{PopupSide::Below, PopupAlign::Start, 2.0f, true};
            options.TakesFocus = true;
            options.FitContent = true;
            CurvePropertyEditor* self = this;
            options.OnClosed = [self](PopupCloseReason reason) { self->Closed(reason == PopupCloseReason::Escape); };
            dispatcher->OpenPopup(*this, *m_popup, core::Move(options));
        }

        // The view's edits (each a gesture of the popup's own set): previewed on the objects, the
        // edit begun at the first.
        void OnCurvesChanged() override
        {
            if (m_loading)
                return;
            const core::Span<const CurveKey> keys = m_curves.GetKeys(0);
            if (!m_editing)
            {
                if (CurveSet::Same(keys, m_keys.AsSpan()))
                    return;
                m_editing = true;
                BeginEdit();
            }
            else if (CurveSet::Same(keys, m_previewed.AsSpan()))
                return; // told again (a commit after its preview): nothing new
            m_previewed.Clear();
            for (const CurveKey& key : keys)
                m_previewed.PushBack(key);
            m_preview->SetValue(Variant::FromCurve(keys), false);
            PreviewEdit(PropertyWrite{Variant::FromCurve(keys)});
        }

    protected:
        void OnBind(const PropertyInfo& info, const PropertyValue& value) override
        {
            m_info = info;
            m_keys.Clear();
            for (const CurveKey& key : value.Value.AsCurve())
                m_keys.PushBack(key);
            m_preview->SetValue(value.Value, value.Mixed);
            m_preview->SetValueRange(info.HasRange ? static_cast<f32>(info.Min) : 0.0f, info.HasRange ? static_cast<f32>(info.Max) : 0.0f);
            m_preview->SetEnabled(!IsReadOnly());
            CurveInfo curve;
            curve.Name = info.Name;
            curve.HasRange = info.HasRange;
            curve.Min = static_cast<f32>(info.Min);
            curve.Max = static_cast<f32>(info.Max);
            curve.MaxKeys = info.MaxCount;
            curve.StrokeColor = Color{0.31f, 0.61f, 1.0f, 1.0f};
            m_curves.Info(0) = curve;
            m_loading = true; // telling the view is not an edit
            m_curves.InfoChanged();
            m_loading = false;
        }
        void OnTextStyleChange() override { ShareTextStyle(*m_preview); }

    private:
        void Closed(bool escaped)
        {
            if (!m_editing)
                return;
            m_editing = false;
            if (escaped)
                CancelEdit();
            else
                CommitEdit(PropertyWrite{Variant::FromCurve(m_curves.GetKeys(0))});
        }

        core::RefPtr<PropertyValuePreview> m_preview;
        core::RefPtr<PropertyViewPopup> m_popup;
        core::RefPtr<TimeAxis> m_axis;
        core::RefPtr<TimeRuler> m_ruler;
        core::RefPtr<CurveView> m_view;
        CurveSet m_curves; // the popup's own: the curve as it is edited
        PropertyInfo m_info;
        core::Array<CurveKey> m_keys; // the value bound
        core::Array<CurveKey> m_previewed; // what the edit last previewed
        bool m_loading = false;
        bool m_editing = false; // the edit begun, its popup open
    };

    /// A gradient's editor: its bar on the row, a gradient view in a popup.
    class GradientPropertyEditor : public PropertyEditor
    {
        RTTI_OBJECT(GradientPropertyEditor, PropertyEditor)
    public:
        GradientPropertyEditor()
        {
            AddClass(core::StringView(u8"gradient"));
            GradientPropertyEditor* self = this;
            m_preview = core::MakeRef<PropertyValuePreview>(MemoryAllocator());
            m_preview->EditLayoutStyle([](LayoutStyle& s) { s.Grow = 1.0f; });
            m_preview->SetOnClick([self]() { self->OpenView(); });
            AddChild(m_preview.Get());
            m_popup = core::MakeRef<PropertyViewPopup>(MemoryAllocator());
            m_view = core::MakeRef<GradientView>(MemoryAllocator());
            m_view->EditLayoutStyle([](LayoutStyle& s) { s.Width = LayoutLength::Px(360.0f); });
            m_view->SetOnGradientChanging([self](const ColorGradient& value) { self->Edited(value); });
            m_view->SetOnGradientChanged([self](const ColorGradient& value) { self->Edited(value); });
            m_view->SetOnGradientCancelled([self]() { self->Edited(self->m_view->GetValue()); });
            m_popup->AddChild(m_view.Get());
        }

        [[nodiscard]] PropertyValuePreview* GetPreview() const noexcept { return m_preview.Get(); }
        [[nodiscard]] GradientView* GetView() const noexcept { return m_view.Get(); }
        [[nodiscard]] bool IsViewOpen() const
        {
            const EventDispatcher* dispatcher = m_popup->GetEventDispatcher();
            return dispatcher != nullptr && dispatcher->IsPopupOpen(*m_popup);
        }
        void OpenView()
        {
            EventDispatcher* dispatcher = GetEventDispatcher();
            if (dispatcher == nullptr || IsReadOnly() || IsViewOpen())
                return;
            ShareTextStyle(*m_popup, false);
            m_view->SetValue(m_gradient);
            m_view->Select(GradientStopRef{});
            m_editing = false;
            PopupOptions options;
            options.Anchor = m_preview.Get();
            options.Placement = PopupPlacement{PopupSide::Below, PopupAlign::Start, 2.0f, true};
            options.TakesFocus = true;
            options.FitContent = true;
            GradientPropertyEditor* self = this;
            options.OnClosed = [self](PopupCloseReason reason) { self->Closed(reason == PopupCloseReason::Escape); };
            dispatcher->OpenPopup(*this, *m_popup, core::Move(options));
        }

    protected:
        void OnBind(const PropertyInfo& info, const PropertyValue& value) override
        {
            m_gradient = value.Value.AsGradient();
            m_preview->SetValue(value.Value, value.Mixed);
            m_preview->SetEnabled(!IsReadOnly());
            m_view->SetMaxStops(info.MaxCount);
        }
        void OnTextStyleChange() override { ShareTextStyle(*m_preview); }

    private:
        void Edited(const ColorGradient& value)
        {
            if (!m_editing)
            {
                if (value == m_gradient)
                    return;
                m_editing = true;
                BeginEdit();
            }
            m_preview->SetValue(Variant(value), false);
            PreviewEdit(PropertyWrite{Variant(value)});
        }
        void Closed(bool escaped)
        {
            if (!m_editing)
                return;
            m_editing = false;
            if (escaped)
                CancelEdit();
            else
                CommitEdit(PropertyWrite{Variant(m_view->GetValue())});
        }

        core::RefPtr<PropertyValuePreview> m_preview;
        core::RefPtr<PropertyViewPopup> m_popup;
        core::RefPtr<GradientView> m_view;
        ColorGradient m_gradient; // the value bound
        bool m_editing = false;
    };

    /// Registers the default editors with `registry`: bool, integer, float, string, enum and flags
    /// by kind (T1); lists by kind, Float2, Float3 and Float4 by hint (T2); colours by kind, stops
    /// and HDR colours by hint (T4); curves and gradients by kind (T5).
    inline void RegisterDefaultPropertyEditors(PropertyEditorRegistry& registry)
    {
        const core::StringView floats[] = {core::StringView(u8"Float2"), core::StringView(u8"Float3"), core::StringView(u8"Float4")};
        for (const core::StringView hint : floats)
            registry.RegisterHint(hint, [](core::IAllocator& a) -> core::RefPtr<PropertyEditor> { return core::MakeRef<FloatsPropertyEditor>(a); }, true);
        registry.RegisterKind(PropertyKind::Bool, [](core::IAllocator& a) -> core::RefPtr<PropertyEditor> { return core::MakeRef<BoolPropertyEditor>(a); });
        registry.RegisterKind(PropertyKind::Integer, [](core::IAllocator& a) -> core::RefPtr<PropertyEditor> { return core::MakeRef<NumberPropertyEditor>(a); });
        registry.RegisterKind(PropertyKind::Float, [](core::IAllocator& a) -> core::RefPtr<PropertyEditor> { return core::MakeRef<NumberPropertyEditor>(a); });
        registry.RegisterKind(PropertyKind::String, [](core::IAllocator& a) -> core::RefPtr<PropertyEditor> { return core::MakeRef<StringPropertyEditor>(a); });
        registry.RegisterKind(PropertyKind::Enum, [](core::IAllocator& a) -> core::RefPtr<PropertyEditor> { return core::MakeRef<EnumPropertyEditor>(a); });
        registry.RegisterKind(PropertyKind::Color, [](core::IAllocator& a) -> core::RefPtr<PropertyEditor> { return core::MakeRef<ColorPropertyEditor>(a); });
        registry.RegisterHint(core::StringView(u8"stops"), [](core::IAllocator& a) -> core::RefPtr<PropertyEditor> { return core::MakeRef<StopsPropertyEditor>(a); });
        registry.RegisterHint(core::StringView(u8"ColorHdr"), [](core::IAllocator& a) -> core::RefPtr<PropertyEditor> { return core::MakeRef<HdrColorPropertyEditor>(a); },
                              true);
        registry.RegisterKind(PropertyKind::List, [](core::IAllocator& a) -> core::RefPtr<PropertyEditor> { return core::MakeRef<ListPropertyEditor>(a); });
        registry.RegisterKind(PropertyKind::Flags, [](core::IAllocator& a) -> core::RefPtr<PropertyEditor> { return core::MakeRef<FlagsPropertyEditor>(a); });
        registry.RegisterKind(PropertyKind::Curve, [](core::IAllocator& a) -> core::RefPtr<PropertyEditor> { return core::MakeRef<CurvePropertyEditor>(a); });
        registry.RegisterKind(PropertyKind::Gradient, [](core::IAllocator& a) -> core::RefPtr<PropertyEditor> { return core::MakeRef<GradientPropertyEditor>(a); });
    }
}
