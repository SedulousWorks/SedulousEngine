// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :style_sheet partition
//
// ResolvedStyle + StyleSheet: the cascade. Ported from eepp's css/StyleSheet(::getElement
// Styles). A StyleSheet is an ordered list of StyleRules; Resolve(element) gathers the rules
// that match, orders them by (specificity, source order), and applies their declarations so
// higher-specificity and later-source rules win - producing a flat name/value ResolvedStyle.

module;
#include "Core/Prelude.h"

export module foundation.gui:style_sheet;

import foundation.core; // String, StringView, Array, i64, Move
import :style_selector;
import :style_rule;
import :media_query;
import :ui_widget;
import :style_properties;
import :style_value; // SubstituteVariables

using namespace foundation::core;
namespace core = foundation::core;

export namespace foundation::gui
{
    /// One property of a resolved style: its text (var() substituted) and its typed value.
    struct ResolvedProperty
    {
        core::String Name;
        core::String Value;
        StyleValue Typed; ///< Kind None: not a property the table parses, or its text did not parse.
        bool Important = false;
    };

    /// The cascaded properties of one element: longhands, var() substituted and parsed.
    class ResolvedStyle
    {
    public:
        /// Sets (or overrides) `name` as written; a shorthand or a var() is settled by Finalize. An
        /// !important value resists later normal ones.
        void Set(core::StringView name, core::StringView value, bool important = false)
        {
            Put(name, value, StyleValue{}, important);
            m_finalized = false;
        }

        /// Sets a longhand already settled (its text substituted and its value parsed).
        void SetParsed(core::StringView name, core::StringView value, const StyleValue& typed, bool important)
        {
            Put(name, value, typed, important);
        }

        /// Puts `typed` in place of `name`'s value, whatever its importance: a transition's or an
        /// animation's value over the cascade's.
        void Override(core::StringView name, const StyleValue& typed)
        {
            for (ResolvedProperty& p : m_props)
            {
                if (p.Name.AsView() == name)
                {
                    p.Typed = typed;
                    return;
                }
            }
            m_props.PushBack(ResolvedProperty{core::String(name), core::String{}, typed, false});
        }

        [[nodiscard]] bool Has(core::StringView name) const { return Find(name) != nullptr; }
        void Remove(core::StringView name)
        {
            for (usize i = 0; i < m_props.Size(); ++i)
                if (m_props[i].Name.AsView() == name)
                {
                    m_props.RemoveAt(i);
                    return;
                }
        }
        /// Settles the CSS-wide keywords (E3). `inherit` takes `parent`'s value (an inherited
        /// property: what it inherits anyway); `initial` the table's initial value, or the node's
        /// own when the table gives none (kept as `initial` for an inherited property, which then
        /// stops inheriting); `unset` is `inherit` for an inherited property, `initial` otherwise.
        void SettleKeywords(const ResolvedStyle* parent)
        {
            for (usize i = 0; i < m_props.Size();)
            {
                ResolvedProperty& p = m_props[i];
                const core::StringView v = Trim(p.Value.AsView());
                const bool inherit = v == core::StringView(u8"inherit");
                const bool initial = v == core::StringView(u8"initial");
                const bool unset = v == core::StringView(u8"unset");
                if (!inherit && !initial && !unset)
                {
                    ++i;
                    continue;
                }
                const StylePropertySpec* spec = FindStyleProperty(p.Name.AsView());
                const bool inherited = spec != nullptr && spec->Inherited;
                if ((inherit || unset) && inherited)
                {
                    m_props.RemoveAt(i); // as if unset: it inherits
                    continue;
                }
                if (inherit)
                {
                    const ResolvedProperty* from = parent != nullptr ? parent->Find(p.Name.AsView()) : nullptr;
                    if (from == nullptr)
                    {
                        m_props.RemoveAt(i);
                        continue;
                    }
                    p.Value = from->Value;
                    p.Typed = from->Typed;
                    ++i;
                    continue;
                }
                // initial, or unset on a property that does not inherit.
                if (spec != nullptr && spec->Initial != nullptr)
                {
                    p.Value = core::String(spec->Initial);
                    p.Typed = ParseLonghand(p.Name.AsView(), p.Value.AsView());
                    ++i;
                }
                else if (inherited)
                {
                    p.Value = core::String(u8"initial");
                    p.Typed = StyleValue{};
                    ++i;
                }
                else
                    m_props.RemoveAt(i); // the node's own
            }
        }

