// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :scene_root partition
//
// GUIContext: one GUI, of any number of roots (windows, render targets, a panel in the world). It
// holds what is the GUI's rather than a window's: the animation clock (roots may pause or slow
// their own time on it), deferred tree edits, the bindings' scheduler (one flush a frame for every
// root, so a binding in one root reading a value another wrote runs once, in order), the named
// data, the commands and the keymap, the element table weak handles resolve through (so a handle
// survives its node moving between roots) and the element set. It tracks the active root, the one
// last given input: keystrokes, the gamepad and command availability follow its focus path. Every
// root is made in a context (a GUI of one root is a context with one); the host advances the GUI
// once a frame through GUIContext::Update.
//
// SceneRoot: the root of one GUI's widget tree AND its coordinator (eepp's Scene::SceneNode, by
// role). A Node subclass that sits at the top; it owns the event dispatcher and its display
// scale, and reaches its GUIContext's ActionManager, MutationQueue, element table and set.
// GUIContext::Update ticks running actions, then drains deferred tree edits. Drawing is
// inherited from Node::Draw, with the top layer drawn after the tree (DrawFrame).
//
// Each root is scaled on its own (one per window, or per render target: a panel in the world, a
// texture): its tree lays out in logical units, which its display scale (the window's content
// scale times a UI scale) maps to device pixels, through the root's own transform, so drawing and
// hit testing agree and two windows on monitors of different density each keep their own.
//
// Nodes reach the coordinator through Node's virtual GetActionManager()/GetMutationQueue(),
// which walk up the parent chain; SceneRoot overrides them to return its own.

module;
#include "Core/Prelude.h"
#include "Core/Reflection/Reflect.h"
#include "Profiler/Profiler.h" // PROFILE_SCOPE

export module foundation.gui:scene_root;

import foundation.core; // Duration, Stopwatch
import foundation.profiler;
import foundation.vg; // VGBatch (what a frame drew)
import :node;
import :frame_stats;
import :draw_context;
import :element_types;
import :action_manager;
import :mutation_queue;
import :event_dispatcher;
import :media_query; // MediaContext
import :reactive;    // EffectScheduler
import :data_model;
import :commands;
import :keymap;
import foundation.fonts;   // IFontService
import foundation.i18n;    // Localization (E9a)
import :resource_provider; // IResourceProvider
import :picture_baker;     // IPictureBaker
import :text_editing_keys; // the editing keys every GUI starts with (E4)
import :accessibility;     // the accessibility tree's model and the host's bridge (E9d)

using namespace foundation::core;
namespace core = foundation::core;
namespace fonts = foundation::fonts;

export namespace foundation::gui
{
    class SceneRoot;

    class GUIContext : public RefCounted
    {
    public:
        // MemoryAllocator is valid in a constructor (MakeRef sets it first).
        GUIContext()
            : m_elements(core::MakeRef<ElementTable>(MemoryAllocator())), m_data(core::MakeRef<DataModel>(MemoryAllocator()))
        {
            BindTextEditingKeys(m_keymap); // a GUI's own bindings come later, so they win a tie
            (void)m_keymap.Bind(core::StringView(u8"f10"), core::StringView(u8"menu.enter-bar"));
            (void)m_keymap.Bind(core::StringView(u8"shift-f10"), core::StringView(u8"menu.context"));
            // A menu's moves (E12), bindings in its key context.
            (void)m_keymap.Bind(core::StringView(u8"up"), core::StringView(kMenuUpCommand), core::StringView(kMenuKeyContext));
            (void)m_keymap.Bind(core::StringView(u8"down"), core::StringView(kMenuDownCommand), core::StringView(kMenuKeyContext));
            (void)m_keymap.Bind(core::StringView(u8"left"), core::StringView(kMenuLeftCommand), core::StringView(kMenuKeyContext));
            (void)m_keymap.Bind(core::StringView(u8"right"), core::StringView(kMenuRightCommand), core::StringView(kMenuKeyContext));
            // A drag from the keys and the pad (E7): picked up at the focus, dropped with Return
            // or South (the dispatcher's while it drags).
            (void)m_keymap.Bind(core::StringView(u8"ctrl-shift-d"), core::StringView(u8"drag.pick"));
            (void)m_keymap.Bind(core::StringView(u8"pad-north"), core::StringView(u8"drag.pick"));
            // Back (K1): one command for the keyboard and the pad, which a game rebinds like any.
            (void)m_keymap.Bind(core::StringView(u8"escape"), core::StringView(kBackCommand));
            (void)m_keymap.Bind(core::StringView(u8"pad-east"), core::StringView(kBackCommand));
        }
        GUIContext(const GUIContext&) = delete;
        GUIContext& operator=(const GUIContext&) = delete;
        ~GUIContext() override
        {
            SetLocalization(nullptr);
            m_elements->Close();
        }

        /// Advances every root by `elapsed`, once a frame: the clock (each root's actions at its own
        /// time scale), each root's input repeat and per-frame hook, the bindings whose values
        /// changed, the deferred tree edits, then each root's layout.
        void Update(core::Duration elapsed);

