// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUISandbox - the Toolkit page's property source (T1 and T2 of Specs/gui-lab-evolution-3.md): three
// lamps, an application's own objects, behind a selection of one or all of them, with the undo an
// application keeps (every lamp as it was before and after each change, one entry whatever the
// gesture previewed). Its paths:
//   - name, a read-only id, enabled, type (an enum), intensity, range, shadows (flags), bounces;
//   - position, a Float3; rotation, a Float3 of Euler degrees over a stored Quaternion, the source
//     converting as the editor's Transform row does; cone, a Float2 shown only on spots (changing
//     the type tells the grid its properties changed);
//   - tags, a list of text of at most four; effects, a list of two types (Flicker, Pulse), each a
//     group of its own values;
//   - flicker, a curve of Core's keys (T5): its row a preview, its editor the toolkit's curve view;
//   - falloff, hinted "falloff", which no editor takes.
// Each lamp's defaults are how it started; a revert puts them back. Copying writes a path and what
// is under it with the engine's XmlSerializer, a shape first, so a paste refuses another shape.
// The page's clip writes sampled values into the lamps (SetAnimatedValue) as it is scrubbed, with no
// history: the grid follows.

module;
#include "Core/Prelude.h"

export module gui.sandbox.lamps;

import foundation.core;
import foundation.xml;
import foundation.xml.serialization;
import foundation.gui;
import foundation.gui.toolkit;

using namespace foundation::core;
namespace core = foundation::core;
namespace gui = foundation::gui;
namespace xml = foundation::xml;

export namespace sandbox
{
    class LampSource : public gui::IPropertySource
    {
    public:
        static constexpr usize kLamps = 3;
        static constexpr u32 kMostTags = 4;

        explicit LampSource(IAllocator& allocator)
            : m_allocator(allocator), m_lamps{Lamp(allocator), Lamp(allocator), Lamp(allocator)},
              m_defaults{Lamp(allocator), Lamp(allocator), Lamp(allocator)}, m_selection(allocator), m_originals(allocator),
              m_undo(allocator), m_redo(allocator)
        {
            const char8_t* const names[kLamps] = {u8"Lamp A", u8"Lamp B", u8"Lamp C"};
            for (usize i = 0; i < kLamps; ++i)
            {
                Lamp& lamp = m_lamps[i];
                lamp.Name = String(names[i]);
                lamp.Id = 101 + static_cast<i64>(i);
                lamp.Position[0] = static_cast<f64>(i) * 2.0;
                lamp.Position[1] = 3.0;
                lamp.Tags.PushBack(String(u8"indoor"));
                // A flicker over a second: bright, a dip, a recovery, a smaller dip.
                const f32 times[] = {0.0f, 0.15f, 0.3f, 0.55f, 0.8f, 1.0f};
                const f32 values[] = {1.0f, 0.4f, 0.9f, 0.55f, 1.0f, 0.8f};
                for (usize k = 0; k < 6; ++k)
                    lamp.FlickerCurve.PushBack(CurveKey{times[k], values[k], 0.0f, 0.0f, CurveKeyInterpolation::Cubic, CurveTangentMode::Auto});
                ApplyTangentModes(lamp.FlickerCurve.AsSpan());
            }
            // The second differs in intensity, type, a shadow flag, its turn and its effects, so
            // all three show them mixed.
            m_lamps[1].Intensity = 12.5;
            m_lamps[1].Type = 1;
            m_lamps[1].Shadows = 0b011;
            m_lamps[1].Rotation = FromYawPitchRoll(DegreesToRadians(30.0f), 0.0f, 0.0f);
            m_lamps[1].Effects.PushBack(Pulse());
            m_lamps[2].Enabled = false;
            for (usize i = 0; i < kLamps; ++i)
                m_defaults[i] = m_lamps[i]; // how each started is its default
            SetSelection(0);
        }

        /// Edits lamp `lamp`, or all of them with kLamps.
        void SetSelection(usize lamp)
        {
            m_selection.Clear();
            for (usize i = 0; i < kLamps; ++i)
                if (lamp >= kLamps || lamp == i)
                    m_selection.PushBack(i);
            NotifyPropertiesChanged();
        }

        [[nodiscard]] bool CanUndo() const noexcept { return !m_undo.IsEmpty(); }
        [[nodiscard]] bool CanRedo() const noexcept { return !m_redo.IsEmpty(); }
        void Undo() { Step(m_undo, m_redo, true); }
        void Redo() { Step(m_redo, m_undo, false); }
        /// A value the page's clip plays into lamp `lamp` at `path`: shown, kept in no history.
        void SetAnimatedValue(usize lamp, StringView path, f64 value)
        {
            if (lamp >= kLamps)
                return;
            Write(m_lamps[lamp], path, gui::Variant(value));
            NotifyValuesChanged();
        }
        /// The lamp named `name` (Lamp A, B or C); kLamps when none is.
        [[nodiscard]] usize FindLamp(StringView name) const
        {
            for (usize i = 0; i < kLamps; ++i)
                if (m_lamps[i].Name.AsView() == name)
                    return i;
            return kLamps;
        }
        /// Told when the history changes (to enable Undo and Redo) and what changed, in words.
        void SetOnHistoryChanged(Function<void(StringView)> changed) { m_onHistory = core::Move(changed); }