        /// The text of `name`, or `fallback`.
        [[nodiscard]] core::StringView Get(core::StringView name, core::StringView fallback = core::StringView{}) const
        {
            const ResolvedProperty* p = Find(name);
            return p != nullptr ? p->Value.AsView() : fallback;
        }

        /// The typed value of `name`, or null when it is unset or did not parse.
        [[nodiscard]] const StyleValue* Value(core::StringView name) const
        {
            const ResolvedProperty* p = Find(name);
            return p != nullptr && p->Typed.Kind != StyleValueKind::None ? &p->Typed : nullptr;
        }

        [[nodiscard]] usize Count() const noexcept { return m_props.Size(); }
        [[nodiscard]] const Array<ResolvedProperty>& Properties() const noexcept { return m_props; }
        [[nodiscard]] bool IsFinalized() const noexcept { return m_finalized; }

        /// Settles what Set left as written: substitutes var() anywhere in a value (its own custom
        /// properties first, then `inherited`'s), expands shorthands into longhands in order, and
        /// parses each longhand's value. Declarations whose var() cannot resolve are dropped.
        void Finalize(const ResolvedStyle* inherited = nullptr)
        {
            Array<ResolvedProperty> written = Move(m_props);
            m_props = Array<ResolvedProperty>{};
            for (ResolvedProperty& p : written)
                if (IsCustomProperty(p.Name.AsView()))
                    Put(p.Name.AsView(), p.Value.AsView(), StyleValue{}, p.Important);
            // currentColor (E13 of Specs/gui-lab-evolution-2.md): the nearest `color` declared here
            // or above, kept as a custom property (which inherits) so every element finds it.
            for (const ResolvedProperty& p : written)
                if (p.Name.AsView() == core::StringView(u8"color"))
                    SetCurrentColor(p.Value.AsView(), inherited);
            for (const ResolvedProperty& p : written)
            {
                if (IsCustomProperty(p.Name.AsView()))
                    continue;
                core::String text;
                if (ResolveText(p.Name.AsView(), p.Value.AsView(), inherited, text))
                    SetDeclaration(p.Name.AsView(), text.AsView(), p.Important);
            }
            m_finalized = true;
        }

        /// Expands `name: text` (var() already substituted) into its longhands, parsed, and sets them.
        void SetDeclaration(core::StringView name, core::StringView text, bool important)
        {
            Array<StyleLonghand> longhands;
            if (!ExpandStyleShorthand(name, text, longhands))
                return;
            for (const StyleLonghand& longhand : longhands)
                SetParsed(longhand.Name.AsView(), longhand.Text.AsView(), ParseLonghand(longhand.Name.AsView(), longhand.Text.AsView()),
                          important);
        }

        /// A longhand's text parsed by the table's grammar for it (Kind None when the table does
        /// not name it, or it does not parse).
        [[nodiscard]] static StyleValue ParseLonghand(core::StringView name, core::StringView text)
        {
            StyleValue value;
            if (const StylePropertySpec* spec = FindStyleProperty(name))
                if (!ParseStyleValue(spec->Grammar, text, value))
                    value = StyleValue{};
            return value;
        }

        /// var() in `value` substituted from this style's custom properties, then `inherited`'s.
        [[nodiscard]] bool Substitute(core::StringView value, const ResolvedStyle* inherited, core::String& out) const
        {
            bool hasVar = false;
            for (usize i = 0; i + 3 < value.Size() && !hasVar; ++i)
                hasVar = value.SubStr(i, 4) == core::StringView(u8"var(");
            if (!hasVar)
            {
                out = core::String(value);
                return true;
            }
            const core::Function<Optional<core::String>(core::StringView)> lookup =
                [this, inherited](core::StringView name) -> Optional<core::String>
            {
                if (const ResolvedProperty* own = Find(name))
                    return core::String(own->Value);
                if (inherited != nullptr)
                    if (const ResolvedProperty* parent = inherited->Find(name))
                        return core::String(parent->Value);
                return {};
            };
            return SubstituteVariables(value, lookup, out);
        }