        [[nodiscard]] ActionManager& GetActionManager() noexcept { return m_actionManager; }
        [[nodiscard]] MutationQueue& GetMutationQueue() noexcept { return m_mutationQueue; }
        [[nodiscard]] EffectScheduler& GetEffectScheduler() noexcept { return m_effects; }
        /// The GUI's named values, which markup and scripts bind to.
        [[nodiscard]] DataModel& GetData() noexcept { return *m_data; }
        /// Moves data value `name` to `to` over `seconds` on the GUI's clock (K3), eased as `easing`
        /// names: whatever is bound to it follows each frame (a score counting up with no widget to
        /// drive it), in the value's own type (a whole number counts in whole numbers). A tween of
        /// the same name replaces the running one, from the value showing; a GUI root's pause does not
        /// hold it. The tween, to shape further. Defined in Styling/TweenImpl.cpp.
        RefPtr<Tween> AnimateData(core::StringView name, f64 to, f32 seconds, core::StringView easing = core::StringView(u8"ease"));
        /// A data value's tween as AnimateData makes one, not yet running: a step for a group.
        RefPtr<Tween> CreateDataTween(core::StringView name, f64 to, f32 seconds, core::StringView easing = core::StringView(u8"ease"));
        [[nodiscard]] const RefPtr<DataModel>& GetDataRef() const noexcept { return m_data; }
        [[nodiscard]] CommandSet& GetCommands() noexcept { return m_commands; }
        Command& DefineCommand(core::StringView id) { return m_commands.Define(id, MemoryAllocator()); }
        [[nodiscard]] Keymap& GetKeymap() noexcept { return m_keymap; }
        /// Where its roots are on the screen, the host's (one that places its windows, D6): a drag goes
        /// on from root to root, and one let go over none ends outside. Not owned; null: each root
        /// alone.
        void SetRootPlaces(IRootPlaces* places);
        [[nodiscard]] IRootPlaces* GetRootPlaces() const noexcept { return m_rootPlaces; }
        /// The fonts and resources its text asks for (a rich text's own faces and its icons); not owned.
        void SetFontService(fonts::IFontService* fonts) noexcept { m_fontService = fonts; }
        /// What the host knows of the user's preferences (its platform's dark mode, contrast and
        /// reduced-motion settings, E13): sheets read them as prefers-color-scheme,
        /// prefers-contrast and prefers-reduced-motion. A change restyles at the next frame.
        void SetColorScheme(bool dark) noexcept { m_darkScheme = dark; }
        [[nodiscard]] bool IsDarkScheme() const noexcept { return m_darkScheme; }
        void SetContrastPreference(ContrastPreference contrast) noexcept { m_contrast = contrast; }
        [[nodiscard]] ContrastPreference GetContrastPreference() const noexcept { return m_contrast; }
        void SetReducedMotion(bool reduce) noexcept { m_reducedMotion = reduce; }
        /// The most the GUI's clock moves in one update, in seconds (K5; 0, the default: no limit).
        /// A game sets it so a hitch (a level loading under a menu) does not skip a screen's
        /// entrance or exit: its motion runs slower for that frame rather than jumping to its end.
        void SetMaxClockStep(f32 seconds) noexcept { m_maxClockStep = core::Max(0.0f, seconds); }
        [[nodiscard]] f32 GetMaxClockStep() const noexcept { return m_maxClockStep; }
        [[nodiscard]] bool IsReducedMotion() const noexcept { return m_reducedMotion; }
        [[nodiscard]] fonts::IFontService* GetFontService() const noexcept { return m_fontService; }
        void SetResourceProvider(IResourceProvider* resources) noexcept { m_resources = resources; }
        /// The host's picture baker (its renderer's): an SVG skin drawn from a texture baked at the
        /// size it shows, not as paths every frame. None: paths. Not owned.
        void SetPictureBaker(IPictureBaker* baker) noexcept { m_baker = baker; }
        [[nodiscard]] IPictureBaker* GetPictureBaker() const noexcept { return m_baker; }
        /// The texts its translated properties resolve through (E9a), the host's; not owned. Its
        /// changes (a language, a table, pseudolocalization) re-resolve every translated property
        /// and restyle the roots (`:lang`). Null: a translated property shows its key.
        void SetLocalization(foundation::i18n::Localization* localization)
        {
            if (localization == m_localization)
                return;
            if (m_localization != nullptr)
                m_localization->RemoveOnChanged(m_localizationToken);
            m_localization = localization;
            m_localizationToken = 0;
            if (m_localization != nullptr)
                m_localizationToken = m_localization->OnChanged([this]() { LanguageChanged(); });
            LanguageChanged();
        }
        [[nodiscard]] foundation::i18n::Localization* GetLocalization() const noexcept { return m_localization; }
        /// Read by what follows the language (a translated property's binding): it reruns when it
        /// changes.
        void TrackLanguage() const { m_languageChanged.Track(); }

        /// A service a library finds through the GUI, by its key (K6: the gamekit's InputPrompts,
        /// which the host gives): borrowed, the host's to keep alive while set; null clears it.
        /// What reads one follows it: a binding that read it runs again when it is set.
        void SetService(core::StringView key, void* service)
        {
            for (usize i = 0; i < m_services.Size(); ++i)
                if (m_services[i].Key.AsView() == key)
                {
                    if (service == nullptr)
                        m_services.RemoveAt(i);
                    else
                        m_services[i].Service = service;
                    m_servicesChanged.Notify();
                    return;
                }
            if (service != nullptr)
                m_services.PushBack(ServiceEntry{core::String(key), service});
            m_servicesChanged.Notify();
        }
        /// The service under `key`, or null; a read a binding follows.
        [[nodiscard]] void* GetService(core::StringView key) const
        {
            m_servicesChanged.Track();
            for (const ServiceEntry& entry : m_services)
                if (entry.Key.AsView() == key)
                    return entry.Service;
            return nullptr;
        }
        [[nodiscard]] IResourceProvider* GetResourceProvider() const noexcept { return m_resources; }
        [[nodiscard]] ElementTable* GetElementTable() noexcept { return m_elements.Get(); }
        [[nodiscard]] const ElementSet& GetElementSet() const noexcept { return m_elementSet; }
        /// What this GUI's markup and scripts may create (every registered element by default).
        void SetElementSet(ElementSet set) { m_elementSet = core::Move(set); }