        // === gui::IPropertySource ===
        [[nodiscard]] usize ObjectCount() const override { return m_selection.Size(); }

        void GetProperties(StringView parent, Array<gui::PropertyInfo>& out) const override
        {
            using K = gui::PropertyKind;
            if (parent == StringView(u8"position"))
            {
                Add(out, u8"x", K::Float, u8"", u8"X").Step = 0.1;
                Add(out, u8"y", K::Float, u8"", u8"Y").Step = 0.1;
                Add(out, u8"z", K::Float, u8"", u8"Z").Step = 0.1;
                return;
            }
            if (parent == StringView(u8"rotation"))
            {
                Add(out, u8"pitch", K::Float, u8"", u8"Pitch");
                Add(out, u8"yaw", K::Float, u8"", u8"Yaw");
                Add(out, u8"roll", K::Float, u8"", u8"Roll");
                return;
            }
            if (parent == StringView(u8"cone"))
            {
                const StringView parts[] = {StringView(u8"inner"), StringView(u8"outer")};
                for (const StringView part : parts)
                {
                    gui::PropertyInfo& angle = Add(out, part, K::Float, u8"", part == StringView(u8"inner") ? StringView(u8"Inner") : StringView(u8"Outer"));
                    angle.HasRange = true;
                    angle.Min = 1.0;
                    angle.Max = 179.0;
                }
                return;
            }
            if (parent == StringView(u8"tags"))
            {
                for (usize i = 0; i < Fewest(true); ++i)
                    Add(out, Format(u8"{}", i).AsView(), K::String, u8"", Format(u8"Tag {}", i + 1).AsView());
                return;
            }
            if (parent == StringView(u8"effects"))
            {
                for (usize i = 0; i < Fewest(false); ++i)
                    Add(out, Format(u8"{}", i).AsView(), K::Group, u8"", Lead().Effects[i].Type == 0 ? StringView(u8"Flicker") : StringView(u8"Pulse"));
                return;
            }
            if (const Optional<usize> index = EffectIndex(parent); index.HasValue())
            {
                if (index.Value() >= Lead().Effects.Size())
                    return;
                if (Lead().Effects[index.Value()].Type == 0)
                {
                    Add(out, u8"speed", K::Float, u8"", u8"Speed").Step = 0.1;
                    Add(out, u8"amount", K::Float, u8"", u8"Amount").Step = 0.05;
                }
                else
                    Add(out, u8"period", K::Float, u8"", u8"Period").Step = 0.1;
                return;
            }
            if (parent.Size() != 0)
                return;

            Add(out, u8"name", K::String, u8"", u8"Name").Description = String(u8"What the scene calls it");
            gui::PropertyInfo& id = Add(out, u8"id", K::Integer, u8"", u8"Id");
            id.ReadOnly = true;
            id.Description = String(u8"Given by the scene: read only");
            Add(out, u8"enabled", K::Bool, u8"Light", u8"Enabled");
            gui::PropertyInfo& type = Add(out, u8"type", K::Enum, u8"Light", u8"Type");
            type.Choices.PushBack(gui::PropertyChoice{String(u8"Point"), 0});
            type.Choices.PushBack(gui::PropertyChoice{String(u8"Spot"), 1});
            type.Choices.PushBack(gui::PropertyChoice{String(u8"Area"), 2});
            gui::PropertyInfo& intensity = Add(out, u8"intensity", K::Float, u8"Light", u8"Intensity");
            intensity.HasRange = true;
            intensity.Min = 0.0;
            intensity.Max = 100.0;
            intensity.Step = 0.5;
            intensity.Description = String(u8"Drag across it to scrub; Escape gives the scrub up");
            Add(out, u8"range", K::Float, u8"Light", u8"Range").Step = 0.25;
            gui::PropertyInfo& flicker = Add(out, u8"flicker", K::Curve, u8"Light", u8"Flicker");
            flicker.HasRange = true;
            flicker.Min = 0.0;
            flicker.Max = 1.5;
            flicker.MaxCount = 8;
            flicker.Description = String(u8"Its brightness over a second: click for the curve");
            gui::PropertyInfo& cone = Add(out, u8"cone", K::Group, u8"Light", u8"Cone");
            cone.Hint = String(u8"Float2");
            cone.Visible = AllSpots();
            cone.Description = String(u8"Only a spot has one: its inner and outer angles");
            gui::PropertyInfo& shadows = Add(out, u8"shadows", K::Flags, u8"Light", u8"Shadows");
            shadows.Choices.PushBack(gui::PropertyChoice{String(u8"Cast"), 1});
            shadows.Choices.PushBack(gui::PropertyChoice{String(u8"Receive"), 2});
            shadows.Choices.PushBack(gui::PropertyChoice{String(u8"Static"), 4});
            Add(out, u8"position", K::Group, u8"Transform", u8"Position").Hint = String(u8"Float3");
            gui::PropertyInfo& rotation = Add(out, u8"rotation", K::Group, u8"Transform", u8"Rotation");
            rotation.Hint = String(u8"Float3");
            rotation.Description = String(u8"Euler degrees over the lamp's Quaternion");
            gui::PropertyInfo& tags = Add(out, u8"tags", K::List, u8"Lists", u8"Tags");
            tags.ListOps = gui::PropertyListAdd | gui::PropertyListRemove | gui::PropertyListMove;
            tags.MaxCount = kMostTags;
            tags.Description = String(u8"At most four");
            gui::PropertyInfo& effects = Add(out, u8"effects", K::List, u8"Lists", u8"Effects");
            effects.ListOps = gui::PropertyListAdd | gui::PropertyListRemove | gui::PropertyListMove;
            effects.ElementTypes.PushBack(String(u8"Flicker"));
            effects.ElementTypes.PushBack(String(u8"Pulse"));
            Add(out, u8"bounces", K::Integer, u8"Advanced", u8"Bounces").Description = String(u8"An integer: no range, snapped to whole numbers");
            gui::PropertyInfo& falloff = Add(out, u8"falloff", K::Group, u8"Advanced", u8"Falloff");
            falloff.Hint = String(u8"falloff"); // a hint no editor takes: the row says so
            falloff.Description = String(u8"A hint no editor takes");
        }