        /// A declaration's text as it applies here: var() substituted, then currentColor (the
        /// nearest declared colour; for `color` itself, the parent's). False when either cannot.
        [[nodiscard]] bool ResolveText(core::StringView name, core::StringView value, const ResolvedStyle* inherited, core::String& out) const
        {
            core::String text;
            if (!Substitute(value, inherited, text))
                return false;
            if (!HasCurrentColor(text.AsView()))
            {
                out = Move(text);
                return true;
            }
            return ReplaceCurrentColor(text.AsView(), name == core::StringView(u8"color") ? inherited : this, out);
        }
        /// Records the colour currentColor reads here: `color`'s winning text among `declarations`
        /// (name, value, important, in cascade order), resolved; none declared: the parent's stays.
        void SetCurrentColor(core::StringView colorText, const ResolvedStyle* inherited)
        {
            core::String resolved;
            if (ResolveText(core::StringView(u8"color"), colorText, inherited, resolved))
                Put(kCurrentColorProperty, resolved.AsView(), StyleValue{}, false);
        }
        [[nodiscard]] static bool HasCurrentColor(core::StringView value)
        {
            core::String ignored;
            return !ReplaceCurrentColor(value, nullptr, ignored);
        }

        /// Where currentColor reads the nearest declared `color` (a custom property: it inherits).
        static constexpr const char8_t* kCurrentColorProperty = u8"--gui-current-color";

        /// `value` with each currentColor (in any case) replaced by `from`'s nearest declared colour;
        /// false when it has one and no colour was declared.
        [[nodiscard]] static bool ReplaceCurrentColor(core::StringView value, const ResolvedStyle* from, core::String& out)
        {
            static constexpr core::StringView kWord(u8"currentcolor");
            const auto at = [&](usize i)
            {
                if (i + kWord.Size() > value.Size())
                    return false;
                for (usize k = 0; k < kWord.Size(); ++k)
                {
                    char8_t c = value[i + k];
                    if (c >= u8'A' && c <= u8'Z')
                        c = static_cast<char8_t>(c - u8'A' + u8'a');
                    if (c != kWord[k])
                        return false;
                }
                return true;
            };
            out = core::String{};
            for (usize i = 0; i < value.Size();)
            {
                if (at(i))
                {
                    const ResolvedProperty* color = from != nullptr ? from->Find(core::StringView(kCurrentColorProperty)) : nullptr;
                    if (color == nullptr)
                        return false;
                    out.Append(color->Value.AsView());
                    i += kWord.Size();
                    continue;
                }
                out.PushBack(value[i++]);
            }
            return true;
        }

        /// This style's custom properties and `parent`'s it does not set (custom properties inherit).
        void InheritCustomProperties(const ResolvedStyle& parent)
        {
            for (const ResolvedProperty& p : parent.m_props)
                if (IsCustomProperty(p.Name.AsView()) && Find(p.Name.AsView()) == nullptr)
                    m_props.PushBack(p);
        }

        [[nodiscard]] static bool IsCustomProperty(core::StringView name) noexcept
        {
            return name.Size() >= 2 && name[0] == u8'-' && name[1] == u8'-';
        }

    private:
        [[nodiscard]] const ResolvedProperty* Find(core::StringView name) const
        {
            for (const ResolvedProperty& p : m_props)
                if (p.Name.AsView() == name)
                    return &p;
            return nullptr;
        }

        void Put(core::StringView name, core::StringView value, const StyleValue& typed, bool important)
        {
            for (ResolvedProperty& p : m_props)
            {
                if (p.Name.AsView() != name)
                    continue;
                if (p.Important && !important)
                    return; // important wins over normal
                p.Value = core::String(value);
                p.Typed = typed;
                p.Important = important;
                return;
            }
            m_props.PushBack(ResolvedProperty{core::String(name), core::String(value), typed, important});
        }