        // === Roots ===
        [[nodiscard]] usize RootCount() const noexcept { return m_roots.Size(); }
        [[nodiscard]] SceneRoot* GetRootAt(usize index) const noexcept { return index < m_roots.Size() ? m_roots[index] : nullptr; }
        /// The root last given input (keys, the gamepad, a press), or the first: where keystrokes,
        /// the gamepad and command availability go. A host or a script may set it.
        [[nodiscard]] SceneRoot* GetActiveRoot() const noexcept
        {
            return m_active != nullptr ? m_active : (m_roots.IsEmpty() ? nullptr : m_roots[0]);
        }
        /// `root` took input from the user: it becomes the active root, and the other roots' light
        /// popups (auto ones and tooltips) close, as a press outside them would (E5).
        void TookInput(SceneRoot& root);
        void SetActiveRoot(SceneRoot* root)
        {
            if (root == m_active)
                return;
            m_active = root;
            m_activeChanged.Notify();
        }

        // === Commands across roots ===
        /// Runs command `id` along the active root's focus path.
        bool RunCommand(core::StringView id);
        /// Whether command `id` is available on the active root's focus path (a read a binding
        /// follows: the active root, its focus, the command, the handlers).
        [[nodiscard]] bool IsCommandAvailable(core::StringView id);

        /// How many bindings the last Update ran.
        [[nodiscard]] u32 LastBindingCount() const noexcept { return m_lastBindingCount; }

        // === Accessibility (E9d) ===
        /// The host's bridge to a screen reader (not owned; null: none). While it listens, each
        /// Update sends every root's nodes that changed (all of them the first time) and the focus.
        void SetAccessibilityBridge(IAccessibilityBridge* bridge) noexcept
        {
            m_accessBridge = bridge;
            m_accessListening = false; // a new listener starts from the whole tree
        }
        [[nodiscard]] IAccessibilityBridge* GetAccessibilityBridge() const noexcept { return m_accessBridge; }
        /// Speaks `text` through the bridge (a score, a level loaded: news no node holds).
        void Announce(core::StringView text, AnnouncePriority priority = AnnouncePriority::Polite)
        {
            if (m_accessBridge != nullptr && m_accessBridge->IsListening())
                m_accessBridge->Announce(text, priority);
        }
        /// Asks for an action a platform sends (from any thread); it runs in the next Update, on
        /// the GUI's thread, through the paths input takes.
        void RequestAccessAction(const AccessActionRequest& request)
        {
            m_accessLock.Lock();
            m_accessRequests.PushBack(request);
            m_accessLock.Unlock();
        }
        /// Runs an action now; false when its node is gone or does not take it. AccessibilityImpl.cpp.
        bool RunAccessAction(const AccessActionRequest& request);
        /// `root`'s whole tree as it is now, listening or not (the inspector's, a test's).
        [[nodiscard]] AccessTreeUpdate BuildAccessTree(SceneRoot& root);
        /// `node`'s accessibility node as it is now; false when it has none of its own (no role,
        /// hidden, or a part of a leaf: what a screen reader reads it as is an ancestor's).
        bool DescribeAccess(Node& node, AccessNode& out);
        /// The node an accessibility id names, or null when it is gone (an item's: its view's).
        [[nodiscard]] Node* ResolveAccessId(u64 id) const noexcept
        {
            if (IsAccessItemId(id))
            {
                const Node::ElementRef* view = m_accessViews.Find(static_cast<u32>((id & ~kAccessItemIdBit) >> 32));
                return view != nullptr && view->table != nullptr ? view->table->Resolve(view->slot, view->generation) : nullptr;
            }
            return m_elements->Resolve(static_cast<u32>(id & 0xFFFFFFFFu), static_cast<u32>(id >> 32));
        }
        /// An item view's key among this GUI's, given the first time it is asked (E17b).
        [[nodiscard]] u32 AccessViewKey(Node& view); // AccessibilityImpl.cpp

    private:
        friend class SceneRoot;
        ActionManager m_actionManager;
        MutationQueue m_mutationQueue;
        EffectScheduler m_effects;
        RefPtr<ElementTable> m_elements; // what weak references to this GUI's nodes resolve through
        ElementSet m_elementSet = ElementSet::All();
        RefPtr<DataModel> m_data;        // shared with the bindings to it
        CommandSet m_commands;
        Keymap m_keymap;
        fonts::IFontService* m_fontService = nullptr;
        bool m_darkScheme = true; // the user's preferences, for media queries (E13)
        ContrastPreference m_contrast = ContrastPreference::NoPreference;
        bool m_reducedMotion = false;
        IResourceProvider* m_resources = nullptr;
        IPictureBaker* m_baker = nullptr;
        foundation::i18n::Localization* m_localization = nullptr; // the host's
        u32 m_localizationToken = 0;
        Observable m_languageChanged;
        struct ServiceEntry
        {
            core::String Key;
            void* Service = nullptr;
        };
        Array<ServiceEntry> m_services; // K6: what libraries find through the GUI (borrowed)
        Observable m_servicesChanged;
        Array<Keystroke> m_chord; // a chord typed so far (in the active root)
        IAccessibilityBridge* m_accessBridge = nullptr; // the host's
        bool m_accessListening = false;                 // it listened at the last update
        core::Mutex m_accessLock;                       // guards the requests, which any thread adds
        core::HashMap<u32, Node::ElementRef> m_accessViews; // item views by key (E17b), for their items' ids
        u32 m_nextAccessView = 1;
        Array<AccessActionRequest> m_accessRequests;
        void RunAccessRequests();  // AccessibilityImpl.cpp: the requests queued, each run
        void FlushAccessibility(); // AccessibilityImpl.cpp: each root's changes to the bridge
        f32 m_chordAge = 0.0f;
        f32 m_maxClockStep = 0.0f; // K5: the clock's step at most this (0: unlimited)
        static constexpr f32 kChordTimeout = 1.0f;
        Array<SceneRoot*> m_roots; // non-owning: each root registers itself and leaves on destruction
        SceneRoot* m_active = nullptr;
        Observable m_activeChanged;
        u32 m_lastBindingCount = 0;