        [[nodiscard]] gui::Variant GetValue(StringView path, usize object) const override
        {
            return object < m_selection.Size() ? ValueOf(m_lamps[m_selection[object]], path) : gui::Variant{};
        }

        void BeginEdit(StringView path) override
        {
            Original original{String(path), Array<gui::Variant>(m_allocator)};
            for (const usize lamp : m_selection)
                original.Values.PushBack(Read(m_lamps[lamp], path));
            m_originals.PushBack(core::Move(original));
        }
        void PreviewEdit(StringView path, const gui::PropertyWrite& write) override
        {
            for (const usize lamp : m_selection)
                Write(m_lamps[lamp], path, gui::ApplyPropertyWrite(Read(m_lamps[lamp], path), write));
            Changed(path);
        }
        void CommitEdit(StringView path, const gui::PropertyWrite& write) override
        {
            if (const Original* original = FindOriginal(path))
                for (usize i = 0; i < m_selection.Size() && i < original->Values.Size(); ++i)
                    Write(m_lamps[m_selection[i]], path, original->Values[i]); // the originals back first
            DropOriginal(path);
            Change(Format(u8"Set {}", path).AsView(), path, [&](Lamp& lamp)
            { Write(lamp, path, gui::ApplyPropertyWrite(Read(lamp, path), write)); });
        }
        void CancelEdit(StringView path) override
        {
            if (const Original* original = FindOriginal(path))
                for (usize i = 0; i < m_selection.Size() && i < original->Values.Size(); ++i)
                    Write(m_lamps[m_selection[i]], path, original->Values[i]);
            DropOriginal(path);
            Changed(path);
        }

        bool EditList(StringView path, const gui::ListEdit& edit) override
        {
            const bool tags = path == StringView(u8"tags");
            if (!tags && path != StringView(u8"effects"))
                return false;
            bool changed = false;
            const auto apply = [&](auto& list, auto made, usize most)
            {
                switch (edit.Kind)
                {
                case gui::ListEdit::Op::Insert:
                    if (list.Size() < most)
                    {
                        list.Insert(core::Min(edit.Index, list.Size()), made);
                        changed = true;
                    }
                    break;
                case gui::ListEdit::Op::Remove:
                    if (edit.Index < list.Size())
                    {
                        list.RemoveAt(edit.Index);
                        changed = true;
                    }
                    break;
                case gui::ListEdit::Op::Move:
                    if (edit.Index < list.Size() && edit.To < list.Size() && edit.Index != edit.To)
                    {
                        auto moved = list[edit.Index];
                        list.RemoveAt(edit.Index);
                        list.Insert(edit.To, core::Move(moved));
                        changed = true;
                    }
                    break;
                }
            };
            const String words = edit.Kind == gui::ListEdit::Op::Insert   ? Format(u8"Added to {}", path)
                                 : edit.Kind == gui::ListEdit::Op::Remove ? Format(u8"Removed from {}", path)
                                                                          : Format(u8"Moved in {}", path);
            Change(words.AsView(), StringView(u8"type"), [&](Lamp& lamp) // the rows change: read again
            {
                if (tags)
                    apply(lamp.Tags, String(u8"new"), kMostTags);
                else
                    apply(lamp.Effects, edit.ElementType == StringView(u8"Pulse") ? Pulse() : Flicker(), ~usize{0});
            });
            if (!changed)
                DropLast();
            return changed;
        }

        [[nodiscard]] gui::Variant GetDefault(StringView path, usize object) const override
        {
            if (object >= m_selection.Size() || path == StringView(u8"id")) // the scene's id is no default
                return gui::Variant{};
            return ValueOf(m_defaults[m_selection[object]], path);
        }
        bool Revert(StringView path) override
        {
            bool changed = false;
            Change(Format(u8"Reverted {}", path).AsView(), StringView(u8"type"), [&](Lamp& lamp)
            {
                const Lamp before = lamp;
                PutUnder(lamp, m_defaults[static_cast<usize>(&lamp - m_lamps)], path);
                changed = changed || !Same(before, lamp);
            });
            if (!changed)
                DropLast();
            return changed;
        }
        [[nodiscard]] String GetRevertText(StringView) const override { return String(u8"Revert to how it started"); }