        Array<ResolvedProperty> m_props;
        bool m_finalized = true; // an empty style is settled
    };

    // One @keyframes stop: an offset in [0,1] (0% .. 100%, from/to) + its declarations.
    struct KeyframeStop
    {
        f32 Offset = 0.0f;
        Array<StyleProperty> Properties;
    };

    // An @font-face rule (E11 of Specs/gui-lab-evolution-2.md): a face of a family, and the file
    // it is in, which the host loads (StyleManager::SetFontFaceLoader).
    struct FontFaceRule
    {
        core::String Family;
        core::String Source; ///< its src, url() and quotes taken off
        u16 Weight = 400;
        bool Italic = false;
    };

    // An @spritesheet (RmlUi's, E13 of Specs/gui-lab-evolution-2.md): one image's named regions, which
    // a sheet names as images (`url(button-normal)`); the style manager writes each such url as the
    // image and its region (`url(atlas.png#xywh=0,0,64,32)`).
    struct Sprite
    {
        core::String Name;
        f32 X = 0.0f, Y = 0.0f, Width = 0.0f, Height = 0.0f;
    };
    struct Spritesheet
    {
        core::String Name;
        core::String Source; ///< its image's path
        Array<Sprite> Sprites;
    };

    // A named @keyframes animation: an ordered list of stops.
    struct Keyframes
    {
        core::String Name;
        Array<KeyframeStop> Stops;
    };

    class StyleSheet;

    /// A rule that matched an element, with what orders it in the cascade.
    struct StyleRuleMatch
    {
        const StyleRule* Rule = nullptr;
        u32 Origin = 0;     ///< the sheet's place among the origins (user agent, the GUI's, a subtree's)
        i64 Specificity = 0;
        u32 Order = 0;      ///< its place in its sheet
    };

    /// One declaration that set a longhand (E8d): from a rule (with its origin), or the inline
    /// style (Rule null).
    struct DeclarationTrace
    {
        const StyleRule* Rule = nullptr;
        u32 Origin = 0;
        core::String Value; ///< as written (a var() not substituted)
        bool Important = false;
    };
    /// A longhand an element's cascade set, with every declaration that set it, the winner first.
    struct LonghandTrace
    {
        core::String Name;
        Array<DeclarationTrace> Declarations;
    };

    class StyleSheet
    {
    public:
        /// What it is called where it came from (a path, "theme"); empty when it was not named.
        void SetName(core::StringView name) { m_name = core::String(name); }
        [[nodiscard]] core::StringView Name() const noexcept { return m_name.AsView(); }

        void AddRule(StyleRule rule)
        {
            m_rules.PushBack(core::Move(rule));
            m_index.Built = false;
        }
        [[nodiscard]] usize RuleCount() const noexcept { return m_rules.Size(); }
        [[nodiscard]] const Array<StyleRule>& Rules() const noexcept { return m_rules; }
        /// `rule` as one to change, when it is this sheet's (null when it is not).
        [[nodiscard]] StyleRule* MutableRule(const StyleRule* rule) noexcept
        {
            for (StyleRule& r : m_rules)
                if (&r == rule)
                    return &r;
            return nullptr;
        }