        IRootPlaces* m_rootPlaces = nullptr; // the host's
        void AddRoot(SceneRoot& root); // after SceneRoot: it hands the root's dispatcher the places
        void LanguageChanged(); // after SceneRoot, which it restyles
        void RemoveRoot(SceneRoot& root); // after SceneRoot: the others' drags forget it
    };

    class SceneRoot : public Node
    {
        RTTI_OBJECT(SceneRoot, Node)
    public:
        /// A root of `context`'s GUI, beside its other roots (a GUI of one root is a context with one).
        explicit SceneRoot(RefPtr<GUIContext> context) : m_context(core::Move(context))
        {
            m_context->AddRoot(*this);
            m_eventDispatcher.SetKeystrokeRouter([this](const Keystroke& stroke) { return RouteKeystroke(stroke); });
            m_eventDispatcher.SetOnInput([this]() { m_context->TookInput(*this); });
            // F10 (bound in every GUI): the first node in this tree that takes it, a menu bar.
            (void)OnCommand(core::StringView(u8"menu.enter-bar"), [this](CommandEvent&) { (void)EnterFromKeyboardIn(*this); });
            // Shift+F10 (bound in every GUI): the focused node's context menu.
            (void)OnCommand(core::StringView(u8"menu.context"), [this](CommandEvent&) { (void)m_eventDispatcher.InjectContextMenu(); });
            // Ctrl+Shift+D or the pad's North (bound in every GUI): a drag picked up at the focus.
            (void)OnCommand(core::StringView(u8"drag.pick"), [this](CommandEvent&) { (void)m_eventDispatcher.PickDrag(); });
        }
        ~SceneRoot() override { m_context->RemoveRoot(*this); }

        [[nodiscard]] GUIContext& GetContext() noexcept { return *m_context; }
        [[nodiscard]] const RefPtr<GUIContext>& GetContextRef() const noexcept { return m_context; }
        [[nodiscard]] GUIContext* GetGUIContext() override { return m_context.Get(); }

        /// Runs this root's layout pass: every container that requested a layout, parents first,
        /// again while a layout requests more (a child's new size can move its parent), at most a
        /// few rounds. A host runs it after styling and before drawing; Update runs it too.
        void UpdateLayout()
        {
            PROFILE_SCOPE("GUI.Layout");
            const core::Stopwatch watch = core::Stopwatch::StartNew();
            m_lastLayoutCount = Node::UpdateLayout();
            m_eventDispatcher.PlacePopups(); // the top layer follows what moved
            m_frameStats.LayoutMs += watch.Elapsed().AsMilliseconds(); // the GUI's Update lays out too
            m_frameStats.LaidOut += m_lastLayoutCount;
        }
        /// How many containers the last layout pass laid out (none in a frame where nothing moved).
        [[nodiscard]] u32 LastLayoutCount() const noexcept { return m_lastLayoutCount; }

        /// Whether this root has anything to show that it has not drawn: something invalidated, an
        /// animation running on a node it shows, a layout or a binding waiting, a direction held.
        /// An action on a node out of view still runs (the GUI's Update ticks it either way); it
        /// asks for no frame until what it does shows. A host skips a
        /// frame that needs none: an idle GUI costs nothing.
        /// The reasons it found go to the frame stats (E8a), and the frame's style and layout are
        /// done: they become the last frame's, which a draw then completes (a host asks once a
        /// frame, after styling and laying out).
        [[nodiscard]] bool NeedsFrame()
        {
            FrameReasons& why = m_frameStats.Reasons;
            // A bake landed since this root last drew: what drew as paths while it waited draws
            // from it now.
            if (const IPictureBaker* baker = m_context->GetPictureBaker(); baker != nullptr && baker->Generation() != m_bakeGeneration)
                Invalidate();
            why.Redraw = NeedsRedraw();
            why.Layout = IsLayoutDirty() || HasLayoutDirtyDescendant();
            why.Pending = m_context->m_effects.HasPending();
            why.HeldDirection = m_eventDispatcher.IsHoldingDirection();
            const Node* animated = nullptr;
            if (!IsPaused())
                (void)m_context->m_actionManager.AnyAction([this, &animated](const Action& action, Node& target)
                {
                    if (target.GetSceneRoot() != this || !target.IsTreeVisible())
                        return false;
                    // Out of view at the last frame (culled, or under something culled), an
                    // animation that cannot bring it into view changes nothing that shows (E8b).
                    if (target.WasOutOfView() && !action.CanMoveTarget())
                        return false;
                    animated = &target;
                    return true;
                });
            why.Animation = animated != nullptr;
            m_frameStats.AnimatedNode = animated != nullptr ? animated->DebugName() : core::String{};
            why.Overlay = m_debugOverlay.RedrawFlash && !m_flashes.IsEmpty();
            const bool needed = why.Any();
            PublishFrame();
            return needed;
        }