        // `path` and what is under it, the first lamp's, written with the engine's XmlSerializer: its
        // shape, a list's count and its effects' types, then each value under its path from here.
        [[nodiscard]] String CopyValue(StringView path) const override
        {
            if (m_selection.IsEmpty() || path == StringView(u8"falloff"))
                return String{};
            const Lamp& lamp = Lead();
            xml::XmlSerializer ar(m_allocator);
            String shape = ShapeOf(path);
            Serialize(ar, "shape", shape);
            if (path == StringView(u8"tags") || path == StringView(u8"effects"))
            {
                i64 count = static_cast<i64>(path == StringView(u8"tags") ? lamp.Tags.Size() : lamp.Effects.Size());
                Serialize(ar, "count", count);
                if (path == StringView(u8"effects"))
                    for (i64 i = 0; i < count; ++i)
                    {
                        i64 type = lamp.Effects[static_cast<usize>(i)].Type;
                        Serialize(ar, Key(Format(u8"{}.type", i)).items, type);
                    }
            }
            Array<String> leaves(m_allocator);
            LeavesOf(lamp, path, leaves);
            if (shape.AsView() == StringView(u8"Float2") || shape.AsView() == StringView(u8"Float3"))
            {
                Lamp written = lamp; // writing reads it alone
                SerializeFloats(ar, written, leaves, shape.AsView() == StringView(u8"Float3"));
            }
            else
                for (const String& leaf : leaves)
                {
                    gui::Variant value = Read(lamp, leaf.AsView());
                    SerializeVariant(ar, Key(Relative(path, leaf)).items, value);
                }
            String text;
            ar.GetOutput(text);
            return ar.IsOk() ? text : String{};
        }
        bool PasteValue(StringView path, StringView text, String& reason) override
        {
            xml::XmlDocument doc(m_allocator);
            String shape;
            if (doc.Parse(text) == xml::XmlResult::Ok)
            {
                xml::XmlSerializer probe(doc);
                Serialize(probe, "shape", shape);
            }
            if (shape.Size() == 0)
            {
                reason = String(u8"The clipboard holds no copied property");
                return false;
            }
            if (path == StringView(u8"id"))
            {
                reason = String(u8"The id is read only");
                return false;
            }
            if (shape != ShapeOf(path))
            {
                reason = Format(u8"A {} does not paste onto {}", shape, ShapeOf(path));
                return false;
            }
            // Read into a copy of the first lamp, then give every selected lamp the same.
            xml::XmlSerializer ar(doc);
            Serialize(ar, "shape", shape);
            Lamp pasted = Lead();
            if (path == StringView(u8"tags") || path == StringView(u8"effects"))
            {
                i64 count = 0;
                Serialize(ar, "count", count);
                count = core::Clamp<i64>(count, 0, path == StringView(u8"tags") ? kMostTags : 64);
                if (path == StringView(u8"tags"))
                {
                    pasted.Tags.Clear();
                    for (i64 i = 0; i < count; ++i)
                        pasted.Tags.PushBack(String{});
                }
                else
                {
                    pasted.Effects.Clear();
                    for (i64 i = 0; i < count; ++i)
                    {
                        i64 type = 0;
                        Serialize(ar, Key(Format(u8"{}.type", i)).items, type);
                        pasted.Effects.PushBack(type == 1 ? Pulse() : Flicker());
                    }
                }
            }
            Array<String> leaves(m_allocator);
            LeavesOf(pasted, path, leaves);
            if (shape.AsView() == StringView(u8"Float2") || shape.AsView() == StringView(u8"Float3"))
                SerializeFloats(ar, pasted, leaves, shape.AsView() == StringView(u8"Float3"));
            else
                for (const String& leaf : leaves)
                {
                    gui::Variant value = Read(pasted, leaf.AsView());
                    SerializeVariant(ar, Key(Relative(path, leaf)).items, value);
                    Write(pasted, leaf.AsView(), value);
                }
            if (!ar.IsOk())
            {
                reason = String(u8"The copied values do not fit");
                return false;
            }
            Change(Format(u8"Pasted {}", path).AsView(), StringView(u8"type"), [&](Lamp& lamp) { PutUnder(lamp, pasted, path); });
            return true;
        }

    private:
        struct Effect
        {
            i64 Type = 0; // 0 Flicker, 1 Pulse
            f64 Speed = 4.0;
            f64 Amount = 0.25;
            f64 Period = 1.0;
        };
        static Effect Flicker() { return Effect{0, 4.0, 0.25, 1.0}; }
        static Effect Pulse() { return Effect{1, 1.0, 0.5, 2.0}; }
        struct Lamp
        {
            explicit Lamp(IAllocator& allocator) : Tags(allocator), Effects(allocator), FlickerCurve(allocator) {}
            String Name;
            i64 Id = 0;
            bool Enabled = true;
            i64 Type = 0;
            f64 Intensity = 5.0;
            f64 Range = 10.0;
            f64 Cone[2] = {20.0, 35.0};
            i64 Shadows = 0b001;
            f64 Position[3] = {0.0, 0.0, 0.0};
            Quaternion Rotation = Quaternion::Identity;
            Array<String> Tags;
            Array<Effect> Effects;
            i64 Bounces = 2;
            Array<CurveKey> FlickerCurve;
        };
        struct Original
        {
            String Path;
            Array<gui::Variant> Values;
        };
        // A change: every lamp as it was before and after, and what it was, in words.
        struct Entry
        {
            String Words;
            Array<Lamp> Before;
            Array<Lamp> After;
        };