        void AddKeyframes(Keyframes keyframes) { m_keyframes.PushBack(core::Move(keyframes)); }
        void AddFontFace(FontFaceRule face) { m_fontFaces.PushBack(core::Move(face)); }
        /// The paths it @imports, in order (E13): the style manager loads and expands them.
        void AddImport(core::StringView path) { m_imports.PushBack(core::String(path)); }
        void AddSpritesheet(Spritesheet sheet) { m_spritesheets.PushBack(core::Move(sheet)); }
        [[nodiscard]] const Array<Spritesheet>& Spritesheets() const noexcept { return m_spritesheets; }
        /// Every rule's value naming one of `sprites` as an image (url(name)) written as its
        /// spritesheet's image and region instead.
        void ResolveSprites(Span<const Spritesheet> sheets)
        {
            for (StyleRule& rule : m_rules)
                for (const StyleProperty& p : rule.Properties())
                {
                    core::StringView value = p.Value.AsView();
                    bool hasUrl = false;
                    for (usize i = 0; i + 4 <= value.Size() && !hasUrl; ++i)
                        hasUrl = value.SubStr(i, 4) == core::StringView(u8"url(");
                    if (!hasUrl)
                        continue;
                    core::String out;
                    bool changed = false;
                    for (usize i = 0; i < value.Size();)
                    {
                        if (i + 4 > value.Size() || value.SubStr(i, 4) != core::StringView(u8"url("))
                        {
                            out.PushBack(value[i++]);
                            continue;
                        }
                        usize close = i + 4;
                        while (close < value.Size() && value[close] != u8')')
                            ++close;
                        core::StringView name = Trim(value.SubStr(i + 4, close - i - 4));
                        if (name.Size() >= 2 && (name[0] == u8'"' || name[0] == u8'\'') && name[name.Size() - 1] == name[0])
                            name = name.SubStr(1, name.Size() - 2);
                        const Sprite* found = nullptr;
                        const Spritesheet* in = nullptr;
                        for (const Spritesheet& sheet : sheets)
                            for (const Sprite& sprite : sheet.Sprites)
                                if (found == nullptr && sprite.Name.AsView() == name)
                                {
                                    found = &sprite;
                                    in = &sheet;
                                }
                        if (found == nullptr)
                        {
                            out.Append(value.SubStr(i, close - i));
                            i = close;
                            continue;
                        }
                        out.Append(core::StringView(u8"url("));
                        out.Append(in->Source.AsView());
                        out.Append(core::Format(u8"#xywh={},{},{},{}", found->X, found->Y, found->Width, found->Height).AsView());
                        i = close;
                        changed = true;
                    }
                    if (changed)
                        rule.SetProperty(p.Name.AsView(), out.AsView(), p.Important);
                }
            m_index.Built = false;
        }
        [[nodiscard]] const Array<core::String>& Imports() const noexcept { return m_imports; }
        /// Puts `imported`'s rules before its own (an import comes first in source order, so this
        /// sheet's own win a tie), and takes its keyframes and font faces after its own.
        void PrependImported(StyleSheet imported)
        {
            for (StyleRule& rule : m_rules)
                imported.m_rules.PushBack(core::Move(rule));
            m_rules = core::Move(imported.m_rules);
            for (Keyframes& k : imported.m_keyframes)
                m_keyframes.PushBack(core::Move(k));
            for (FontFaceRule& f : imported.m_fontFaces)
                m_fontFaces.PushBack(core::Move(f));
            for (Spritesheet& s : imported.m_spritesheets)
                m_spritesheets.PushBack(core::Move(s));
            m_index.Built = false;
        }
        [[nodiscard]] const Array<FontFaceRule>& FontFaces() const noexcept { return m_fontFaces; }
        [[nodiscard]] usize KeyframesCount() const noexcept { return m_keyframes.Size(); }
        [[nodiscard]] const Array<Keyframes>& AllKeyframes() const noexcept { return m_keyframes; }
        [[nodiscard]] const Keyframes* FindKeyframes(core::StringView name) const
        {
            for (const Keyframes& k : m_keyframes)
                if (k.Name.AsView() == name)
                    return &k;
            return nullptr;
        }