        /// Draws the tree as Draw does, timing it and counting what it made (E8a): the host's
        /// frame. A frame drawn through Draw alone goes uncounted.
        void DrawFrame(DrawContext& ctx)
        {
            PROFILE_SCOPE("GUI.Draw");
            if (!m_framePublished)
                PublishFrame(); // a host that draws every frame without asking
            const core::Stopwatch watch = core::Stopwatch::StartNew();
            const vg::VGBatch& before = ctx.VG().GetBatch();
            const usize vertices = before.vertices.Size() + before.boxVertices.Size();
            const usize commands = before.commands.Size();
            const u32 drawn = ctx.NodesDrawn();
            const u32 culled = ctx.NodesCulled();
            ctx.SetFrame(m_framesDrawn + 1); // the nodes drawn note it (FramesDrawn is set after)
            ctx.SetPictureBaker(m_context->GetPictureBaker());
            m_bakeGeneration = m_context->GetPictureBaker() != nullptr ? m_context->GetPictureBaker()->Generation() : 0;
            m_frameRedraws.Clear();
            if (m_debugOverlay.RedrawFlash)
                ctx.SetRedrawRecorder(&m_frameRedraws);
            // Damage (E15): what changed since the last frame, its nodes' old areas noted as they
            // changed, their new ones as they draw.
            m_lastDamage = core::Move(m_pendingDamage);
            m_pendingDamage = core::Array<Rect>{};
            ctx.SetDamageRecorder(&m_lastDamage);
            // The window bounds the drawing, so what lies outside it is culled (E8b); only the
            // drawing: navigation and hit testing still reach a node past it.
            const bool sized = GetSize().x > 0.0f && GetSize().y > 0.0f;
            if (sized)
                ctx.PushClip(Rect{GetPosition().x, GetPosition().y, GetSize().x, GetSize().y});
            Draw(ctx);
            if (sized)
                ctx.PopClip();
            ctx.SetRedrawRecorder(nullptr);
            ctx.SetDamageRecorder(nullptr);
            m_lastDamageBounds = Rect{};
            for (usize i = 0; i < m_lastDamage.Size(); ++i)
                m_lastDamageBounds = i == 0 ? m_lastDamage[i] : Rect::Union(m_lastDamageBounds, m_lastDamage[i]);
            const vg::VGBatch& batch = ctx.VG().GetBatch(); // flushed: its last command counts
            m_lastFrame.DrawMs = watch.Elapsed().AsMilliseconds();
            m_lastFrame.NodesDrawn = ctx.NodesDrawn() - drawn;
            m_lastFrame.NodesCulled = ctx.NodesCulled() - culled;
            m_lastFrame.Vertices = static_cast<u32>(batch.vertices.Size() + batch.boxVertices.Size() - vertices);
            m_lastFrame.Commands = static_cast<u32>(batch.commands.Size() - commands);
            m_lastFrame.FramesDrawn = ++m_framesDrawn;
            m_framePublished = false;
        }
        /// What the last frame drew changed, in device pixels (E15): each node's area where it is new,
        /// changed, moved or gone, and the bounds of them all. A host that can present part of a
        /// frame (or redraw a HUD over its scene) redraws this much; empty when nothing changed.
        [[nodiscard]] const core::Array<Rect>& GetLastDamage() const noexcept { return m_lastDamage; }
        [[nodiscard]] const Rect& GetLastDamageBounds() const noexcept { return m_lastDamageBounds; }
        void AddDamage(const Rect& device) override { m_pendingDamage.PushBack(device); }

        /// The frame in progress, which the phases add to.
        [[nodiscard]] FrameStats* GetFrameStats() override { return &m_frameStats; }
        /// The last frame: its style, layout and reasons (as NeedsFrame closed it), and its draw
        /// (none when it was skipped).
        [[nodiscard]] const FrameStats& GetLastFrameStats() const noexcept { return m_lastFrame; }
        [[nodiscard]] u32 GetLastDrawnFrame() const override { return m_framesDrawn; }

        // === This root's time on the GUI's clock ===
        /// Its animations' time scale (1: real time; 0.5: half speed). A paused root's stand still.
        void SetTimeScale(f32 scale) noexcept { m_timeScale = core::Max(0.0f, scale); }
        [[nodiscard]] f32 GetTimeScale() const noexcept { return m_timeScale; }
        void SetPaused(bool paused) noexcept { m_paused = paused; }
        [[nodiscard]] bool IsPaused() const noexcept { return m_paused; }
        [[nodiscard]] f32 EffectiveTimeScale() const noexcept { return m_paused ? 0.0f : m_timeScale; }

        [[nodiscard]] EffectScheduler* GetEffectScheduler() override { return &m_context->m_effects; }
        [[nodiscard]] ActionManager* GetActionManager() override { return &m_context->m_actionManager; }
        [[nodiscard]] MutationQueue* GetMutationQueue() override { return &m_context->m_mutationQueue; }
        [[nodiscard]] EventDispatcher* GetEventDispatcher() override { return &m_eventDispatcher; }
        [[nodiscard]] fonts::IFontService* GetFontService() override { return m_context->GetFontService(); }
        [[nodiscard]] IResourceProvider* GetResourceProvider() override { return m_context->GetResourceProvider(); }
        [[nodiscard]] ElementTable* GetElementTable() override { return m_context->m_elements.Get(); }
        [[nodiscard]] const ElementSet* GetElementSet() const override { return &m_context->m_elementSet; }