        static gui::PropertyInfo& Add(Array<gui::PropertyInfo>& out, StringView name, gui::PropertyKind kind, StringView category, StringView shown)
        {
            gui::PropertyInfo info;
            info.Name = String(name);
            info.DisplayName = String(shown);
            info.Kind = kind;
            info.Category = String(category);
            out.PushBack(core::Move(info));
            return out.Back();
        }
        [[nodiscard]] const Lamp& Lead() const { return m_lamps[m_selection.IsEmpty() ? 0 : m_selection[0]]; }
        [[nodiscard]] bool AllSpots() const
        {
            for (const usize lamp : m_selection)
                if (m_lamps[lamp].Type != 1)
                    return false;
            return !m_selection.IsEmpty();
        }
        // The fewest tags (or effects) any selected lamp has: the elements shown.
        [[nodiscard]] usize Fewest(bool tags) const
        {
            usize count = ~usize{0};
            for (const usize lamp : m_selection)
                count = core::Min(count, tags ? m_lamps[lamp].Tags.Size() : m_lamps[lamp].Effects.Size());
            return m_selection.IsEmpty() ? 0 : count;
        }
        // "effects.2" -> 2.
        [[nodiscard]] static Optional<usize> EffectIndex(StringView path)
        {
            usize index = 0;
            StringView field;
            return ElementOf(path, StringView(u8"effects"), index, field) && field.Size() == 0 ? Optional<usize>(index) : Optional<usize>{};
        }
        // "tags.1" -> 1; "effects.0.speed" -> 0 and "speed".
        [[nodiscard]] static bool ElementOf(StringView path, StringView list, usize& index, StringView& field)
        {
            if (path.Size() <= list.Size() + 1 || path.SubStr(0, list.Size()) != list || path[list.Size()] != u8'.')
                return false;
            StringView rest = path.SubStr(list.Size() + 1, path.Size() - list.Size() - 1);
            field = StringView{};
            for (usize i = 0; i < rest.Size(); ++i)
                if (rest[i] == u8'.')
                {
                    field = rest.SubStr(i + 1, rest.Size() - i - 1);
                    rest = rest.SubStr(0, i);
                    break;
                }
            const Optional<i64> parsed = ParseInt(rest);
            if (!parsed.HasValue() || parsed.Value() < 0)
                return false;
            index = static_cast<usize>(parsed.Value());
            return true;
        }