        /// The rules of this sheet that match `element` (its own style with `pseudoElement` empty,
        /// else that part's, from rules written `tag::part`) under `context`, added to `out` at
        /// `origin` (a later origin wins over an earlier one at any specificity).
        /// A part's rules that ask for its states (`::thumb:hover`) match when `partStates` has them.
        /// `ancestors`, when given, holds the names of every widget above `element`.
        void CollectMatches(const UIWidget& element, const MediaContext& context, bool applyPseudo,
                            core::StringView pseudoElement, u32 origin, Array<StyleRuleMatch>& out, u32 partStates = 0,
                            const AncestorFilter* ancestors = nullptr) const
        {
            // Only the rules whose subject could match: those keyed by the element's id, one of
            // its classes or its tag, and those with no key (the order is the cascade's to set).
            const RuleIndex& index = Index();
            const auto tryRules = [&](const Array<u32>& candidates)
            {
                for (const u32 i : candidates)
                {
                    const StyleRule& rule = m_rules[i];
                    if (rule.Selector().PseudoElement() != pseudoElement)
                        continue;
                    if (applyPseudo && (rule.Selector().PartPseudoClasses() & ~partStates) != 0)
                        continue;
                    if (ancestors != nullptr && !ancestors->MayMatch(rule.Selector()))
                        continue;
                    const bool mediaActive = rule.Media().IsEmpty() || rule.Media().Evaluate(context);
                    if (mediaActive && rule.Selector().Select(element, applyPseudo))
                        out.PushBack(StyleRuleMatch{&rule, origin, rule.Specificity(), i});
                }
            };
            const auto tryKey = [&](const HashMap<u64, Array<u32>>& map, core::StringView key)
            {
                if (key.Size() != 0)
                    if (const Array<u32>* candidates = map.Find(HashText(key)))
                        tryRules(*candidates);
            };
            tryKey(index.ById, element.GetId());
            for (const core::String& cls : element.Classes())
                tryKey(index.ByClass, cls.AsView());
            tryKey(index.ByTag, element.GetTag());
            tryRules(index.Universal);
        }

        // Resolve the cascade for `element` against this sheet alone. With `pseudoElement` empty
        // this is the element's own style (rules with no ::part); pass a part name (e.g. "thumb")
        // to resolve the cascade for that widget part (rules written as `tag::part { ... }`).
        /// `inherited` (the parent's resolved style) gives the custom properties this element
        /// does not set.
        [[nodiscard]] ResolvedStyle Resolve(const UIWidget& element,
                                            const MediaContext& context = {},
                                            bool applyPseudo = true,
                                            core::StringView pseudoElement = {},
                                            const ResolvedStyle* inherited = nullptr) const
        {
            Array<StyleRuleMatch> matches;
            CollectMatches(element, context, applyPseudo, pseudoElement, 0, matches);
            return Cascade(matches, inherited, {});
        }

        /// The cascade of `matches` (from any sheets): ordered by origin, then specificity, then
        /// source order, applied low to high so the later wins (!important resists a later normal
        /// value); then `inlineStyle` (markup's attributes, a script's style), the highest origin.
        /// Custom properties first (this element's, then those it inherits from `inherited`), so a
        /// var() anywhere resolves against the whole cascade; then each declaration as its
        /// longhands, parsed: once per declaration when it has no var() (its value cannot change),
        /// else each time.
        [[nodiscard]] static ResolvedStyle Cascade(Array<StyleRuleMatch>& matches, const ResolvedStyle* inherited,
                                                   Span<const InlineStyleDeclaration> inlineStyle)
        {
            SortMatches(matches);
            ResolvedStyle out;
            for (const StyleRuleMatch& m : matches)
                for (const StyleProperty& p : m.Rule->Properties())
                    if (ResolvedStyle::IsCustomProperty(p.Name.AsView()))
                        out.SetParsed(p.Name.AsView(), p.Value.AsView(), StyleValue{}, p.Important);
            for (const InlineStyleDeclaration& d : inlineStyle)
                if (ResolvedStyle::IsCustomProperty(d.Name.AsView()))
                    out.SetParsed(d.Name.AsView(), d.Value.AsView(), StyleValue{}, false);
            if (inherited != nullptr)
                out.InheritCustomProperties(*inherited);
            // currentColor's colour (E13): the winning `color` here, before anything reads it.
            {
                const StyleProperty* winner = nullptr;
                core::StringView inlineColor;
                for (const StyleRuleMatch& m : matches)
                    for (const StyleProperty& p : m.Rule->Properties())
                        if (p.Name.AsView() == core::StringView(u8"color") && (winner == nullptr || p.Important || !winner->Important))
                            winner = &p;
                for (const InlineStyleDeclaration& d : inlineStyle)
                    if (d.Name.AsView() == core::StringView(u8"color") && (winner == nullptr || !winner->Important))
                        inlineColor = d.Value.AsView();
                if (inlineColor.Size() != 0)
                    out.SetCurrentColor(inlineColor, inherited);
                else if (winner != nullptr)
                    out.SetCurrentColor(winner->Value.AsView(), inherited);
            }
            for (const StyleRuleMatch& m : matches)
            {
                for (const StyleProperty& p : m.Rule->Properties())
                {
                    if (ResolvedStyle::IsCustomProperty(p.Name.AsView()))
                        continue;
                    if (!p.Cached)
                        Cache(p);
                    if (p.CacheValid)
                    {
                        for (const StyleLonghandValue& longhand : p.Longhands)
                            out.SetParsed(longhand.Name.AsView(), longhand.Text.AsView(), longhand.Value, p.Important);
                        continue;
                    }
                    core::String text;
                    if (out.ResolveText(p.Name.AsView(), p.Value.AsView(), inherited, text))
                        out.SetDeclaration(p.Name.AsView(), text.AsView(), p.Important);
                }
            }
            for (const InlineStyleDeclaration& d : inlineStyle)
            {
                if (ResolvedStyle::IsCustomProperty(d.Name.AsView()))
                    continue;
                core::String text;
                if (out.ResolveText(d.Name.AsView(), d.Value.AsView(), inherited, text))
                    out.SetDeclaration(d.Name.AsView(), text.AsView(), false);
            }
            return out;
        }