        // === Commands (G7), along this root's focus path ===
        /// Runs command `id` along this root's focus path (the root alone when nothing here is
        /// focused): capture handlers from the root down, then bubble handlers from the focused
        /// widget up, the first bubble handler stopping it unless it sets Propagate. False when it is
        /// disabled or nothing handled it.
        bool RunCommand(core::StringView id)
        {
            if (const Command* command = m_context->GetCommands().Find(id); command != nullptr && !Untracked([&] { return command->IsEnabled(); }))
                return false;
            // Back closes the topmost auto popup before anything under it hears it (K1): the top
            // layer is on top whether or not it holds the focus (a combo box's list).
            if (id == core::StringView(kBackCommand) && m_eventDispatcher.CloseTopAutoPopup(PopupCloseReason::Escape))
                return true;
            // Focused first, up to this root or a modal popup (below it is inert); held for the walk,
            // as a handler may end nodes on it (a dock float its own move empties).
            Array<RefPtr<Node>> path(MemoryAllocator());
            for (Node* n = CommandStart(); n != nullptr; n = n->GetParent())
            {
                path.PushBack(RefPtr<Node>(n));
                if (n->IsRouteStop())
                    break;
            }
            bool ran = false;
            CommandEvent event{id, CommandPhase::Capture, false, false};
            for (usize i = path.Size(); i-- > 0;)
            {
                ran |= path[i]->RunCommandHandlers(event);
                if (event.Stop)
                    return true; // taken on the way down (a modal wrapper, a mode that owns the key)
            }
            event.Phase = CommandPhase::Bubble;
            for (const RefPtr<Node>& n : path)
            {
                event.Propagate = false;
                if (n->RunCommandHandlers(event))
                {
                    ran = true;
                    if (!event.Propagate)
                        break;
                }
            }
            return ran;
        }

        /// Whether command `id` is enabled and a handler for it is on this root's focus path: a read
        /// a binding follows (focus, the command's state, the handlers).
        [[nodiscard]] bool IsCommandAvailable(core::StringView id)
        {
            m_context->GetCommands().TrackChanges();
            (void)m_eventDispatcher.ObserveFocus();
            if (const Command* command = m_context->GetCommands().Find(id); command != nullptr && !command->IsEnabled())
                return false;
            if (id == core::StringView(kBackCommand) && m_eventDispatcher.HasTopAutoPopup())
                return true;
            for (Node* n = CommandStart(); n != nullptr; n = n->GetParent())
            {
                if (n->HandlesCommand(id))
                    return true;
                if (n->IsRouteStop())
                    break;
            }
            return false;
        }

        /// A keystroke no widget used: matched against the GUI's keymap in this root's focus-path
        /// contexts (a chord waits for its next keystroke); a match runs its command. True when it
        /// was taken (a match, or the start of a chord).
        /// The key contexts in force at `from` (root first, one layer per node up from it that
        /// declares one, up to this root or a modal popup): what the keymap matches against there.
        [[nodiscard]] Array<KeyContextLayer> KeyContextsAt(Node* from) const
        {
            Array<KeyContextLayer> stack;
            Array<Node*> path;
            for (Node* n = from; n != nullptr; n = n->GetParent())
            {
                path.PushBack(n);
                if (n->IsRouteStop())
                    break;
            }
            KeyContextLayer layer;
            for (usize i = path.Size(); i-- > 0;)
                if (path[i]->GetKeyContext().Size() != 0)
                {
                    layer.Declare(path[i]->GetKeyContext());
                    stack.PushBack(layer);
                }
            return stack;
        }
        /// A chord cut short: what its keys so far are whole for runs (a binding of its first key
        /// alone, which waited to see if the chord went on), and the chord ends.
        void FinishChord()
        {
            Array<Keystroke>& chord = m_context->m_chord;
            core::String command;
            const Array<KeyContextLayer> stack = KeyContextsAt(CommandStart());
            const bool whole = !chord.IsEmpty() && m_context->GetKeymap().MatchWhole(chord.AsSpan(), stack.AsSpan(), command);
            chord.Clear();
            if (whole)
                (void)RunCommand(command.AsView());
        }

        bool RouteKeystroke(const Keystroke& stroke)
        {
            const Array<KeyContextLayer> stack = KeyContextsAt(CommandStart()); // root first
            Array<Keystroke>& chord = m_context->m_chord;
            chord.PushBack(stroke);
            m_context->m_chordAge = 0.0f;
            core::String command;
            KeymapMatch match = m_context->GetKeymap().Match(chord.AsSpan(), stack.AsSpan(), command);
            if (match == KeymapMatch::None && chord.Size() > 1)
            {
                // A chord broken off: what came before runs as whole if it is (its first key's own
                // binding), then the keystroke alone.
                chord.PopBack();
                FinishChord();
                chord.PushBack(stroke);
                match = m_context->GetKeymap().Match(chord.AsSpan(), stack.AsSpan(), command);
            }
            if (match == KeymapMatch::Pending)
                return true;
            chord.Clear();
            if (match == KeymapMatch::None || command.Size() == 0)
                return false; // no binding, or unbound here: as if none
            // Nothing on the focus path handles it (a menu's keys on a bar button with no menu open,
            // E12): as if unbound, so the key goes on to navigation. One disabled is still taken.
            bool handled = command.AsView() == core::StringView(kBackCommand) && m_eventDispatcher.HasTopAutoPopup();
            for (Node* n = CommandStart(); n != nullptr && !handled; n = n->GetParent())
            {
                handled = n->HandlesCommand(command.AsView());
                if (n->IsRouteStop())
                    break;
            }
            if (!handled)
                return false;
            (void)RunCommand(command.AsView());
            return true;
        }