        // A value as the grid reads it: a list's is its count.
        [[nodiscard]] static gui::Variant ValueOf(const Lamp& lamp, StringView path)
        {
            if (path == StringView(u8"tags"))
                return gui::Variant(static_cast<i64>(lamp.Tags.Size()));
            if (path == StringView(u8"effects"))
                return gui::Variant(static_cast<i64>(lamp.Effects.Size()));
            return Read(lamp, path);
        }
        [[nodiscard]] static gui::Variant Read(const Lamp& lamp, StringView path)
        {
            if (path == StringView(u8"name"))
                return gui::Variant(lamp.Name.AsView());
            if (path == StringView(u8"id"))
                return gui::Variant(lamp.Id);
            if (path == StringView(u8"enabled"))
                return gui::Variant(lamp.Enabled);
            if (path == StringView(u8"type"))
                return gui::Variant(lamp.Type);
            if (path == StringView(u8"intensity"))
                return gui::Variant(lamp.Intensity);
            if (path == StringView(u8"range"))
                return gui::Variant(lamp.Range);
            if (path == StringView(u8"cone.inner"))
                return gui::Variant(lamp.Cone[0]);
            if (path == StringView(u8"cone.outer"))
                return gui::Variant(lamp.Cone[1]);
            if (path == StringView(u8"shadows"))
                return gui::Variant(lamp.Shadows);
            if (path == StringView(u8"bounces"))
                return gui::Variant(lamp.Bounces);
            if (path == StringView(u8"flicker"))
                return gui::Variant::FromCurve(lamp.FlickerCurve.AsSpan());
            if (path == StringView(u8"position.x"))
                return gui::Variant(lamp.Position[0]);
            if (path == StringView(u8"position.y"))
                return gui::Variant(lamp.Position[1]);
            if (path == StringView(u8"position.z"))
                return gui::Variant(lamp.Position[2]);
            if (path == StringView(u8"rotation.pitch"))
                return gui::Variant(static_cast<f64>(EulerDegrees(lamp.Rotation).x));
            if (path == StringView(u8"rotation.yaw"))
                return gui::Variant(static_cast<f64>(EulerDegrees(lamp.Rotation).y));
            if (path == StringView(u8"rotation.roll"))
                return gui::Variant(static_cast<f64>(EulerDegrees(lamp.Rotation).z));
            usize index = 0;
            StringView field;
            if (ElementOf(path, StringView(u8"tags"), index, field))
                return index < lamp.Tags.Size() && field.Size() == 0 ? gui::Variant(lamp.Tags[index].AsView()) : gui::Variant{};
            if (ElementOf(path, StringView(u8"effects"), index, field) && index < lamp.Effects.Size())
            {
                const Effect& effect = lamp.Effects[index];
                if (field == StringView(u8"speed") && effect.Type == 0)
                    return gui::Variant(effect.Speed);
                if (field == StringView(u8"amount") && effect.Type == 0)
                    return gui::Variant(effect.Amount);
                if (field == StringView(u8"period") && effect.Type == 1)
                    return gui::Variant(effect.Period);
            }
            return gui::Variant{};
        }
        static void Write(Lamp& lamp, StringView path, const gui::Variant& value)
        {
            if (value.IsEmpty())
                return;
            if (path == StringView(u8"name"))
                lamp.Name = String(value.AsString());
            else if (path == StringView(u8"enabled"))
                lamp.Enabled = value.AsBool();
            else if (path == StringView(u8"type"))
                lamp.Type = value.AsInt();
            else if (path == StringView(u8"intensity"))
                lamp.Intensity = value.AsFloat();
            else if (path == StringView(u8"range"))
                lamp.Range = value.AsFloat();
            else if (path == StringView(u8"cone.inner"))
                lamp.Cone[0] = value.AsFloat();
            else if (path == StringView(u8"cone.outer"))
                lamp.Cone[1] = value.AsFloat();
            else if (path == StringView(u8"shadows"))
                lamp.Shadows = value.AsInt();
            else if (path == StringView(u8"bounces"))
                lamp.Bounces = value.AsInt();
            else if (path == StringView(u8"flicker") && value.GetType() == gui::Variant::Type::Curve)
            {
                lamp.FlickerCurve.Clear();
                for (const CurveKey& key : value.AsCurve())
                    lamp.FlickerCurve.PushBack(key);
            }
            else if (path == StringView(u8"position.x"))
                lamp.Position[0] = value.AsFloat();
            else if (path == StringView(u8"position.y"))
                lamp.Position[1] = value.AsFloat();
            else if (path == StringView(u8"position.z"))
                lamp.Position[2] = value.AsFloat();
            else if (path == StringView(u8"rotation.pitch") || path == StringView(u8"rotation.yaw") || path == StringView(u8"rotation.roll"))
            {
                // One angle set, the other two kept as they read now, as the editor's Transform row does.
                Float3 euler = EulerDegrees(lamp.Rotation);
                const f32 degrees = static_cast<f32>(value.AsFloat());
                if (path == StringView(u8"rotation.pitch"))
                    euler.x = degrees;
                else if (path == StringView(u8"rotation.yaw"))
                    euler.y = degrees;
                else
                    euler.z = degrees;
                lamp.Rotation = FromYawPitchRoll(DegreesToRadians(euler.y), DegreesToRadians(euler.x), DegreesToRadians(euler.z));
            }
            else
            {
                usize index = 0;
                StringView field;
                if (ElementOf(path, StringView(u8"tags"), index, field) && index < lamp.Tags.Size() && field.Size() == 0)
                    lamp.Tags[index] = String(value.AsString());
                else if (ElementOf(path, StringView(u8"effects"), index, field) && index < lamp.Effects.Size())
                {
                    Effect& effect = lamp.Effects[index];
                    if (field == StringView(u8"speed"))
                        effect.Speed = value.AsFloat();
                    else if (field == StringView(u8"amount"))
                        effect.Amount = value.AsFloat();
                    else if (field == StringView(u8"period"))
                        effect.Period = value.AsFloat();
                }
            }
        }
        [[nodiscard]] static Float3 EulerDegrees(Quaternion q)
        {
            f32 yaw = 0.0f, pitch = 0.0f, roll = 0.0f;
            ToYawPitchRoll(q, yaw, pitch, roll);
            return Float3{RadiansToDegrees(pitch), RadiansToDegrees(yaw), RadiansToDegrees(roll)};
        }