        /// Where each longhand of `matches` and `inlineStyle` came from, as Cascade applies them:
        /// ordered by origin, specificity and source, then the inline style; for each longhand
        /// every declaration that set it, the winner first (the last !important one, else the
        /// last), the rest by precedence. For the inspector, not the frame.
        [[nodiscard]] static Array<LonghandTrace> Trace(Array<StyleRuleMatch>& matches, Span<const InlineStyleDeclaration> inlineStyle)
        {
            SortMatches(matches);
            struct Applied
            {
                usize Longhand;
                DeclarationTrace Declaration;
            };
            Array<LonghandTrace> out;
            Array<Applied> applied; // in the order the cascade applies them
            const auto add = [&](core::StringView name, const DeclarationTrace& d)
            {
                usize at = out.Size();
                for (usize i = 0; i < out.Size(); ++i)
                    if (out[i].Name.AsView() == name)
                        at = i;
                if (at == out.Size())
                    out.PushBack(LonghandTrace{core::String(name), {}});
                applied.PushBack(Applied{at, d});
            };
            const auto declare = [&](core::StringView name, core::StringView value, const DeclarationTrace& d)
            {
                if (ResolvedStyle::IsCustomProperty(name))
                {
                    add(name, d);
                    return;
                }
                Array<StyleLonghand> longhands;
                if (ExpandStyleShorthand(name, value, longhands))
                    for (const StyleLonghand& l : longhands)
                        add(l.Name.AsView(), DeclarationTrace{d.Rule, d.Origin, l.Text, d.Important});
            };
            for (const StyleRuleMatch& m : matches)
                for (const StyleProperty& p : m.Rule->Properties())
                    declare(p.Name.AsView(), p.Value.AsView(), DeclarationTrace{m.Rule, m.Origin, p.Value, p.Important});
            for (const InlineStyleDeclaration& d : inlineStyle)
                declare(d.Name.AsView(), d.Value.AsView(), DeclarationTrace{nullptr, 0, d.Value, false});
            // Precedence: an important one over every normal one, then the later over the earlier.
            for (usize i = applied.Size(); i-- > 0;)
                if (applied[i].Declaration.Important)
                    out[applied[i].Longhand].Declarations.PushBack(applied[i].Declaration);
            for (usize i = applied.Size(); i-- > 0;)
                if (!applied[i].Declaration.Important)
                    out[applied[i].Longhand].Declarations.PushBack(applied[i].Declaration);
            return out;
        }