        /// Device pixels per logical unit: the window's content scale times a UI scale. The tree
        /// lays out, styles and handles input in logical units; the root's transform maps them to
        /// device pixels (input in device pixels hit-tests through it). The size follows: the
        /// viewport's device pixels over the scale.
        void SetDisplayScale(f32 scale)
        {
            const f32 was = m_displayScale;
            m_displayScale = core::Max(scale, 0.01f);
            Transformable::SetScale(core::Float2{m_displayScale, m_displayScale});
            if (m_displayScale != was)
            {
                RequestLayoutTree(); // every edge rounds to the new grid
                Invalidate();        // the same scale again changes nothing (E15: no damage)
            }
            ApplyViewport();
        }
        [[nodiscard]] f32 GetDisplayScale() const noexcept { return m_displayScale; }

        /// What the debug overlay shows over this GUI's tree (nothing by default, E8c).
        void SetDebugOverlay(const DebugOverlay& overlay)
        {
            if (overlay == m_debugOverlay)
                return;
            m_debugOverlay = overlay;
            Invalidate();
        }
        [[nodiscard]] const DebugOverlay& GetDebugOverlay() const noexcept { return m_debugOverlay; }
        /// The font the overlay names nodes and numbers tab stops in (none: it draws no text).
        void SetDebugFont(fonts::CachedFont* font) noexcept { m_debugFont = font; }

    protected:
        [[nodiscard]] f32 TopPixelScale() const override { return m_displayScale; }
        // A node with no `lang` above it speaks the GUI's language (its Localization's).
        [[nodiscard]] core::String ContextLanguage() const override
        {
            const foundation::i18n::Localization* loc = m_context->GetLocalization();
            return loc != nullptr ? core::String(loc->Language()) : core::String{};
        }
        [[nodiscard]] bool ContextRightToLeft() const override
        {
            const foundation::i18n::Localization* loc = m_context->GetLocalization();
            return loc != nullptr && loc->IsRightToLeft();
        }
        void OnDrawAbove(DrawContext& ctx) override
        {
            m_eventDispatcher.DrawPopups(ctx); // the top layer, after the tree (E5)
            if (m_debugOverlay.AnyLayout())
                DrawLayoutOverlay(ctx, m_debugOverlay);
            if (m_debugOverlay.RedrawFlash)
                DrawRedrawFlashes(ctx);
            if (m_debugOverlay.AnyInput())
                DrawInputOverlay(ctx);
        }

    private:
        // The debug overlay's input half, in this root's space (DebugOverlayImpl.cpp).
        void DrawInputOverlay(DrawContext& ctx) const;
        // This frame's redraws join the flashes, which fade over half a second (DebugOverlayImpl.cpp).
        void DrawRedrawFlashes(DrawContext& ctx);

    public:
        /// The redraw flashes still fading (the debug overlay's), in this root's space.
        [[nodiscard]] usize RedrawFlashCount() const noexcept { return m_flashes.Size(); }

    private:
        struct RedrawFlash
        {
            Rect Box; // in this root's space
            core::Stopwatch Age;
        };
        // `node`'s border box in this root's space.
        [[nodiscard]] Rect InRootSpace(const Node& node) const
        {
            return (GetTransform().GetInverse() * node.GetWorldTransform()).TransformRect(node.GetLocalBounds());
        }

    public:

        /// The device pixels this root covers (its window's or target's); its size is them in
        /// logical units.
        void SetViewportSize(core::Float2 devicePixels)
        {
            m_viewport = devicePixels;
            ApplyViewport();
        }
        [[nodiscard]] core::Float2 GetViewportSize() const noexcept { return m_viewport; }

        /// What this root's media queries see: its logical size, and its density (96 dpi at 1x).
        [[nodiscard]] MediaContext GetMediaContext() const noexcept
        {
            MediaContext context{GetSize().x, GetSize().y, 96.0f * m_displayScale};
            context.DarkScheme = m_context->IsDarkScheme();
            context.Contrast = m_context->GetContrastPreference();
            context.ReducedMotion = m_context->IsReducedMotion();
            context.Input = m_eventDispatcher.GetInputKind(); // K2b: `@media (input: pad)`
            return context;
        }

        // Per-frame hook for subclasses (layout, timers, ...).
        virtual void OnUpdate(core::Duration elapsed) { (void)elapsed; }

    private:
        friend class GUIContext;
        RefPtr<GUIContext> m_context;            // the GUI this root is part of (declared first: outlives the rest)
        bool m_accessSent = false;               // its whole tree went to the bridge (E9d)
        u64 m_accessFocus = 0;                   // the focus the bridge was last told
        EventDispatcher m_eventDispatcher{this}; // pointer, hover and focus: this root's own
        f32 m_displayScale = 1.0f;
        DebugOverlay m_debugOverlay;
        core::Array<Rect> m_frameRedraws;     // the nodes this frame drew that invalidated themselves (world)
        core::Array<Rect> m_pendingDamage;    // old areas noted since the last frame (device pixels, E15)
        core::Array<Rect> m_lastDamage;       // the last frame's damage
        Rect m_lastDamageBounds;
        core::Array<RedrawFlash> m_flashes;   // fading
        fonts::CachedFont* m_debugFont = nullptr; // the overlay's text (the host's)
        FrameStats m_frameStats; // in progress
        FrameStats m_lastFrame;
        u64 m_framesDrawn = 0;
        u64 m_bakeGeneration = 0; // the picture baker's, as of the last frame drawn
        bool m_framePublished = false;