        // The value paths under `path` in `lamp` (itself when it is one).
        void LeavesOf(const Lamp& lamp, StringView path, Array<String>& out) const
        {
            if (path == StringView(u8"tags"))
            {
                for (usize i = 0; i < lamp.Tags.Size(); ++i)
                    out.PushBack(Format(u8"tags.{}", i));
                return;
            }
            if (path == StringView(u8"effects"))
            {
                for (usize i = 0; i < lamp.Effects.Size(); ++i)
                    LeavesOf(lamp, Format(u8"effects.{}", i).AsView(), out);
                return;
            }
            if (const Optional<usize> index = EffectIndex(path); index.HasValue())
            {
                if (index.Value() >= lamp.Effects.Size())
                    return;
                if (lamp.Effects[index.Value()].Type == 0)
                {
                    out.PushBack(Format(u8"{}.speed", path));
                    out.PushBack(Format(u8"{}.amount", path));
                }
                else
                    out.PushBack(Format(u8"{}.period", path));
                return;
            }
            Array<gui::PropertyInfo> children(m_allocator);
            GetProperties(path, children);
            if (children.IsEmpty())
            {
                out.PushBack(String(path));
                return;
            }
            for (const gui::PropertyInfo& child : children)
                LeavesOf(lamp, gui::JoinPropertyPath(path, child.Name.AsView()).AsView(), out);
        }
        // `from`'s values put into `lamp` at `path` and under it; a list whole.
        void PutUnder(Lamp& lamp, const Lamp& from, StringView path) const
        {
            if (path == StringView(u8"tags"))
            {
                lamp.Tags = from.Tags;
                return;
            }
            if (path == StringView(u8"effects"))
            {
                lamp.Effects = from.Effects;
                return;
            }
            Array<String> leaves(m_allocator);
            LeavesOf(from, path, leaves);
            for (const String& leaf : leaves)
                if (leaf.AsView() != StringView(u8"id"))
                    Write(lamp, leaf.AsView(), Read(from, leaf.AsView()));
        }
        [[nodiscard]] static bool Same(const Lamp& a, const Lamp& b)
        {
            if (a.Name != b.Name || a.Enabled != b.Enabled || a.Type != b.Type || a.Intensity != b.Intensity || a.Range != b.Range ||
                a.Cone[0] != b.Cone[0] || a.Cone[1] != b.Cone[1] || a.Shadows != b.Shadows || a.Bounces != b.Bounces ||
                a.Tags.Size() != b.Tags.Size() || a.Effects.Size() != b.Effects.Size() ||
                gui::Variant::FromCurve(a.FlickerCurve.AsSpan()).Compare(gui::Variant::FromCurve(b.FlickerCurve.AsSpan())) != 0)
                return false;
            for (usize i = 0; i < 3; ++i)
                if (a.Position[i] != b.Position[i])
                    return false;
            if (a.Rotation.x != b.Rotation.x || a.Rotation.y != b.Rotation.y || a.Rotation.z != b.Rotation.z || a.Rotation.w != b.Rotation.w)
                return false;
            for (usize i = 0; i < a.Tags.Size(); ++i)
                if (a.Tags[i] != b.Tags[i])
                    return false;
            for (usize i = 0; i < a.Effects.Size(); ++i)
                if (a.Effects[i].Type != b.Effects[i].Type || a.Effects[i].Speed != b.Effects[i].Speed ||
                    a.Effects[i].Amount != b.Effects[i].Amount || a.Effects[i].Period != b.Effects[i].Period)
                    return false;
            return true;
        }

        // What a copy of `path` is, so a paste refuses another shape: a group's hint, a list's
        // name, an effect's type, else a value's kind.
        [[nodiscard]] String ShapeOf(StringView path) const
        {
            if (path == StringView(u8"position") || path == StringView(u8"rotation"))
                return String(u8"Float3");
            if (path == StringView(u8"cone"))
                return String(u8"Float2");
            if (path == StringView(u8"tags") || path == StringView(u8"effects"))
                return Format(u8"list of {}", path);
            if (const Optional<usize> index = EffectIndex(path); index.HasValue())
                return index.Value() < Lead().Effects.Size() && Lead().Effects[index.Value()].Type == 1 ? String(u8"Pulse") : String(u8"Flicker");
            switch (Read(Lead(), path).GetType())
            {
            case gui::Variant::Type::Bool:
                return String(u8"bool");
            case gui::Variant::Type::Int:
                return String(u8"integer");
            case gui::Variant::Type::Float:
                return String(u8"number");
            case gui::Variant::Type::String:
                return String(u8"text");
            case gui::Variant::Type::Curve:
                return String(u8"curve");
            default:
                return String(u8"value");
            }
        }
        // `leaf`'s path from `path` ("value" for `path` itself).
        [[nodiscard]] static String Relative(StringView path, const String& leaf)
        {
            return leaf.Size() == path.Size() ? String(u8"value") : String(leaf.AsView().SubStr(path.Size() + 1, leaf.Size() - path.Size() - 1));
        }
        // A key as the serializer takes one, null-terminated.
        [[nodiscard]] static core::FixedArray<char, 64> Key(const String& text)
        {
            core::FixedArray<char, 64> key;
            for (usize i = 0; i < text.Size() && key.Size() + 1 < key.CapacityValue(); ++i)
                key.Add(static_cast<char>(text[i]));
            key.Add('\0'); // read as a C string (items)
            return key;
        }
        // A Float2 or a Float3 either way as Core's own value (its x, y, z), its parts taken in
        // order, so one pastes onto another whatever its parts are called (a position onto a
        // rotation's Euler degrees).
        static void SerializeFloats(ISerializer& ar, Lamp& lamp, const Array<String>& leaves, bool three)
        {
            const auto part = [&](usize i) { return i < leaves.Size() ? static_cast<f32>(Read(lamp, leaves[i].AsView()).AsFloat()) : 0.0f; };
            const auto put = [&](usize i, f32 value)
            {
                if (i < leaves.Size())
                    Write(lamp, leaves[i].AsView(), gui::Variant(static_cast<f64>(value)));
            };
            if (three)
            {
                Float3 value{part(0), part(1), part(2)};
                Serialize(ar, "value", value);
                if (ar.Mode() == SerializeMode::Read)
                {
                    put(0, value.x);
                    put(1, value.y);
                    put(2, value.z);
                }
            }
            else
            {
                Float2 value{part(0), part(1)};
                Serialize(ar, "value", value);
                if (ar.Mode() == SerializeMode::Read)
                {
                    put(0, value.x);
                    put(1, value.y);
                }
            }
        }
        // One value either way, in the type it has (a read keeps the value's type).
        static void SerializeVariant(ISerializer& ar, const char* key, gui::Variant& value)
        {
            switch (value.GetType())
            {
            case gui::Variant::Type::Bool:
            {
                bool v = value.AsBool();
                Serialize(ar, key, v);
                value = gui::Variant(v);
                break;
            }
            case gui::Variant::Type::Int:
            {
                i64 v = value.AsInt();
                Serialize(ar, key, v);
                value = gui::Variant(v);
                break;
            }
            case gui::Variant::Type::Float:
            {
                f64 v = value.AsFloat();
                Serialize(ar, key, v);
                value = gui::Variant(v);
                break;
            }
            case gui::Variant::Type::String:
            {
                String v(value.AsString());
                Serialize(ar, key, v);
                value = gui::Variant(v.AsView());
                break;
            }
            case gui::Variant::Type::Curve:
            {
                // Its count, then each key's fields, under the key's own object.
                Array<CurveKey> keys;
                for (const CurveKey& k : value.AsCurve())
                    keys.PushBack(k);
                ar.Key(key);
                ar.BeginObject();
                i64 count = static_cast<i64>(keys.Size());
                Serialize(ar, "count", count);
                count = core::Clamp<i64>(count, 0, 64);
                while (static_cast<i64>(keys.Size()) < count)
                    keys.PushBack(CurveKey{});
                while (static_cast<i64>(keys.Size()) > count)
                    keys.PopBack();
                for (usize i = 0; i < keys.Size(); ++i)
                {
                    ar.Key(Key(Format(u8"k{}", i)).items);
                    ar.BeginObject();
                    Serialize(ar, "time", keys[i].time);
                    Serialize(ar, "value", keys[i].value);
                    Serialize(ar, "tangentIn", keys[i].tangentIn);
                    Serialize(ar, "tangentOut", keys[i].tangentOut);
                    i64 interpolation = static_cast<i64>(keys[i].interpolation);
                    i64 mode = static_cast<i64>(keys[i].tangentMode);
                    Serialize(ar, "interpolation", interpolation);
                    Serialize(ar, "tangentMode", mode);
                    keys[i].interpolation = static_cast<CurveKeyInterpolation>(interpolation);
                    keys[i].tangentMode = static_cast<CurveTangentMode>(mode);
                    ar.EndObject();
                }
                ar.EndObject();
                value = gui::Variant::FromCurve(keys.AsSpan());
                break;
            }
            default:
                break;
            }
        }