    private:
        // Stable insertion sort (ties keep their order: sheet, then source).
        static void SortMatches(Array<StyleRuleMatch>& matches)
        {
            for (usize a = 1; a < matches.Size(); ++a)
            {
                const StyleRuleMatch key = matches[a];
                usize b = a;
                while (b > 0 && Before(key, matches[b - 1]))
                {
                    matches[b] = matches[b - 1];
                    --b;
                }
                matches[b] = key;
            }
        }

        [[nodiscard]] static bool Before(const StyleRuleMatch& a, const StyleRuleMatch& b) noexcept
        {
            if (a.Origin != b.Origin)
                return a.Origin < b.Origin;
            if (a.Specificity != b.Specificity)
                return a.Specificity < b.Specificity;
            return a.Order < b.Order;
        }

        // A declaration without var() expands and parses once: its longhands cached on it.
        static void Cache(const StyleProperty& p)
        {
            p.Cached = true;
            for (usize i = 0; i + 3 < p.Value.Size(); ++i)
                if (p.Value.AsView().SubStr(i, 4) == core::StringView(u8"var("))
                    return; // re-substituted each cascade
            if (ResolvedStyle::HasCurrentColor(p.Value.AsView()))
                return; // its colour is each element's
            Array<StyleLonghand> longhands;
            if (!ExpandStyleShorthand(p.Name.AsView(), p.Value.AsView(), longhands))
            {
                p.CacheValid = true; // a shorthand that does not parse sets nothing, every time
                return;
            }
            for (const StyleLonghand& longhand : longhands)
                p.Longhands.PushBack(StyleLonghandValue{longhand.Name, longhand.Text,
                                                        ResolvedStyle::ParseLonghand(longhand.Name.AsView(), longhand.Text.AsView())});
            p.CacheValid = true;
        }

        // The rules by their subject compound's key (E8 of Specs/gui-lab-evolution.md), as
        // browsers and RmlUi keep them: its id, else its first class, else its tag; a subject with
        // none is tried on every element. An element tries only the lists its id, classes and tag
        // name, so a sheet of many rules costs what could match. Keys are hashes of the names: a
        // collision only adds candidates, which the full match then turns away.
        struct RuleIndex
        {
            HashMap<u64, Array<u32>> ById;
            HashMap<u64, Array<u32>> ByClass;
            HashMap<u64, Array<u32>> ByTag;
            Array<u32> Universal;
            bool Built = false;
        };
        [[nodiscard]] const RuleIndex& Index() const
        {
            if (m_index.Built)
                return m_index;
            m_index = RuleIndex{};
            for (usize i = 0; i < m_rules.Size(); ++i)
            {
                const StyleSelector& selector = m_rules[i].Selector();
                if (selector.IsEmpty())
                    continue;
                const StyleSelectorRule& subject = selector.RuleAt(selector.RuleCount() - 1);
                if (subject.IsNever())
                    continue; // matches nothing
                const u32 at = static_cast<u32>(i);
                const auto add = [at](HashMap<u64, Array<u32>>& map, core::StringView key)
                {
                    if (Array<u32>* list = map.Find(HashText(key)))
                        list->PushBack(at);
                    else
                    {
                        Array<u32> list1;
                        list1.PushBack(at);
                        map.InsertOrAssign(HashText(key), core::Move(list1));
                    }
                };
                if (subject.GetId().Size() != 0)
                    add(m_index.ById, subject.GetId());
                else if (!subject.GetClasses().IsEmpty())
                    add(m_index.ByClass, subject.GetClasses()[0].AsView());
                else if (subject.GetTag().Size() != 0)
                    add(m_index.ByTag, subject.GetTag());
                else
                    m_index.Universal.PushBack(at);
            }
            m_index.Built = true;
            return m_index;
        }

        Array<StyleRule> m_rules;
        Array<Keyframes> m_keyframes;
        Array<FontFaceRule> m_fontFaces;
        Array<core::String> m_imports;
        Array<Spritesheet> m_spritesheets;
        mutable RuleIndex m_index;
        core::String m_name;
    };
}