        // The frame's style and layout are done: the last frame starts from them, undrawn.
        void PublishFrame()
        {
            m_lastFrame = core::Move(m_frameStats);
            m_lastFrame.FramesDrawn = m_framesDrawn;
            m_frameStats = FrameStats{};
            m_framePublished = true;
        }
        f32 m_timeScale = 1.0f;
        bool m_paused = false;
        u32 m_lastLayoutCount = 0;
        core::Float2 m_viewport{0.0f, 0.0f};

        // The focused node when it is in this tree, else this root.
        [[nodiscard]] Node* FocusInThisTree()
        {
            Node* focus = m_eventDispatcher.GetFocusNode();
            for (Node* n = focus; n != nullptr; n = n->GetParent())
                if (n == this)
                    return focus;
            return this;
        }
        // The first visible, enabled node from `node` down (pre-order) that takes the keyboard's entry.
        static bool EnterFromKeyboardIn(Node& node)
        {
            if (!node.IsVisible() || !node.IsTreeEnabled())
                return false;
            if (&node != node.GetRootNode() && node.EnterFromKeyboard())
                return true;
            for (usize i = 0; i < node.ChildCount(); ++i)
                if (EnterFromKeyboardIn(*node.GetChildAt(i)))
                    return true;
            return false;
        }
        // Where a command or a keystroke starts: the focus here, else the root; below a modal popup,
        // the modal popup (what is under it is inert, its bindings too).
        [[nodiscard]] Node* CommandStart()
        {
            Node* start = FocusInThisTree();
            return m_eventDispatcher.IsInputLive(start) ? start : m_eventDispatcher.GetFocusScopeRoot();
        }

        void ApplyViewport()
        {
            if (m_viewport.x > 0.0f || m_viewport.y > 0.0f)
                SetSize(core::Float2{m_viewport.x / m_displayScale, m_viewport.y / m_displayScale});
        }
    };

    inline void GUIContext::Update(core::Duration elapsed)
    {
        RunAccessRequests(); // what a platform asked since: this frame shows it
        const f32 seconds = static_cast<f32>(elapsed.AsSecondsF());
        // The motion's clock steps at most so far (K5): a hitch slows it rather than skipping it.
        const core::Duration step = m_maxClockStep > 0.0f && seconds > m_maxClockStep
                                        ? core::Duration::FromSeconds(static_cast<f64>(m_maxClockStep))
                                        : elapsed;
        m_actionManager.Update(step,
                               [](Node& target)
                               {
                                   const SceneRoot* root = target.GetSceneRoot();
                                   return root != nullptr ? root->EffectiveTimeScale() : 1.0f;
                               });
        if (!m_chord.IsEmpty() && (m_chordAge += seconds) > kChordTimeout)
        {
            // A chord not finished in time: what its keys so far bind (its first key alone) runs.
            if (SceneRoot* root = GetActiveRoot())
                root->FinishChord();
            m_chord.Clear();
        }
        // A root's hook may add or remove roots: walk a copy.
        const Array<SceneRoot*> roots = m_roots;
        for (SceneRoot* root : roots)
        {
            root->m_eventDispatcher.Tick(seconds);
            root->OnUpdate(elapsed);
        }
        m_lastBindingCount = m_effects.Flush();
        m_mutationQueue.Drain();
        for (SceneRoot* root : m_roots)
            root->UpdateLayout();
        FlushAccessibility();
    }

    inline void GUIContext::AddRoot(SceneRoot& root)
    {
        m_roots.PushBack(&root);
        root.GetEventDispatcher()->SetRootPlaces(m_rootPlaces);
    }
    inline void GUIContext::RemoveRoot(SceneRoot& root)
    {
        for (usize i = 0; i < m_roots.Size(); ++i)
            if (m_roots[i] == &root)
            {
                m_roots.RemoveAt(i);
                break;
            }
        for (SceneRoot* other : m_roots)
            other->GetEventDispatcher()->ForgetRoot(*root.GetEventDispatcher());
        if (m_active == &root)
            SetActiveRoot(nullptr);
    }
    inline void GUIContext::SetRootPlaces(IRootPlaces* places)
    {
        m_rootPlaces = places;
        for (SceneRoot* root : m_roots)
            root->GetEventDispatcher()->SetRootPlaces(places);
    }

    inline void GUIContext::LanguageChanged()
    {
        m_languageChanged.Notify(); // translated properties resolve again
        for (SceneRoot* root : m_roots)
            root->DirectionChanged(); // :lang may match otherwise, and the language's direction may differ
    }

    inline void GUIContext::TookInput(SceneRoot& root)
    {
        for (SceneRoot* other : m_roots)
            if (other != &root)
                other->GetEventDispatcher()->CloseLightPopups();
        SetActiveRoot(&root);
    }

    inline bool GUIContext::RunCommand(core::StringView id)
    {
        SceneRoot* root = GetActiveRoot();
        return root != nullptr && root->RunCommand(id);
    }

    inline bool GUIContext::IsCommandAvailable(core::StringView id)
    {
        m_activeChanged.Track();
        SceneRoot* root = GetActiveRoot();
        return root != nullptr && root->IsCommandAvailable(id);
    }
}