        // The selected lamps changed by `change`, kept as one entry of the history.
        template <typename F>
        void Change(StringView words, StringView path, F&& change)
        {
            Entry entry{String(words), Array<Lamp>(m_allocator), Array<Lamp>(m_allocator)};
            for (const Lamp& lamp : m_lamps)
                entry.Before.PushBack(lamp);
            for (const usize lamp : m_selection)
                change(m_lamps[lamp]);
            for (const Lamp& lamp : m_lamps)
                entry.After.PushBack(lamp);
            m_undo.PushBack(core::Move(entry));
            m_redo.Clear();
            Changed(path);
            if (m_onHistory)
                m_onHistory(words);
        }
        // The last entry changed nothing: it goes.
        void DropLast()
        {
            if (!m_undo.IsEmpty())
                m_undo.PopBack();
            if (m_onHistory)
                m_onHistory(StringView(u8"Nothing changed"));
        }
        // A type's change shows or hides the cone, and a list's change its rows: the properties
        // changed, not only values.
        void Changed(StringView path)
        {
            if (path == StringView(u8"type"))
                NotifyPropertiesChanged();
            else
                NotifyValuesChanged();
        }
        const Original* FindOriginal(StringView path) const
        {
            for (const Original& original : m_originals)
                if (original.Path.AsView() == path)
                    return &original;
            return nullptr;
        }
        void DropOriginal(StringView path)
        {
            for (usize i = 0; i < m_originals.Size(); ++i)
                if (m_originals[i].Path.AsView() == path)
                {
                    m_originals.RemoveAt(i);
                    return;
                }
        }
        void Step(Array<Entry>& from, Array<Entry>& to, bool undo)
        {
            if (from.IsEmpty())
                return;
            Entry entry = core::Move(from.Back());
            from.PopBack();
            const Array<Lamp>& state = undo ? entry.Before : entry.After;
            for (usize i = 0; i < kLamps && i < state.Size(); ++i)
                m_lamps[i] = state[i];
            const String words = undo ? Format(u8"Undid: {}", entry.Words) : Format(u8"Redid: {}", entry.Words);
            to.PushBack(core::Move(entry));
            NotifyPropertiesChanged();
            if (m_onHistory)
                m_onHistory(words.AsView());
        }

        IAllocator& m_allocator;
        Lamp m_lamps[kLamps];
        Lamp m_defaults[kLamps];
        Array<usize> m_selection;
        Array<Original> m_originals;
        Array<Entry> m_undo;
        Array<Entry> m_redo;
        Function<void(StringView)> m_onHistory;
    };
}
