// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI Sandbox - foundation.gui's demo (Documentation/Specs/vg-and-gui-lab.md), built from the GUI
// itself. A shell (Data/Assets/ui/sandbox/shell.xml: a header, a sidebar of pages, the page on
// show) whose sidebar buttons run page.<id> commands; each page is pages/<id>.xml with an optional
// pages/<id>.css and pages/<id>.as, so a new page is a button and its files. This host only sizes
// the shell, fills the few hosts that need native models or widgets (the data views, the menu bar,
// the context menu, the floating window, the message box, an image, anchors), and
// switches the theme. The game menu (Data/Assets/ui/showcase) is a second root of the same GUI:
// it shares the data, and its Leave brings the player back here.
//
// Drawn through VG with everything it has (analytic boxes, layers and blurs, the MSAA and stencil
// pass), only on frames that need it. Input reaches the root on show through GuiInputBridge.

#include <algorithm> // sort (the soak's frame times)
#include <new>
#include <cstdio> // printf, fprintf
#include <cstdlib> // atof

import foundation.core;
import foundation.rhi;
import foundation.shell;
import foundation.shell.desktop;   // the window
import foundation.vfs;             // the data folder
import foundation.graphics;        // the device and the window's frames
import foundation.graphics.gpu;
import foundation.runtime;
import foundation.runtime.client;  // IApplication: the runtime host runs the sandbox
import foundation.runtime.desktop;
import foundation.image;
import foundation.image.io; // the resource provider's pictures
import foundation.fonts;
import foundation.fonts.truetype;
import foundation.fonts.bidi;
import foundation.fonts.harfbuzz; // joined Arabic (E9e)
import foundation.i18n;           // the Language and direction page's table (E9e)
import foundation.xml;
import foundation.xml.serialization;
import foundation.fonts.distancefield.baker; // the Lilita distance-field face
import foundation.vg;
import foundation.vg.renderer;
import foundation.vg.svg; // the resource provider's SVG pictures (E13)
import foundation.gui;
import foundation.gui.shell;
import foundation.gui.inspector; // Ctrl+Shift+I (E8e)
import foundation.gui.testing;   // --keys targets by selector or text (E8f), the image tests' match (E8g)
import foundation.gui.hosting;   // the host: the window's GUI, offscreen pictures, the picture baker
import foundation.gui.viewport;  // the Viewport page's widget
import foundation.gui.docking;   // the Docking page's dock space
import foundation.gui.toolkit;   // the Toolkit page's tool and status bars
import foundation.gui.code;      // the Code page's editors (C8)
import foundation.gui.gamekit;   // the game menu's screens and prompts (K7)
import foundation.input;           // the game menu's actions, which its prompts show
import foundation.shaders;         // the Viewport page's cube compiles its shader
import foundation.rhi.capture;     // F12 and --screenshot
import gui.sandbox.stress; // the Stress page (E8a)
import gui.sandbox.lamps;  // the Toolkit page's property source (T1)
import gui.sandbox.camera; // the Toolkit page's reflected object (T3)
import gui.sandbox.code;   // the Code page (C8)
import foundation.script; // the pages' and the game menu's scripts
#ifdef OPTION_HAS_ANGELSCRIPT
import foundation.script.angelscript;
#endif

#include "../../Samples/Common/FlyCamera.h"    // the Viewport page's camera, from its gated input
#include "../../Samples/Common/SpinningCube.h" // what the Viewport page shows

using namespace foundation::core;
namespace rhi = foundation::rhi;
namespace shell = foundation::shell;
namespace runtime = foundation::runtime;
namespace graphics = foundation::graphics;
namespace vfs = foundation::vfs;
namespace image = foundation::image;
namespace fonts = foundation::fonts;
namespace vg = foundation::vg;
namespace gui = foundation::gui;
namespace script = foundation::script;

namespace
{
    // This binary's composition root: the ONE ambient-allocator decision here. It counts what is
    // live (--soak reports it); built in place and never destroyed, so frees at exit still find it.
    [[nodiscard]] TrackingAllocator& AppRoot() noexcept
    {
        alignas(TrackingAllocator) static unsigned char storage[sizeof(TrackingAllocator)];
        static TrackingAllocator* const tracking = new (storage) TrackingAllocator(DefaultAllocator());
        return *tracking;
    }

    // The process's resident memory in MiB (Linux; 0 elsewhere), for what does not go through AppRoot.
    [[nodiscard]] f64 ResidentMiB()
    {
        f64 mib = 0.0;
        if (FILE* statm = std::fopen("/proc/self/statm", "r"))
        {
            unsigned long size = 0;
            unsigned long resident = 0;
            if (std::fscanf(statm, "%lu %lu", &size, &resident) == 2)
                mib = static_cast<f64>(resident) * 4096.0 / (1024.0 * 1024.0);
            std::fclose(statm);
        }
        return mib;
    }

    constexpr StringView kRoboto = u8"Assets/fonts/roboto/Roboto-Regular.ttf";
    constexpr StringView kLilita = u8"Assets/fonts/lilita-one/LilitaOne-Regular.ttf";
    constexpr StringView kDejaVu = u8"Assets/fonts/dejavu/DejaVuSansMono.ttf"; // Arabic, which Roboto has not
    constexpr StringView kStrings = u8"Assets/ui/sandbox/i18n/sandbox.strings.xml";
    constexpr StringView kSandboxDir = u8"Assets/ui/sandbox/";
    constexpr StringView kMenuDir = u8"Assets/ui/showcase/";
    constexpr StringView kPageCommand = u8"page.";

    constexpr f32 kHeaderHeight = 60.0f;
    constexpr f32 kSidebarWidth = 210.0f;

    // The first widget under `node` (itself included) whose id is `id`.
    [[nodiscard]] gui::Node* FindById(gui::Node& node, StringView id)
    {
        if (const gui::UIWidget* widget = Cast<gui::UIWidget>(&node); widget != nullptr && widget->GetId() == id)
            return &node;
        for (usize i = 0; i < node.ChildCount(); ++i)
            if (gui::Node* found = FindById(*node.GetChildAt(i), id))
                return found;
        return nullptr;
    }

    // Every node under `node` (itself included) whose bound command starts with `prefix`.
    void CollectCommands(gui::Node& node, StringView prefix, Array<gui::Node*>& out)
    {
        const StringView command = node.GetCommand();
        if (command.Size() > prefix.Size() && command.SubStr(0, prefix.Size()) == prefix)
            out.PushBack(&node);
        for (usize i = 0; i < node.ChildCount(); ++i)
            CollectCommands(*node.GetChildAt(i), prefix, out);
    }

    // The GUI's pictures (an Image's src, a sheet's background-image: url()), loaded from the data
    // folder once each and kept for the sandbox's life.
    class SandboxResources final : public gui::IResourceProvider
    {
    public:
        explicit SandboxResources(Function<String(StringView)> resolve) : IResourceProvider(AppRoot()), m_resolve(Move(resolve)) {}
        const image::ImageData* LoadImage(StringView path) override
        {
            for (const Entry& e : m_images)
                if (e.Path.AsView() == path)
                    return e.Picture.Get();
            UniquePtr<image::Image> picture = MakeUnique<image::Image>(AppRoot());
            if (!image::io::LoadImage(m_resolve(path).AsView(), *picture).IsOk())
                picture = UniquePtr<image::Image>{}; // missing: remembered as such
            m_images.PushBack(Entry{String(path), Move(picture)});
            return m_images[m_images.Size() - 1].Picture.Get();
        }
        // A CSS SVG image (E13), parsed once and kept (missing: remembered as such).
        const foundation::vg::svg::SVGDocument* LoadSvg(StringView path) override
        {
            for (const SvgEntry& e : m_svgs)
                if (e.Path.AsView() == path)
                    return e.Document.Get();
            UniquePtr<foundation::vg::svg::SVGDocument> document;
            String text;
            if (LoadText(path, text))
                if (Result<foundation::vg::svg::SVGDocument> parsed = foundation::vg::svg::SVGLoader::Load(text.AsView()); parsed.HasValue())
                    document = MakeUnique<foundation::vg::svg::SVGDocument>(AppRoot(), Move(parsed.Value()));
            m_svgs.PushBack(SvgEntry{String(path), Move(document)});
            return m_svgs[m_svgs.Size() - 1].Document.Get();
        }
        // A sheet's @import, from the data folder.
        bool LoadText(StringView path, String& out) override
        {
            Result<Array<byte>> bytes = ReadFile(m_resolve(path).AsView(), AppRoot());
            if (!bytes.HasValue())
                return false;
            out = String(StringView(reinterpret_cast<const utf8char*>(bytes.Value().Data()), bytes.Value().Size()));
            return true;
        }

    private:
        struct Entry
        {
            String Path;
            UniquePtr<image::Image> Picture;
        };
        struct SvgEntry
        {
            String Path;
            UniquePtr<foundation::vg::svg::SVGDocument> Document;
        };
        Function<String(StringView)> m_resolve;
        Array<Entry> m_images;
        Array<SvgEntry> m_svgs;
    };

    // --narrate (E9e): a bridge that speaks to the console as a screen reader would aloud: each
    // focus change (what it reached, what it is, its value and states) and each announcement.
    class NarrateBridge final : public gui::IAccessibilityBridge
    {
    public:
        explicit NarrateBridge(IAllocator& allocator) : m_nodes(allocator) {}
        [[nodiscard]] bool IsListening() const override { return true; }
        void Update(const gui::AccessTreeUpdate& update) override
        {
            if (update.Full)
                m_nodes.Clear();
            for (const gui::AccessNode& node : update.Nodes)
                m_nodes.InsertOrAssign(node.Id, node);
            if (update.Focus == m_focus)
                return;
            m_focus = update.Focus;
            const gui::AccessNode* focused = m_nodes.Find(update.Focus);
            if (focused == nullptr || focused->Role == gui::AccessRole::Window)
                return;
            String line = focused->Name.Size() != 0 ? focused->Name : String(u8"(no name)");
            line += StringView(u8", ");
            line += gui::AccessRoleName(focused->Role);
            if (focused->Value.Size() != 0)
            {
                line += StringView(u8", ");
                line += focused->Value.AsView();
            }
            if (focused->PositionInSet > 0 && focused->SetSize > 0) // "3 of 100000" (E17b)
            {
                char where[64];
                std::snprintf(where, sizeof(where), ", %d of %d", focused->PositionInSet, focused->SetSize);
                line += StringView(reinterpret_cast<const utf8char*>(where));
            }
            if (focused->Level > 0)
            {
                char level[32];
                std::snprintf(level, sizeof(level), ", level %d", focused->Level);
                line += StringView(reinterpret_cast<const utf8char*>(level));
            }
            if (focused->Has(gui::AccessSelected))
                line += StringView(u8", selected");
            if (focused->Has(gui::AccessChecked))
                line += StringView(u8", checked");
            if (focused->Has(gui::AccessCollapsed))
                line += StringView(u8", collapsed");
            if (focused->Has(gui::AccessExpanded))
                line += StringView(u8", expanded");
            if (focused->Has(gui::AccessDisabled))
                line += StringView(u8", dimmed");
            if (focused->Description.Size() != 0)
            {
                line += StringView(u8". ");
                line += focused->Description.AsView();
            }
            std::printf("narrate: %s\n", reinterpret_cast<const char*>(line.CStr()));
            std::fflush(stdout);
        }
        void Announce(StringView text, gui::AnnouncePriority priority) override
        {
            const String said(text);
            std::printf("narrate (%s): %s\n", priority == gui::AnnouncePriority::Assertive ? "now" : "next",
                        reinterpret_cast<const char*>(said.CStr()));
            std::fflush(stdout);
        }

    private:
        HashMap<u64, gui::AccessNode> m_nodes;
        u64 m_focus = 0;
    };

    struct ScriptErrors final : script::IScriptErrorHandler
    {
        void OnError(const script::ScriptError& error) override
        {
            const String message(error.message);
            const String module(error.module);
            std::fprintf(stderr, "GUISandbox script %s, line %d: %s\n", reinterpret_cast<const char*>(module.CStr()),
                         static_cast<int>(error.line), reinterpret_cast<const char*>(message.CStr()));
        }
    };
}

class GUISandbox : public runtime::IApplication
{
public:
    void SetStartPage(StringView id) { m_startPage = String(id); }
    /// --stress <n>: start on the Stress page, built at load n.
    void SetStress(i32 load)
    {
        m_startPage = String(u8"stress");
        m_stressLoad = load;
    }
    void SetOpenMenu(bool open) { m_openMenuAtStart = open; }
    void SetLightAtStart(bool light) { m_lightAtStart = light; }
    void SetMenuCall(StringView function) { m_menuCall = String(function); }
    void SetKeys(StringView keys) { m_keys = String(keys); }
    void SetAlwaysRedraw(bool always) { m_alwaysRedraw = always; }
    void SetFrameStats(bool stats) { m_frameStats = stats; }
    void SetSweep(bool sweep) { m_sweep = sweep; }
    /// --mirror-audit (E17a): each page laid out left to right and then right to left, in one
    /// language (its text measures the same both ways); every widget must stand at the mirror of its
    /// left-to-right place within the page. Prints each that does not; exits 1 if any did.
    void SetMirrorAudit(bool on) { m_mirrorAudit = on; }
    /// --soak <minutes> [--soak-csv <path>]: the sweep's steps over and over for that long, a CSV
    /// row every ten seconds (frame time percentiles, live allocations and bytes, resident memory).
    void SetSoak(f32 minutes) { m_soakSeconds = Max(0.0f, minutes) * 60.0f; m_sweep = m_soakSeconds > 0.0f; }
    void SetSoakCsv(StringView path) { m_soakCsv = String(path); }
    void SetScroll(f32 pixels) { m_scroll = pixels; }
    void SetLayoutOverlay(bool on) { m_layoutOverlay = on; }
    void SetInputOverlay(bool on) { m_inputOverlay = on; }
    void SetOpenInspector(bool on) { m_openInspector = on; }
    // --image-tests (E8g): each page drawn offscreen at a fixed size on a fixed clock, compared
    // with its reference; --approve-images writes the pictures as the references instead.
    void SetImageTests(bool on) { m_imageTests = on; }
    void SetApproveImages(StringView how) { m_imageTests = true; m_approve = String(how); }
    void SetImageOut(StringView dir) { m_imageOut = String(dir); }
    // --bench <page> [frames] (E15): the page drawn offscreen at the image tests' size, its title's
    // text changed each frame (the smallest change a frame can carry), and the frames' average
    // cost printed by stage: the GUI's draw, the renderer's prepare, the GPU's work.
    void SetBench(StringView page, u32 frames) { m_benchPage = String(page); m_benchFrames = Max(frames, 1u); }
    void SetBackendName(StringView name) { m_backendName = String(name); }
    // What main returns: the image tests' verdict (77, skipped, when no device came up).
    [[nodiscard]] int ImageExitCode(int runCode) const
    {
        if (m_mirrorAudit)
            return m_mirrorAuditDone ? (m_mirrorMisplaced == 0 ? 0 : 1) : 77;
        if (!m_imageTests)
            return m_sweep ? SweepExitCode() : runCode;
        if (m_imagesDone == 0)
            return 77;
        return m_imageFailures == 0 ? 0 : 1;
    }
    // The sweep's verdict: 77 (skipped) when it never ran (no device), else whether anything warned.
    [[nodiscard]] int SweepExitCode() const
    {
        if (!m_sweepDone)
            return 77;
        if (m_sweepLog.problems != 0)
            std::printf("GUISandbox sweep: %u warnings or errors\n", m_sweepLog.problems);
        return m_sweepLog.problems == 0 ? 0 : 1;
    }
    void SetInspectSelector(StringView selector) { m_openInspector = true; m_inspectSelector = String(selector); }
    /// --lang <locale>: the GUI's language at start (E9e; "pseudo": English pseudolocalized).
    void SetStartLanguage(StringView locale) { m_startLanguage = String(locale); }
    /// --narrate: a stand-in screen reader on the console.
    void SetNarrate(bool on) { m_narrate = on; }

    /// The framework's --screenshot flags (and F12): a picture of the window as presented.
    void SetScreenshots(rhi::ScreenshotOptions options) { m_screenshotOptions = Move(options); }

    void OnStartup(runtime::IApplicationHost& host) override;
    void OnUpdate(runtime::IApplicationHost& host, f32 deltaTime) override;
    void OnRenderWindow(runtime::IApplicationHost& host, graphics::FrameContext& frame) override;
    void OnShutdown(runtime::IApplicationHost& host) override;

private:
    // === On the runtime host (H3 of Specs/gui-lab-evolution-3.md) ===
    runtime::IApplicationHost* m_host = nullptr;
    shell::IShell* m_shell = nullptr;
    shell::IWindow* m_window = nullptr;
    graphics::RenderWindow* m_mainWindow = nullptr;
    rhi::Device* m_device = nullptr;
    u32 m_width = 960;  // the window's pixels
    u32 m_height = 820;
    f32 m_deltaTime = 0.0f;
    f32 m_totalTime = 0.0f;
    String m_dataRoot;
    UniquePtr<vfs::NativeFileSystem> m_dataFileSystem;
    UniquePtr<gui::VgShaderLibrary> m_shaders;
    UniquePtr<gui::GuiHost> m_guiHost;      // the window's GUI: input, frames, the baker
    UniquePtr<gui::GuiOffscreen> m_offscreen; // what the image tests and the bench draw into
    void Exit()
    {
        if (m_host != nullptr)
            m_host->RequestExit(0);
    }
    [[nodiscard]] String DataPath(StringView relative) const { return vfs::DataPath(m_dataRoot.AsView(), relative); }
    // The image tests and the bench draw offscreen on a fixed clock: the window shows nothing.
    [[nodiscard]] bool DrawsOffscreen() const noexcept { return m_imageTests || !m_benchPage.IsEmpty(); }
    void Layout(); // the panes' regions: the root on show, the inspector's pane at its right
    // F12 and --screenshot: the window as presented, written once the GPU has run the frame.
    rhi::ScreenshotOptions m_screenshotOptions;
    rhi::ScreenshotCapture m_screenshot;
    u32 m_screenshotsTaken = 0;
    u32 m_screenshotSerial = 0;
    u64 m_presentedFrames = 0;
    bool m_screenshotExitPending = false;
    void RequestScreenshot();
    void FinishScreenshot();

    // === Building ===
    void LoadFonts();
    [[nodiscard]] bool LoadFontFace(StringView face, StringView source);
    [[nodiscard]] String ReadText(StringView relative);
    [[nodiscard]] RefPtr<gui::Node> LoadMarkup(StringView text);
    RefPtr<script::IScriptContext> RunScript(StringView relative, gui::GuiScriptBinding& binding);
    void BuildSandbox();
    void LoadPages();
    void FillNativeHosts();
    void ApplySandboxSheet();
    void BuildMenu();

    // === Running ===
    void ShowPage(StringView id);
    void ToggleTheme();
    // The layout overlay (F9) on both roots: bounds, padding, margins and text baselines.
    void ApplyDebugOverlay();
    void ToggleInspector();
    // The inspector's pane width in device pixels (0 while it is closed).
    [[nodiscard]] f32 InspectorPixels() const
    {
        return m_inspectorOpen ? m_inspectorWidth * (m_window != nullptr ? m_window->ContentScale() : 1.0f) : 0.0f;
    }
    void OpenWindow();
    void ShowMessage();
    void OpenMenu();
    void CloseMenu();
    void LayOutShell();
    void RouteInput();
    void UpdateMenu();
    void TypeKeys(gui::SceneRoot& root);
    void Sweep();
    void MirrorAudit();
    // Styled and laid out as a frame would, without drawing.
    void Settle();

    // === Options ===
    String m_startPage = String(u8"controls");
    String m_startLanguage = String(u8"en");
    bool m_narrate = false;
    bool m_openMenuAtStart = false;
    bool m_lightAtStart = false; // --light: the light colour scheme from the start
    String m_menuCall; // a game-menu script function to call once it is up (a screenshot of a panel)
    String m_keys;     // keystrokes to type into the root on show, one every 15 frames
    bool m_layoutOverlay = false; // F9: the debug overlay's layout half
    bool m_inputOverlay = false;  // F8: its input half (focus path, tab order, navigation, pointer, redraws)
    f32 m_scroll = 0.0f; // the page scrolled down this far once it is up (a screenshot further down)
    bool m_alwaysRedraw = false;
    bool m_frameStats = false;
    i32 m_stressLoad = 1;
    f32 m_nextStressStatsTime = 0.0f;
    // --sweep: every page, then the game menu, each widget hovered, clicked and right-clicked, and
    // each page walked by keys and the pad, one step a frame, each printed first (a crash's last
    // line names its widget); then exit, failing if anything warned or erred while it ran (the
    // GUI.Sweep ctest entries, skipped without a device).
    bool m_sweep = false;
    bool m_sweepDone = false;
    bool m_mirrorAudit = false;
    bool m_mirrorAuditDone = false;
    u32 m_mirrorMisplaced = 0;
    struct SweepStep
    {
        String page;     // a page to show first (empty: none)
        bool menu = false; // the game menu's root
        bool keys = false; // the page walked by Tab, the arrows and the pad instead of a click
        Float2 at{};
        String what;
    };
    // What warned or erred while the sweep ran.
    class SweepLog final : public ILogSink
    {
    public:
        u32 problems = 0;
        void Write(LogLevel level, StringView, StringView) noexcept override
        {
            if (static_cast<u8>(level) >= static_cast<u8>(LogLevel::Warning))
                ++problems;
        }
    };
    SweepLog m_sweepLog;
    f32 m_soakSeconds = 0.0f; // > 0: soaking, not sweeping once
    String m_soakCsv = String(u8"gui-soak.csv");
    f32 m_soakStart = -1.0f;
    f32 m_soakNextRow = 0.0f;
    Array<f32> m_soakFrames; // frame times (ms) since the last row
    FILE* m_soakFile = nullptr;
    void SoakFrame();
    Array<SweepStep> m_sweepSteps;
    usize m_sweepNext = 0;
    f32 m_nextStatsTime = 1.0f;
    u64 m_frames = 0;      // frames the loop ran

    // === The Viewport page (V2 of Specs/gui-lab-evolution-3.md) ===
    RefPtr<gui::Viewport> m_viewport;
    samples::SpinningCube m_cube;
    samples::FlyCamera m_camera;
    foundation::shaders::Compiler* m_cubeCompiler = nullptr;
    f32 m_spin = 0.0f;
    void ResetCamera();

    // === The Docking page (D3 and D4 of Specs/gui-lab-evolution-3.md) ===
    UniquePtr<gui::DockController> m_dock;
    RefPtr<gui::DockArea> m_dockArea;
    UniquePtr<gui::DockHostWindows> m_dockWindows; // the floats in OS windows (D6), while switched on
    void SetDockWindows(bool own);
    Array<String> m_dockPanels; // the registered panels' ids, for "Show the closed panels"
    u32 m_dockMade[8]{};        // how often each panel's content was made (its close policy shows)
    void FillDocking(gui::Node& host);
    void FillToolkit(gui::Node& frame);
    void FillProperties(gui::PropertyGrid& grid);
    void FillReflected(gui::PropertyGrid& grid);
    void SelectCameras(usize which);
    void StepCameras(bool undo);
    void FillClip(gui::Node& section);
    void PlayClip(f32 time);
    void FillGraphs(gui::Node& section);
    void FillCrumbs(gui::Node& section);
    void FillToasts(gui::Node& section);
    // The Toolkit page's edit history: changes left to save, to undo and to redo.
    i32 m_toolkitUnsaved = 0;
    i32 m_toolkitDone = 0;
    i32 m_toolkitUndone = 0;
    void RegisterDockPanel(StringView id, StringView title, gui::DockClosePolicy close, StringView line);

    // === Fonts ===
    UniquePtr<fonts::TrueTypeFontService> m_fontService;
    fonts::CachedFont* m_font = nullptr; // Roboto 16, for what native code builds

    // The Stress page's builder and its views' models: before the GUI, so it outlives the views.
    UniquePtr<sandbox::StressPage> m_stress;
    // The Code page's host (C8): its languages and its service, before the GUI, so the editors
    // that point at them go first.
    UniquePtr<sandbox::CodePage> m_code;
    // The Toolkit page's lamps (T1): before the GUI, so the grid lets go of them first.
    UniquePtr<sandbox::LampSource> m_lamps;
    // The Toolkit page's clip (T5): tracks of the lamps' values, before the GUI too, its axis, and
    // the page's history of its changes.
    UniquePtr<gui::CurveSet> m_clip;
    RefPtr<gui::TimeAxis> m_clipAxis;
    Array<gui::CurveChange> m_clipUndo;
    Array<gui::CurveChange> m_clipRedo;
    // The Toolkit page's node graphs (T6): a dataflow graph and a lamp's state machine, before the GUI
    // too, the format their copies are written in, and the page's history of each one's changes.
    struct GraphHistory
    {
        UniquePtr<gui::GraphSet> Set;
        Array<gui::GraphChange> Undo;
        Array<gui::GraphChange> Redo;
        Function<void()> Changed; // told each change and each step back or on
    };
    GraphHistory m_flow;
    GraphHistory m_states;
    UniquePtr<sandbox::XmlTextFormat> m_graphFormat;
    gui::GraphId m_lampState = 0; // the state machine's active state
    RefPtr<gui::ToastHost> m_toasts; // over the whole window (the Toolkit page posts to it)
    i32 m_cookPercent = 0;           // the Progress toast's
    u32 m_toastsPosted = 0, m_toastsClosed = 0;
    void WireGraph(GraphHistory& graph, gui::Node& section, StringView prefix, Function<void()> changed);
    // The Toolkit page's reflected cameras (T3), their source and its format, and the page's
    // history of the source's changes (each with the cameras it was made on).
    RefPtr<sandbox::CameraRig> m_cameras[2];
    UniquePtr<sandbox::XmlTextFormat> m_cameraFormat;
    UniquePtr<gui::ReflectedPropertySource> m_reflected;
    struct CameraStep
    {
        gui::ReflectedChange Change;
        usize Selection = 0;
    };
    Array<CameraStep> m_cameraUndo;
    Array<CameraStep> m_cameraRedo;
    usize m_cameraSelection = 0;
    gui::Label* m_cameraSaid = nullptr;
    gui::Button* m_cameraUndoButton = nullptr;
    gui::Button* m_cameraRedoButton = nullptr;

    // The texts the Language and direction page shows (E9e), the GUI's localization: before the
    // GUI, which lets go of it when it goes. The narrating bridge likewise.
    foundation::i18n::StringTable m_strings;
    foundation::i18n::Localization m_localization;
    UniquePtr<NarrateBridge> m_narrator;
    void LoadStrings();
    void SetLanguage(StringView locale); // "pseudo": English pseudolocalized
    void SetPageDirection(gui::Node::LayoutDirection direction);

    // === The GUI: one context, two roots ===
    RefPtr<gui::GUIContext> m_gui;
    RefPtr<gui::SceneRoot> m_root;     // the sandbox
    // The game menu: a screen of the sandbox's one root (one root per window), hidden until it
    // opens as a modal layer over the shell, back in its place when it closes.
    RefPtr<gui::Node> m_menu;
    UniquePtr<SandboxResources> m_resources; // pictures by path, from the data folder
    gui::StyleManager* m_styles = nullptr; // the host's: the sandbox's sheet
    // The inspector (E8e): a pane of its own root on the right, Ctrl+Shift+I.
    UniquePtr<gui::inspector::Inspector> m_inspector;
    bool m_inspectorOpen = false;
    bool m_openInspector = false; // --inspector
    // The image tests (E8g).
    static constexpr u32 kImageWidth = 960;
    static constexpr u32 kImageHeight = 720;
    static constexpr i32 kImageFrames = 40; // frames on the fixed clock before a page's picture
    bool m_imageTests = false;
    String m_approve;                       // "" compares; "shared" or "backend" writes references
    String m_imageOut = String(u8"build/gui-images");
    String m_backendName = String(u8"vulkan");
    Array<String> m_imagePages;
    usize m_imagePage = 0;
    i32 m_imageFrame = 0;
    u32 m_imagesDone = 0;
    u32 m_imageFailures = 0;
    void RunImageTests();
    void RunBench();
    String m_benchPage;
    u32 m_benchFrames = 0;
    u32 m_benchFrame = 0;
    struct BenchTotals
    {
        f64 Draw = 0.0, Prepare = 0.0, Gpu = 0.0;
        u64 Vertices = 0, Commands = 0, Drawn = 0, Culled = 0;
        f64 Damaged = 0.0; // the damage's bounds, as a share of the window
    } m_bench;
    String m_inspectSelector;     // --inspect <selector>: selected once the GUI is up
    f32 m_inspectorWidth = 460.0f;  // logical units; the boundary drags it
    bool m_resizingInspector = false; // the boundary is held
    bool m_overInspectorEdge = false; // the pointer is on the boundary (or holds it)
    // The boundary between the root on show and the pane: on it the cursor shows the resize
    // arrows, pressed it drags the pane's width (neither root sees the pointer meanwhile).
    // True while it has the pointer.
    bool ResizeInspector(shell::IInputManager& input);
    // The pointer as the host would give a pane: false when the sandbox takes it first (the
    // inspector picking, the boundary held, a --keys script driving the pointer).
    bool FilterPointer(gui::SceneRoot& pane, shell::InputSurface& surface);
    bool m_showingMenu = false;
    f32 m_menuLeaveAt = -1.0f; // when the game menu's Leave has faded: back to the sandbox

    // The shell and its pages.
    RefPtr<gui::Node> m_shellNode;
    gui::Node* m_header = nullptr;
    gui::Node* m_body = nullptr;
    gui::Node* m_sidebar = nullptr;
    gui::ScrollView* m_content = nullptr;
    gui::Button* m_themeToggle = nullptr;
    struct Page
    {
        String id;
        gui::Node* node = nullptr;      // in the content scroller
        gui::Node* navButton = nullptr; // in the sidebar
        String sheet;                   // its .css, which styles it alone
        RefPtr<script::IScriptContext> script;
    };
    Array<Page> m_pages;
    String m_current;
    bool m_light = false;

    // Scripts: one manager, a context per page that has a script, one for the game menu.
    RefPtr<script::IScriptManager> m_scripts;
    gui::GuiScriptBinding m_sandboxBinding;
    gui::GuiScriptBinding m_menuBinding;
    ScriptErrors m_scriptErrors;
    RefPtr<script::IScriptContext> m_menuScript;
    bool m_menuWantsUpdate = false;
    // The game menu's actions, which its prompts read (K7): a stand-in for a game's input map.
    foundation::input::ActionRuntime m_menuInput;
    gui::InputPrompts m_menuPrompts;

    // What native hosts hold.
    UniquePtr<image::OwnedImageData> m_checker;
    UniquePtr<gui::StringListModel> m_listModel;
    i32 m_insertedRows = 0; // rows the Data views page inserted at the top
    UniquePtr<gui::TableModel> m_tableModel;
    UniquePtr<gui::SortingProxyModel> m_tableProxy;
    UniquePtr<gui::TreeModel> m_treeModel;
    RefPtr<gui::Menu> m_contextMenu;
    RefPtr<gui::Window> m_floating; // the Menus page's floating window
    RefPtr<gui::MessageBox> m_dialog;
};

// === Building ===

void GUISandbox::OnStartup(runtime::IApplicationHost& host)
{
    m_host = &host;
    m_shell = host.Shell();
    m_mainWindow = host.MainRenderWindow();
    if (m_shell == nullptr || m_mainWindow == nullptr || host.Graphics() == nullptr || host.Graphics()->Raw() == nullptr)
    {
        std::fprintf(stderr, "GUISandbox: no window or device\n");
        host.RequestExit(1);
        return;
    }
    m_window = &m_mainWindow->Window();
    m_device = host.Graphics()->Raw();
    m_width = m_window->Width();
    m_height = m_window->Height();
    // The data folder: fonts, pages, pictures, and the VG shaders (cooked, or compiled from Shaders/).
    m_dataRoot = vfs::FindDataRoot();
    if (m_dataRoot.IsEmpty())
    {
        std::fprintf(stderr, "GUISandbox: no data folder\n");
        host.RequestExit(1);
        return;
    }
    m_dataFileSystem = MakeUnique<vfs::NativeFileSystem>(AppRoot(), m_dataRoot.AsView(), AppRoot());
    gui::RegisterGuiElements(); // the GUI's widgets, creatable by tag from markup
    gui::RegisterToolkitElements(); // and the toolkit's
    gui::RegisterCodeElements();    // and the code editor
    gui::RegisterGamekitElements(); // and the gamekit's (the game menu's screens and prompts)
    m_shaders = MakeUnique<gui::VgShaderLibrary>(AppRoot(), AppRoot());
    if (!m_shaders->Load(*m_device, *m_dataFileSystem))
    {
        std::fprintf(stderr, "GUISandbox: the VG shaders did not load\n");
        host.RequestExit(1);
        return;
    }

    // Mixed-direction text reorders by the Unicode bidirectional algorithm (E9c), as Engine.UI's does.
    fonts::BidiAlgorithm::Install();
    // Shaped by HarfBuzz (E9e): Arabic joins its letters. Installed before any font loads, so each
    // one's atlas takes the joined forms its shaping reaches.
    fonts::HarfBuzzShaping::Install();
    m_fontService = MakeUnique<fonts::TrueTypeFontService>(AppRoot(), AppRoot());
    LoadFonts();
    // The window's GUI: its input, its frames, its renderer and the picture baker. The sandbox blends
    // in linear light, as its references were drawn.
    m_guiHost = MakeUnique<gui::GuiHost>(AppRoot(), AppRoot(), *host.Graphics(), *m_shell, m_fontService.Get(), m_shaders->Set());
    m_guiHost->SetBlendSpace(vg::VGBlendSpace::Linear);
    m_styles = &m_guiHost->Styles();
    // The windows the host opens for a root (the Docking page's floats in OS windows) are the
    // runtime host's.
    {
        runtime::IApplicationHost* runtimeHost = &host;
        gui::GuiHost::WindowOpener opener;
        opener.Open = [runtimeHost](const shell::WindowSettings& settings) { return runtimeHost->OpenWindow(settings, graphics::RenderWindowDesc{}); };
        opener.Close = [runtimeHost](graphics::RenderWindow& window) { runtimeHost->CloseWindow(&window); };
        m_guiHost->SetWindowOpener(Move(opener));
    }

#ifdef OPTION_HAS_ANGELSCRIPT
    RegisterCoreTypes();
    gui::RegisterGuiScriptSurface();
    m_scripts = script::angelscript::CreateScriptManager(AppRoot());
    script::RegisterReflectedTypes(*m_scripts);
#else
    std::fprintf(stderr, "GUISandbox: built without AngelScript; the pages' and the game menu's scripts do not run\n");
#endif

    m_gui = m_guiHost->ContextRef();
    // The data the pages and the game menu share.
    gui::DataModel& data = m_gui->GetData();
    data.Set(StringView(u8"volume"), Variant::From<f32>(0.7f));
    data.Set(StringView(u8"music"), Variant::From<bool>(true));
    data.Set(StringView(u8"name"), Variant::From<String>(String(u8"Ada")));
    data.Set(StringView(u8"clicks"), Variant::From<i32>(0));
    data.Set(StringView(u8"cuts"), Variant::From<i32>(0));
    data.Set(StringView(u8"menu"), Variant::From<String>(String(u8"pick an item")));
    data.Set(StringView(u8"status"), Variant::From<String>(String(u8"Loading...")));
    data.Set(StringView(u8"progress"), Variant::From<f32>(0.0f));
    data.Set(StringView(u8"quit"), Variant::From<bool>(false));
    data.Set(StringView(u8"files"), Variant::From<i32>(3)); // the Language page's count
    LoadStrings();
    if (m_narrate)
    {
        m_narrator = MakeUnique<NarrateBridge>(AppRoot(), AppRoot());
        m_gui->SetAccessibilityBridge(m_narrator.Get());
    }

    BuildSandbox();
    BuildMenu();
    if (m_openMenuAtStart)
        OpenMenu();

    // The Viewport page's cube, its pipeline built for the widget's formats.
    if (m_viewport && foundation::shaders::createCompiler(foundation::shaders::CompilerDesc{}, m_cubeCompiler).IsOk() &&
        m_cubeCompiler != nullptr)
        m_cube.Init(m_device, m_cubeCompiler, static_cast<i32>(host.Graphics()->FramesInFlight()), m_viewport->ColorFormat(),
                    m_viewport->DepthFormat());

    // What the sandbox does to the host's input and drawing: the inspector picks and draws over
    // the page, its boundary takes the pointer, a desk test hears of the OS's drops.
    GUISandbox* self = this;
    m_guiHost->SetPointerFilter([self](gui::SceneRoot& pane, shell::InputSurface& surface) { return self->FilterPointer(pane, surface); });
    m_guiHost->SetOverlay(
        [self](graphics::RenderWindow&, gui::DrawContext& context)
        {
            if (!self->m_inspectorOpen)
                return;
            self->m_inspector->RecordFrame(self->m_root->GetLastFrameStats());
            self->m_inspector->DrawOverTarget(context);
            // The boundary, lit while the pointer is on it or drags it.
            if (self->m_overInspectorEdge)
                context.VG().FillRect(Rectangle{static_cast<f32>(self->m_width) - self->InspectorPixels() - 1.0f, 0.0f, 2.0f,
                                                static_cast<f32>(self->m_height)},
                                      Color{0.31f, 0.61f, 1.0f, 1.0f});
        });
    m_guiHost->SetDropObserver(
        [self](const shell::DroppedFile& drop) // said, for a desk test of a desktop's drops
        {
            std::printf("GUISandbox: OS drop on window %u (this %u) at %.0f, %.0f: %s\n", drop.window, self->m_window->Id(), drop.x,
                        drop.y, reinterpret_cast<const char*>(drop.path.CStr()));
        });
    // The image tests and the bench draw the root offscreen; otherwise it is the window's.
    if (DrawsOffscreen())
        m_offscreen = MakeUnique<gui::GuiOffscreen>(AppRoot(), AppRoot(), *m_guiHost, kImageWidth, kImageHeight,
                                                    m_mainWindow->Swap()->Format(), vg::VGBlendSpace::Linear);
    else
    {
        m_guiHost->AttachWindow(*m_mainWindow, m_root);
        if (m_inspectorOpen)
            m_guiHost->AddPane(*m_mainWindow, m_inspector->GetRootRef(), Rectangle{}, &m_inspector->GetStyles());
        Layout();
    }
}

// The Language and direction page's table (E9e): the serialized StringTable in the data folder,
// read through the XML serializer, given to the GUI as its localization in the start language.
void GUISandbox::LoadStrings()
{
    foundation::i18n::RegisterStringTableType();
    const String text = ReadText(kStrings);
    foundation::xml::XmlDocument document(AppRoot());
    if (text.Size() == 0 || document.Parse(text.AsView()) != foundation::xml::XmlResult::Ok)
    {
        std::fprintf(stderr, "GUISandbox: the string table did not load\n");
        return;
    }
    foundation::xml::XmlSerializer reader(document);
    m_strings.Serialize(reader);
    if (!reader.IsPayloadOk())
    {
        std::fprintf(stderr, "GUISandbox: the string table did not read\n");
        return;
    }
    m_localization.AddTable(&m_strings);
    m_gui->SetLocalization(&m_localization);
    SetLanguage(m_startLanguage.AsView());
}

void GUISandbox::SetLanguage(StringView locale)
{
    const bool pseudo = locale == StringView(u8"pseudo");
    foundation::i18n::PseudoOptions options;
    options.Enabled = pseudo;
    // Rich-text tags and bindings stay as they are.
    options.Untouched.PushBack(foundation::i18n::UntouchedSpan{String(u8"["), String(u8"]")});
    options.Untouched.PushBack(foundation::i18n::UntouchedSpan{String(u8"{{"), String(u8"}}")});
    m_localization.SetPseudolocalization(Move(options));
    m_localization.SetLanguage(pseudo ? StringView(u8"en") : locale);
    m_gui->Announce(m_localization.Text(u8"lang.changed"));
}

void GUISandbox::SetPageDirection(gui::Node::LayoutDirection direction)
{
    for (const Page& page : m_pages)
        if (page.id.AsView() == StringView(u8"language"))
            page.node->SetLayoutDirection(direction);
}

void GUISandbox::LoadFonts()
{
    // Roboto in coverage atlases (a size baked on first use), Lilita as one distance-field bake
    // drawn crisp at any size, whose field text effects read (12 texels: effects reach 6 past the
    // edge at the bake size).
    fonts::FontLoadOptions roboto = fonts::FontLoadOptions::ExtendedLatin();
    roboto.pixelHeight = 16.0f;
    roboto.lastCodepoint = 0x17F; // Latin Extended-A too: European languages, and pseudolocalized text
    (void)m_fontService->LoadFont(u8"Roboto", DataPath(kRoboto).AsView(), roboto);
    m_font = m_fontService->GetFont(u8"Roboto", 16.0f);
    fonts::DistanceFieldFonts::Initialize();
    fonts::FontLoadOptions lilita = fonts::FontLoadOptions::DistanceField();
    lilita.pixelHeight = 48.0f;
    lilita.distanceFieldRange = 12.0f;
    if (m_fontService->LoadFont(u8"Lilita", DataPath(kLilita).AsView(), lilita) != fonts::FontLoadResult::Success)
        std::fprintf(stderr, "GUISandbox: the Lilita face did not load\n");
    // DejaVu Sans Mono for Arabic (E9e): Latin, Greek, Cyrillic, Hebrew and Arabic, and the joined
    // forms HarfBuzz reaches from them.
    fonts::FontLoadOptions dejavu = fonts::FontLoadOptions::ExtendedLatin();
    dejavu.pixelHeight = 16.0f;
    dejavu.lastCodepoint = 0x6FF;
    dejavu.atlasWidth = 2048;
    dejavu.atlasHeight = 2048;
    if (m_fontService->LoadFont(u8"DejaVu", DataPath(kDejaVu).AsView(), dejavu) != fonts::FontLoadResult::Success)
        std::fprintf(stderr, "GUISandbox: the DejaVu face did not load\n");
}

// A sheet's @font-face (E11): the file under the data folder, into the font service under the
// face's name, in coverage atlases as Roboto's are.
bool GUISandbox::LoadFontFace(StringView face, StringView source)
{
    fonts::FontLoadOptions options = fonts::FontLoadOptions::ExtendedLatin();
    options.pixelHeight = 16.0f;
    options.lastCodepoint = 0x17F;
    if (m_fontService->LoadFont(face, DataPath(source).AsView(), options) == fonts::FontLoadResult::Success)
        return true;
    std::fprintf(stderr, "GUISandbox: the @font-face %.*s (%.*s) did not load\n", static_cast<int>(face.Size()),
                 reinterpret_cast<const char*>(face.Data()), static_cast<int>(source.Size()), reinterpret_cast<const char*>(source.Data()));
    return false;
}

String GUISandbox::ReadText(StringView relative)
{
    Result<Array<byte>> bytes = ReadFile(DataPath(relative).AsView(), AppRoot());
    if (!bytes.HasValue())
        return {};
    return String(StringView(reinterpret_cast<const utf8char*>(bytes.Value().Data()), bytes.Value().Size()));
}

RefPtr<gui::Node> GUISandbox::LoadMarkup(StringView text)
{
    const gui::ElementSet elements = gui::ElementSet::All();
    gui::MarkupLoader loader(elements, AppRoot(), nullptr, m_fontService.Get());
    loader.SetDataModel(m_gui->GetDataRef());
    return loader.LoadFromString(text);
}

RefPtr<script::IScriptContext> GUISandbox::RunScript(StringView relative, gui::GuiScriptBinding& binding)
{
    if (!m_scripts)
        return {};
    const String source = ReadText(relative);
    if (source.Size() == 0)
        return {};
    RefPtr<script::IScriptContext> context = m_scripts->CreateContext();
    context->SetErrorHandler(&m_scriptErrors);
    gui::InstallGuiScriptService(*context, binding);
    if (!context->Load(source.AsView(), relative).IsOk())
        std::fprintf(stderr, "GUISandbox: %s did not load\n", reinterpret_cast<const char*>(String(relative).CStr()));
    return context;
}

void GUISandbox::BuildSandbox()
{
    m_root = MakeRef<gui::SceneRoot>(AppRoot(), m_gui);
    m_root->SetDisplayScale(m_window != nullptr ? m_window->ContentScale() : 1.0f);
    m_root->SetViewportSize(Float2{static_cast<f32>(m_width), static_cast<f32>(m_height)});
    m_sandboxBinding.root = m_root.Get();

    String path(kSandboxDir);
    path += StringView(u8"shell.xml");
    m_shellNode = LoadMarkup(ReadText(path.AsView()).AsView());
    if (!m_shellNode)
    {
        std::fprintf(stderr, "GUISandbox: the shell did not load\n");
        return;
    }
    m_root->AddChild(m_shellNode.Get());
    m_toasts = MakeRef<gui::ToastHost>(AppRoot());
    m_shellNode->AddChild(m_toasts.Get());
    m_header = FindById(*m_shellNode, u8"header");
    m_body = FindById(*m_shellNode, u8"body");
    m_sidebar = FindById(*m_shellNode, u8"sidebar");
    m_content = Cast<gui::ScrollView>(FindById(*m_shellNode, u8"content"));
    m_themeToggle = Cast<gui::Button>(FindById(*m_shellNode, u8"theme-toggle"));

    LoadPages();
    FillNativeHosts();
    for (const Page& page : m_pages)
        if (page.id.AsView() == StringView(u8"stress"))
        {
            m_stress = MakeUnique<sandbox::StressPage>(AppRoot(), AppRoot(), m_font);
            m_stress->SetLoad(m_stressLoad);
            m_stress->Attach(*page.node);
        }

    // The shell's commands; the sidebar's buttons are bound to page.<id>, the header's to the theme.
    GUISandbox* self = this;
    (void)m_root->OnCommand(u8"theme.toggle", [self](gui::CommandEvent&) { self->ToggleTheme(); });
    (void)m_root->OnCommand(u8"demo.window", [self](gui::CommandEvent&) { self->OpenWindow(); });
    (void)m_root->OnCommand(u8"demo.message", [self](gui::CommandEvent&) { self->ShowMessage(); });
    (void)m_root->OnCommand(u8"showcase.open", [self](gui::CommandEvent&) { self->OpenMenu(); });
    (void)m_root->OnCommand(u8"debug.layout", [self](gui::CommandEvent&) { self->m_layoutOverlay = !self->m_layoutOverlay; self->ApplyDebugOverlay(); });
    (void)m_root->OnCommand(u8"debug.input", [self](gui::CommandEvent&) { self->m_inputOverlay = !self->m_inputOverlay; self->ApplyDebugOverlay(); });
    (void)m_gui->GetKeymap().Bind(u8"f9", u8"debug.layout");
    (void)m_gui->GetKeymap().Bind(u8"f8", u8"debug.input");
    (void)m_root->OnCommand(u8"inspector.toggle", [self](gui::CommandEvent&) { self->ToggleInspector(); });
    // The Language and direction page's (E9e).
    (void)m_root->OnCommand(u8"lang.en", [self](gui::CommandEvent&) { self->SetLanguage(u8"en"); });
    (void)m_root->OnCommand(u8"lang.pseudo", [self](gui::CommandEvent&) { self->SetLanguage(u8"pseudo"); });
    (void)m_root->OnCommand(u8"lang.ar", [self](gui::CommandEvent&) { self->SetLanguage(u8"ar"); });
    (void)m_root->OnCommand(u8"dir.language", [self](gui::CommandEvent&) { self->SetPageDirection(gui::Node::LayoutDirection::Inherit); });
    (void)m_root->OnCommand(u8"dir.ltr", [self](gui::CommandEvent&) { self->SetPageDirection(gui::Node::LayoutDirection::LeftToRight); });
    (void)m_root->OnCommand(u8"dir.rtl", [self](gui::CommandEvent&) { self->SetPageDirection(gui::Node::LayoutDirection::RightToLeft); });
    const auto count = [self](i32 by)
    {
        gui::DataModel& data = self->m_gui->GetData();
        const Variant now = data.Get(StringView(u8"files"));
        const i32 files = now.TryGet<i32>() != nullptr ? *now.TryGet<i32>() : 0;
        data.Set(StringView(u8"files"), Variant::From<i32>(Max(0, files + by)));
    };
    (void)m_root->OnCommand(u8"files.more", [count](gui::CommandEvent&) { count(1); });
    (void)m_root->OnCommand(u8"files.fewer", [count](gui::CommandEvent&) { count(-1); });
    (void)m_gui->GetKeymap().Bind(u8"ctrl-shift-i", u8"inspector.toggle");
    gui::BindCodeEditorKeys(m_gui->GetKeymap()); // the Code page's editors: VS Code's keys (C8)
    m_root->SetDebugFont(m_font);
    ApplyDebugOverlay();

    GUISandbox* app = this;
    m_styles->SetFontService(m_fontService.Get());
    m_styles->SetFontFaceLoader([app](StringView face, StringView source) { return app->LoadFontFace(face, source); });
    m_gui->SetFontService(m_fontService.Get()); // a rich text's own faces
    m_resources = MakeUnique<SandboxResources>(AppRoot(), [app](StringView path) { return app->DataPath(path); });
    m_styles->SetResourceProvider(m_resources.Get());
    m_gui->SetResourceProvider(m_resources.Get());
    ApplySandboxSheet();
    if (m_lightAtStart)
        ToggleTheme();
    ShowPage(m_startPage.AsView());

    if (m_openInspector)
        ToggleInspector();
    m_root->GetEventDispatcher()->SetTooltipDelay(0.4f); // tooltips are the GUI's own (E5)
}

void GUISandbox::LoadPages()
{
    // The pages are what the sidebar names: each button bound to page.<id>.
    Array<gui::Node*> buttons;
    if (m_sidebar != nullptr)
        CollectCommands(*m_sidebar, kPageCommand, buttons);
    GUISandbox* self = this;
    for (gui::Node* button : buttons)
    {
        Page page;
        page.id = String(button->GetCommand().SubStr(kPageCommand.Size(), button->GetCommand().Size() - kPageCommand.Size()));
        page.navButton = button;
        String base(kSandboxDir);
        base += StringView(u8"pages/");
        base += page.id.AsView();
        String xml = base;
        xml += StringView(u8".xml");
        RefPtr<gui::Node> node = LoadMarkup(ReadText(xml.AsView()).AsView());
        if (!node)
        {
            std::fprintf(stderr, "GUISandbox: page %s did not load\n", reinterpret_cast<const char*>(xml.CStr()));
            continue;
        }
        node->SetDisplayed(false); // out of the layout until shown
        m_content->AddChild(node.Get());
        page.node = node.Get();
        String css = base;
        css += StringView(u8".css");
        page.sheet = ReadText(css.AsView());
        if (page.id.AsView() == StringView(u8"stress"))
            page.sheet += sandbox::StressPage::Rules(1000).AsView(); // a large sheet's many rules
        const String id = page.id;
        String command(kPageCommand);
        command += id.AsView();
        (void)m_root->OnCommand(command.AsView(), [self, id](gui::CommandEvent&) { self->ShowPage(id.AsView()); });
        m_pages.PushBack(Move(page));
    }
    // Their scripts, once every page is in the tree (a script may reach another page's widgets).
    for (Page& page : m_pages)
    {
        String as(kSandboxDir);
        as += StringView(u8"pages/");
        as += page.id.AsView();
        as += StringView(u8".as");
        if (FileExists(DataPath(as.AsView()).AsView()))
            page.script = RunScript(as.AsView(), m_sandboxBinding);
    }
}

void GUISandbox::FillNativeHosts()
{
    // Controls: a generated image.
    if (gui::Node* host = FindById(*m_shellNode, u8"controls-image"))
    {
        static u8 pixels[16 * 16 * 4];
        for (i32 y = 0; y < 16; ++y)
            for (i32 x = 0; x < 16; ++x)
            {
                const usize o = static_cast<usize>((y * 16 + x) * 4);
                const bool checker = ((x / 4) + (y / 4)) % 2 == 0;
                pixels[o + 0] = static_cast<u8>(checker ? 40 + x * 12 : 20);
                pixels[o + 1] = static_cast<u8>(checker ? 90 : 40 + y * 12);
                pixels[o + 2] = static_cast<u8>(checker ? 160 : 80);
                pixels[o + 3] = 255;
            }
        m_checker = MakeUnique<image::OwnedImageData>(AppRoot(), 16, 16, image::PixelFormat::RGBA8, Span<const u8>(pixels, sizeof(pixels)));
        auto view = MakeRef<gui::Image>(AppRoot());
        view->SetSize(host->GetSize().x > 0.0f ? host->GetSize() : Float2{160.0f, 160.0f});
        view->SetDrawable(MakeRef<gui::ImageDrawable>(AppRoot(), m_checker.Get()));
        view->SetFit(gui::ObjectFit::Contain);
        view->SetTooltip(u8"An Image from code: a generated picture, object-fit: contain");
        host->AddChild(view.Get());
    }

    // Docking: a dock space over a controller (D3, D4).
    if (gui::Node* host = FindById(*m_shellNode, u8"docking-host"))
        FillDocking(*host);
    // Toolkit: the tool bars' commands, their keys and the status bar's messages (T0).
    if (gui::Node* frame = FindById(*m_shellNode, u8"toolkit-frame"))
        FillToolkit(*frame);
    // Toolkit: the property grid over three lamps (T1).
    if (auto* grid = Cast<gui::PropertyGrid>(FindById(*m_shellNode, u8"props-grid")))
        FillProperties(*grid);
    // Toolkit: a reflected object's grid (T3).
    if (auto* grid = Cast<gui::PropertyGrid>(FindById(*m_shellNode, u8"reflected-grid")))
        FillReflected(*grid);
    // Toolkit: a clip of the lamps' values in a dopesheet and a curve view (T5), after the lamps.
    if (gui::Node* section = FindById(*m_shellNode, u8"clip-section"))
        FillClip(*section);
    // Toolkit: a dataflow graph and a lamp's state machine (T6), after the clip.
    if (gui::Node* section = FindById(*m_shellNode, u8"graph-section"))
        FillGraphs(*section);
    // Code: a script checked as it is typed and a shader, in the sandbox's languages (C8).
    if (auto* editor = Cast<gui::CodeEditor>(FindById(*m_shellNode, u8"code-script")))
    {
        const String dir = Format(u8"{}code/", kSandboxDir);
        m_code = MakeUnique<sandbox::CodePage>(AppRoot(), AppRoot(), m_scripts.Get());
        m_code->AttachScript(*editor, ReadText(Format(u8"{}angelscript.xml", dir).AsView()).AsView(),
                             ReadText(Format(u8"{}sample.as", dir).AsView()).AsView(),
                             Cast<gui::Label>(FindById(*m_shellNode, u8"code-status")));
        if (auto* shader = Cast<gui::CodeEditor>(FindById(*m_shellNode, u8"code-shader")))
            m_code->AttachShader(*shader, ReadText(Format(u8"{}hlsl.xml", dir).AsView()).AsView(),
                                 ReadText(Format(u8"{}sample.hlsl", dir).AsView()).AsView());
    }
    if (gui::Node* section = FindById(*m_shellNode, u8"crumbs-section"))
        FillCrumbs(*section);
    if (gui::Node* section = FindById(*m_shellNode, u8"toasts-section"))
        FillToasts(*section);

    // Viewport: a cube drawn into the widget's targets, under the page's note (V2).
    if (gui::Node* host = FindById(*m_shellNode, u8"viewport-host"))
    {
        m_viewport = MakeRef<gui::Viewport>(AppRoot());
        m_viewport->AddClass(u8"viewport-scene");
        (void)host->AddChildAt(m_viewport.Get(), 0); // under the note
        m_viewport->HostIn(*m_guiHost);
        GUISandbox* self = this;
        m_viewport->OnRender = [self](gui::Viewport& viewport, rhi::CommandEncoder& encoder, i32 frameIndex)
        {
            const u32 width = viewport.RenderWidth(), height = viewport.RenderHeight();
            const f32 aspect = static_cast<f32>(width) / static_cast<f32>(Max(height, 1u));
            const Float4x4 projection = Float4x4::PerspectiveFovRH(1.0f, aspect, 0.1f, 100.0f);
            const samples::FlyCamera& camera = self->m_camera;
            const Float4x4 view = Float4x4::LookAtRH(camera.position, camera.position + camera.Forward(), camera.Up());
            const Float4x4 model = Float4x4::RotationY(self->m_spin) * Float4x4::RotationX(self->m_spin * 0.5f);
            self->m_cube.Render(encoder, viewport.ColorView(), viewport.DepthView(), width, height, viewport.LinearClearColor(),
                                model * view * projection, frameIndex); // row vectors: v * M * V * P
        };
        (void)m_root->OnCommand(u8"viewport.reset", [self](gui::CommandEvent&) { self->ResetCamera(); });
        (void)m_root->OnCommand(u8"viewport.fit",
                                [self](gui::CommandEvent&)
                                {
                                    // A fixed 16:9 picture letterboxed in the widget, or the widget's own pixels.
                                    const bool fixed = self->m_viewport->GetFitMode() != FitMode::Letterbox;
                                    self->m_viewport->SetFixedResolution(fixed ? 1280u : 0u, fixed ? 720u : 0u);
                                    self->m_viewport->SetFitMode(fixed ? FitMode::Letterbox : FitMode::Stretch);
                                    if (auto* button = Cast<gui::Button>(FindById(*self->m_shellNode, u8"viewport-fit")))
                                        button->SetText(fixed ? u8"Follow the widget" : u8"Letterbox at 16:9");
                                });
        ResetCamera();
    }

    // Data views over native models.
    // Drag and drop (E7): the cards are sources, the bins targets; the hand takes cards, the
    // discard pile refuses aces with a reason; the chip goes nowhere.
    {
        auto* said = Cast<gui::Label>(FindById(*m_shellNode, u8"dnd-said"));
        const char8_t* cards[3] = {u8"dnd-ace", u8"dnd-king", u8"dnd-chip"};
        for (const char8_t* id : cards)
            if (gui::Node* card = FindById(*m_shellNode, id))
            {
                const bool chip = StringView(id) == StringView(u8"dnd-chip");
                card->SetTabFocusable(true); // Ctrl+Shift+D or the pad's North picks it up
                gui::Label* label = Cast<gui::Label>(card);
                card->SetDragSource([label, chip](gui::DragRequest& r)
                {
                    r.Payload.Type = String(chip ? u8"chip" : u8"card");
                    r.Payload.Label = String(label != nullptr ? label->GetText() : StringView{});
                    r.Payload.Value = Variant::From<String>(r.Payload.Label);
                    return true;
                });
                card->SetOnDragEnd([said, label](const gui::DragResult& r)
                {
                    if (label == nullptr)
                        return;
                    // The card goes where it was dropped (a move), or a copy of it does.
                    if (r.Target != nullptr && r.Effect == gui::DropEffect::Move)
                        r.Target->GetChildHost()->AddChild(label);
                    else if (r.Target != nullptr && r.Effect == gui::DropEffect::Copy)
                    {
                        auto copy = MakeRef<gui::Label>(AppRoot());
                        copy->SetText(label->GetText());
                        copy->AddClass(u8"dnd-card");
                        r.Target->GetChildHost()->AddChild(copy.Get());
                    }
                    if (said == nullptr)
                        return;
                    const char8_t* how = r.Cancelled ? u8"cancelled" : r.Effect == gui::DropEffect::Copy ? u8"copied" : r.Effect == gui::DropEffect::Move ? u8"moved" : r.Effect == gui::DropEffect::Link ? u8"linked" : u8"dropped nowhere";
                    said->SetText(Format(u8"{}: {}", label->GetText(), how).AsView());
                });
            }
        const char8_t* targets[3] = {u8"dnd-hand", u8"dnd-discard", u8"dnd-files"};
        for (const char8_t* id : targets)
            if (gui::Node* target = FindById(*m_shellNode, id))
                target->SetTabFocusable(true); // a keyboard drag goes where the focus goes
        if (gui::Node* hand = FindById(*m_shellNode, u8"dnd-hand"))
            hand->SetOnDragQuery([](gui::DropQuery& q)
            {
                if (q.Payload.Type.AsView() != StringView(u8"card"))
                    return;
                q.Accept();
                q.Reason = Format(u8"{} it to the hand", q.Effect == gui::DropEffect::Copy ? u8"Copy" : u8"Move");
            });
        // Files from the OS: the files pile takes them; dropped anywhere else, the GUI's own
        // handler says so.
        if (gui::Node* files = FindById(*m_shellNode, u8"dnd-files"))
        {
            files->SetDropTypes(String(u8"files"));
            (void)files->AddEventListener(gui::EventType::Drop, [said](const gui::Event& e)
            {
                const Array<String> paths = gui::DroppedPaths(static_cast<const gui::DragEvent&>(e).Payload);
                if (said != nullptr && !paths.IsEmpty())
                    said->SetText(Format(u8"Dropped {} file(s), the first {}", paths.Size(), paths[0]).AsView());
            });
        }
        m_root->GetEventDispatcher()->SetOnFileDrop([said](const Array<String>& paths, Float2)
        {
            if (said != nullptr)
                said->SetText(Format(u8"{} file(s) dropped where nothing takes them", paths.Size()).AsView());
            return true;
        });
        const char8_t* piles[2] = {u8"dnd-long", u8"dnd-hidden"};
        for (const char8_t* id : piles)
            if (gui::Node* pile = FindById(*m_shellNode, id))
                pile->SetDropTypes(String(u8"card"));
        if (gui::Node* discard = FindById(*m_shellNode, u8"dnd-discard"))
            discard->SetOnDragQuery([](gui::DropQuery& q)
            {
                if (q.Payload.Type.AsView() != StringView(u8"card"))
                    return;
                if (q.Payload.Label.AsView().Size() >= 3 && q.Payload.Label.AsView().SubStr(0, 3) == StringView(u8"Ace"))
                    q.Refuse(u8"The discard pile takes no aces");
                else
                {
                    q.Accept(gui::DropEffect::Move);
                    q.Reason = String(u8"Discard it");
                }
            });
    }

    if (gui::Node* host = FindById(*m_shellNode, u8"views-list"))
    {
        m_listModel = MakeUnique<gui::StringListModel>(AppRoot());
        Array<String> rows;
        for (i32 i = 0; i < 500; ++i)
            rows.PushBack(Format(u8"Row {}", i));
        m_listModel->SetItems(Move(rows));
        auto list = MakeRef<gui::ListView>(AppRoot());
        list->SetSize(Float2{320.0f, 180.0f});
        list->SetFont(m_font);
        list->SetRowHeight(24.0f);
        list->SetModel(m_listModel.Get());
        m_listModel->SetEditable(true); // F2 renames a row
        list->SetDragType(String(u8"row")); // rows drag to reorder (E7)
        auto* picked = Cast<gui::Label>(FindById(*m_shellNode, u8"views-picked"));
        gui::StringListModel* model = m_listModel.Get();
        list->SetOnSelectionChanged(
            [picked, model](gui::ModelIndex index)
            {
                if (picked != nullptr && index.IsValid())
                    picked->SetText(Format(u8"picked: {}", model->ItemAt(static_cast<usize>(index.Row))).AsView());
            });
        list->SetOnActivated(
            [picked, model](gui::ModelIndex index)
            {
                if (picked != nullptr && index.IsValid())
                    picked->SetText(Format(u8"activated: {}", model->ItemAt(static_cast<usize>(index.Row))).AsView());
            });
        host->AddChild(list.Get());
        if (auto* insert = Cast<gui::Button>(FindById(*m_shellNode, u8"views-insert")))
        {
            i32* inserted = &m_insertedRows;
            insert->SetOnClick([model, inserted]() { model->InsertItem(0, Format(u8"Inserted {}", ++*inserted).AsView()); });
        }
    }
    if (gui::Node* host = FindById(*m_shellNode, u8"views-table"))
    {
        m_tableModel = MakeUnique<gui::TableModel>(AppRoot());
        Array<String> columns;
        columns.PushBack(String(u8"Name"));
        columns.PushBack(String(u8"Score"));
        m_tableModel->SetColumns(Move(columns));
        const char8_t* names[6] = {u8"Ivy", u8"Cara", u8"Bo", u8"Ada", u8"Eve", u8"Dan"};
        const i32 scores[6] = {42, 7, 91, 15, 68, 30};
        for (usize i = 0; i < 6; ++i)
        {
            Array<gui::Variant> cells;
            cells.PushBack(gui::Variant(StringView(names[i])));
            cells.PushBack(gui::Variant(static_cast<i64>(scores[i])));
            m_tableModel->AddRow(Move(cells));
        }
        m_tableModel->SetEditable(true); // F2 edits a name
        m_tableProxy = MakeUnique<gui::SortingProxyModel>(AppRoot(), m_tableModel.Get());
        auto table = MakeRef<gui::TableView>(AppRoot());
        table->SetSize(Float2{320.0f, 180.0f});
        table->SetFont(m_font);
        table->SetRowHeight(24.0f);
        table->SetModel(m_tableProxy.Get()); // a header click sorts through the proxy (the model's sort capability)
        table->SetColumnWidthsText(String(u8"60% auto"));
        host->AddChild(table.Get());
    }
    if (gui::Node* host = FindById(*m_shellNode, u8"views-tree"))
    {
        m_treeModel = MakeUnique<gui::TreeModel>(AppRoot());
        const i32 code = m_treeModel->AddNode(gui::TreeModel::kRoot, u8"Code");
        const i32 experimental = m_treeModel->AddNode(code, u8"Experimental");
        m_treeModel->AddNode(experimental, u8"GUI");
        m_treeModel->AddNode(experimental, u8"GUI.Sandbox");
        const i32 foundation = m_treeModel->AddNode(code, u8"Foundation");
        m_treeModel->AddNode(foundation, u8"VG");
        m_treeModel->AddNode(foundation, u8"Script");
        const i32 data = m_treeModel->AddNode(gui::TreeModel::kRoot, u8"Data");
        m_treeModel->AddNode(data, u8"Assets");
        auto tree = MakeRef<gui::TreeView>(AppRoot());
        tree->SetSize(Float2{320.0f, 180.0f});
        tree->SetFont(m_font);
        tree->SetRowHeight(24.0f);
        tree->SetModel(m_treeModel.Get());
        tree->SetDragType(String(u8"node")); // nodes drag onto and beside others (E7)
        tree->ExpandItem(0);
        host->AddChild(tree.Get());
    }

    // Menus: a menu bar and a context menu, each saying what was picked through the data.
    RefPtr<gui::DataModel> data = m_gui->GetDataRef();
    const auto said = [data](const char8_t* what) { return [data, what]() { data->Set(u8"menu", Variant::From<String>(String(what))); }; };
    if (gui::Node* host = FindById(*m_shellNode, u8"menus-bar"))
    {
        auto bar = MakeRef<gui::MenuBar>(AppRoot());
        bar->SetSize(Float2{590.0f, 28.0f});
        bar->SetFont(m_font);
        gui::Menu* file = bar->AddMenu(u8"File");
        file->AddItem(u8"New", said(u8"File > New"));
        file->AddItem(u8"Open...", said(u8"File > Open"));
        file->AddSeparator();
        file->AddItem(u8"Close", said(u8"File > Close"));
        gui::Menu* edit = bar->AddMenu(u8"Edit");
        edit->AddItem(u8"Undo", said(u8"Edit > Undo"))->SetShortcut(u8"Ctrl+Z");
        edit->AddItem(u8"Redo", said(u8"Edit > Redo"))->SetShortcut(u8"Ctrl+Y");
        gui::Menu* insert = edit->AddSubMenu(u8"Insert");
        insert->AddItem(u8"Image", said(u8"Edit > Insert > Image"));
        insert->AddItem(u8"Table", said(u8"Edit > Insert > Table"));
        gui::Menu* view = bar->AddMenu(u8"View");
        view->AddCheckItem(u8"Show grid", true,
                           [data](bool on) { data->Set(u8"menu", Variant::From<String>(String(on ? u8"grid on" : u8"grid off"))); });
        host->AddChild(bar.Get());
    }
    if (gui::Node* area = FindById(*m_shellNode, u8"menus-context"))
    {
        for (usize i = 0; i < area->ChildCount(); ++i)
            area->GetChildAt(i)->SetHitTestVisible(false); // the hint lets the click reach the box
        m_contextMenu = MakeRef<gui::Menu>(AppRoot());
        m_contextMenu->SetFont(m_font);
        m_contextMenu->SetWidth(200.0f);
        m_contextMenu->AddItem(u8"Cut", said(u8"context > Cut"))->SetShortcut(u8"Ctrl+X");
        m_contextMenu->AddItem(u8"Copy", said(u8"context > Copy"))->SetShortcut(u8"Ctrl+C");
        m_contextMenu->AddSeparator();
        gui::Menu* more = m_contextMenu->AddSubMenu(u8"More");
        more->SetFont(m_font);
        more->SetWidth(140.0f);
        more->AddItem(u8"Rename", said(u8"context > More > Rename"));
        gui::Menu* menu = m_contextMenu.Get();
        // A right release, a long press or Shift+F10 asks for it (E5).
        area->AddEventListener(gui::EventType::ContextMenu,
                               [menu, area](const gui::Event& e)
                               {
                                   const auto& mouse = static_cast<const gui::MouseEvent&>(e);
                                   e.Handled = true;
                                   menu->Open(*area, area->GetRootNode()->ConvertToNodeSpace(mouse.Position));
                               });
    }
}

void GUISandbox::ApplySandboxSheet()
{
    // The built-in theme for the widgets (the user agent's), the sandbox's look over it, and each
    // page's own sheet over that, styling its page alone.
    const String theme = Format(u8"{}\n{}\n{}\n{}", gui::DefaultThemeCSS(), gui::DockingSheetCSS(), gui::ToolkitSheetCSS(),
                                gui::CodeSheetCSS()); // the satellites' over the widgets'
    m_styles->SetUserAgentSheet(gui::CSSParser::Parse(theme.AsView(), StringView(u8"theme")));
    String path(kSandboxDir);
    path += StringView(u8"sandbox.css");
    m_styles->SetStyleSheet(gui::CSSParser::Parse(ReadText(path.AsView()).AsView(), path.AsView()));
    for (const Page& page : m_pages)
        if (page.node != nullptr)
            (void)m_styles->SetSubtreeSheet(*page.node, gui::CSSParser::Parse(page.sheet.AsView(), Format(u8"pages/{}.css", page.id).AsView()));
}

void GUISandbox::ApplyDebugOverlay()
{
    gui::DebugOverlay overlay = m_layoutOverlay ? gui::DebugOverlay::Layout() : gui::DebugOverlay{};
    if (m_inputOverlay)
    {
        const gui::DebugOverlay input = gui::DebugOverlay::Input();
        overlay.FocusPath = input.FocusPath;
        overlay.TabOrder = input.TabOrder;
        overlay.Navigation = input.Navigation;
        overlay.Pointer = input.Pointer;
        overlay.RedrawFlash = input.RedrawFlash;
    }
    if (m_root)
        m_root->SetDebugOverlay(overlay);
}

bool GUISandbox::ResizeInspector(shell::IInputManager& input)
{
    if (!m_inspectorOpen || input.Mouse() == nullptr)
    {
        m_resizingInspector = m_overInspectorEdge = false;
        return false;
    }
    shell::IMouse& mouse = *input.Mouse(); // the window's, in its pixels
    const f32 scale = m_window != nullptr ? m_window->ContentScale() : 1.0f;
    const f32 edge = static_cast<f32>(m_width) - InspectorPixels();
    const bool near = Abs(mouse.X() - edge) <= 4.0f * scale && mouse.Y() >= 0.0f && mouse.Y() < static_cast<f32>(m_height);
    if (!m_resizingInspector && near && mouse.IsButtonPressed(shell::MouseButton::Left))
        m_resizingInspector = true;
    if (m_resizingInspector)
    {
        if (!mouse.IsButtonDown(shell::MouseButton::Left))
            m_resizingInspector = false;
        else
        {
            // The pane's width follows the pointer, leaving the root on show some room.
            const f32 widest = Max(260.0f, static_cast<f32>(m_width) / scale - 240.0f);
            m_inspectorWidth = Clamp((static_cast<f32>(m_width) - mouse.X()) / scale, 260.0f, widest);
        }
    }
    const bool over = m_resizingInspector || near;
    if (over != m_overInspectorEdge)
    {
        m_overInspectorEdge = over;
        m_root->Invalidate(); // the boundary's highlight
        if (!over)
            m_guiHost->ResetCursors(); // the GUI's cursors take the pointer back
    }
    if (over)
        mouse.SetCursor(shell::CursorType::ResizeEW);
    return m_resizingInspector;
}

void GUISandbox::ToggleInspector()
{
    if (!m_inspector)
        m_inspector = MakeUnique<gui::inspector::Inspector>(AppRoot(), AppRoot(), m_gui, m_fontService.Get());
    m_inspectorOpen = !m_inspectorOpen;
    if (m_inspectorOpen)
        m_inspector->Inspect(m_root.Get(), m_styles);
    else
        m_inspector->SetPicking(false);
    // A pane of the window at the right (once the window has the root: at start, OnStartup adds it).
    if (m_guiHost && m_guiHost->WindowFor(m_root.Get()) != nullptr)
    {
        if (m_inspectorOpen)
            m_guiHost->AddPane(*m_mainWindow, m_inspector->GetRootRef(), Rectangle{}, &m_inspector->GetStyles());
        else
            m_guiHost->RemovePane(m_inspector->GetRoot());
        Layout();
    }
    m_root->Invalidate();
}

void GUISandbox::BuildMenu()
{
    m_menuBinding.root = m_root.Get(); // its script finds its widgets in the one root
    String path(kMenuDir);
    path += StringView(u8"menu.xml");
    RefPtr<gui::Node> menu = LoadMarkup(ReadText(path.AsView()).AsView());
    if (!menu)
    {
        std::fprintf(stderr, "GUISandbox: the game menu did not load\n");
        return;
    }
    // Over the shell, last of the root's children; not shown until it opens. Its sheet styles it
    // alone, as a page's does.
    menu->SetDisplayed(false);
    m_root->AddChild(menu.Get());
    m_menu = menu;
    String css(kMenuDir);
    css += StringView(u8"menu.css");
    (void)m_styles->SetSubtreeSheet(*menu, gui::CSSParser::Parse(ReadText(css.AsView()).AsView(), css.AsView()));
    // Leave: the menu fades out, then the sandbox comes back.
    RefPtr<gui::DataModel> model = m_gui->GetDataRef();
    menu->Bind([this, model]()
               {
                   const Variant quit = gui::ConvertVariant(model->Get(u8"quit"), TypeOf<bool>());
                   if (!quit.IsEmpty() && quit.Get<bool>() && m_menuLeaveAt < 0.0f)
                       m_menuLeaveAt = m_totalTime + 0.7f;
               });
    // Its actions, as a game's input map would give them: its prompts show their controls for the
    // device in hand (K6).
    foundation::input::InputMap actions;
    foundation::input::ActionSet game;
    game.name = String(u8"Game");
    foundation::input::Action pause;
    pause.name = String(u8"pause");
    foundation::input::Binding escape;
    escape.source = foundation::input::BindingSource::Key;
    escape.code = static_cast<u32>(shell::KeyCode::Escape);
    pause.bindings.PushBack(escape);
    foundation::input::Binding start;
    start.source = foundation::input::BindingSource::GamepadButton;
    start.code = static_cast<u32>(shell::GamepadButton::Start);
    pause.bindings.PushBack(start);
    game.actions.PushBack(Move(pause));
    actions.sets.PushBack(Move(game));
    m_menuInput.SetMap(actions);
    m_menuPrompts.SetRuntime(&m_menuInput);
    m_menuPrompts.Install(*m_gui);
    String as(kMenuDir);
    as += StringView(u8"menu.as");
    m_menuScript = RunScript(as.AsView(), m_menuBinding);
}

// === Running ===

void GUISandbox::ShowPage(StringView id)
{
    for (Page& page : m_pages)
    {
        const bool shown = page.id.AsView() == id;
        page.node->SetDisplayed(shown);
        if (auto* button = Cast<gui::UIWidget>(page.navButton))
        {
            if (shown)
                button->AddClass(u8"current");
            else
                button->RemoveClass(u8"current");
        }
    }
    m_current = String(id);
    if (m_stress && id == StringView(u8"stress") && !m_stress->IsBuilt())
        m_stress->Build(m_stressLoad); // built when first shown: the other pages start fast
    if (m_content != nullptr)
    {
        m_content->SetScrollOffset(Float2{0.0f, 0.0f});
    }
}

void GUISandbox::ToggleTheme()
{
    m_light = !m_light;
    if (auto* shellWidget = Cast<gui::UIWidget>(m_shellNode.Get()))
    {
        if (m_light)
            shellWidget->AddClass(u8"light");
        else
            shellWidget->RemoveClass(u8"light");
    }
    if (m_themeToggle != nullptr)
        m_themeToggle->SetText(m_light ? StringView(u8"Dark theme") : StringView(u8"Light theme"));
    // The theme's light tokens come from its own media query (E13): the GUI says the user's scheme.
    m_gui->SetColorScheme(!m_light);
}

void GUISandbox::OpenWindow()
{
    if (!m_floating)
    {
        // A window to drag by its title and resize from its corner, holding tabs.
        m_floating = MakeRef<gui::Window>(AppRoot());
        m_floating->SetSize(Float2{340.0f, 280.0f});
        m_floating->SetTitle(u8"A floating window");
        m_floating->SetFont(m_font);
        auto tabs = MakeRef<gui::TabView>(AppRoot());
        tabs->SetFont(m_font);
        tabs->EditLayoutStyle([](gui::LayoutStyle& s) { s.Grow = 1.0f; });
        m_floating->GetContent()->AddChild(tabs.Get());
        const char8_t* names[3] = {u8"First", u8"Second", u8"Third"};
        const char8_t* bodies[3] = {u8"Tabs switch the page below them.", u8"Drag the title bar to move the window.",
                                    u8"Drag the bottom-right corner to resize it."};
        for (usize i = 0; i < 3; ++i)
        {
            gui::TabPage* page = tabs->AddPage(StringView(names[i]));
            auto body = MakeRef<gui::Label>(AppRoot());
            body->SetPadding(gui::Thickness{12.0f});
            body->SetFont(m_font);
            body->SetWhiteSpace(gui::TextWhiteSpace::Normal);
            body->SetText(StringView(bodies[i]));
            body->AddClass(u8"text");
            page->AddChild(body.Get());
        }
    }
    // The button toggles it, opening it in the middle each time; closed (its close button, or this),
    // it opens there again.
    if (m_floating->GetParent() != nullptr)
        m_floating->Close();
    else
        m_floating->Open(*m_root.Get());
}

void GUISandbox::ShowMessage()
{
    if (!m_dialog)
    {
        m_dialog = MakeRef<gui::MessageBox>(AppRoot());
        m_dialog->SetFont(m_font);
    }
    m_dialog->Configure(u8"A message box", u8"A modal dialog: the page behind it takes no clicks until it is answered.",
                        gui::MessageBox::Buttons::Ok);
    m_dialog->OpenModal(*m_root.Get());
}

void GUISandbox::OpenMenu()
{
    if (!m_menu || m_showingMenu)
        return;
    m_showingMenu = true;
    m_menuLeaveAt = -1.0f;
    m_gui->GetData().Set(u8"quit", Variant::From<bool>(false));
    // A modal layer over the shell: drawn over it, the shell inert below it, the focus inside it
    // and given back on close; Escape is its own (a manual layer: nothing closes it but it).
    m_menu->SetDisplayed(true);
    gui::PopupOptions options;
    options.Kind = gui::PopupKind::Manual;
    options.Modal = true;
    options.TakesFocus = true;
    options.ReturnHome = true; // back in its place when it closes, to open again
    m_root->GetEventDispatcher()->OpenPopup(*m_root, *m_menu, Move(options));
    if (m_menuScript && m_menuScript->HasFunction(u8"enter"))
        (void)m_menuScript->Call(u8"enter", Span<Variant>{});
    m_menuWantsUpdate = true;
}

void GUISandbox::CloseMenu()
{
    if (!m_showingMenu)
        return;
    m_showingMenu = false;
    m_menuLeaveAt = -1.0f;
    m_gui->GetData().Set(u8"quit", Variant::From<bool>(false));
    (void)m_root->GetEventDispatcher()->ClosePopup(*m_menu);
    m_menu->SetDisplayed(false);
    if (gui::Node* back = FindById(*m_shellNode, u8"nav-game-menu"))
        (void)back->FocusElement(); // where the player left from
}

void GUISandbox::LayOutShell()
{
    // The shell fills the window: the header across the top, the sidebar down the left, the page's
    // scroller the rest; the game menu's layers fill it too.
    const Float2 size = m_root->GetSize();
    if (m_shellNode)
        m_shellNode->SetSize(size);
    if (m_header != nullptr)
        m_header->SetSize(Float2{size.x, kHeaderHeight});
    const Float2 body{size.x, Max(0.0f, size.y - kHeaderHeight)};
    if (m_body != nullptr)
        m_body->SetSize(body);
    if (m_sidebar != nullptr)
        m_sidebar->SetSize(Float2{kSidebarWidth, body.y});
    if (m_content != nullptr)
        m_content->SetSize(Float2{Max(0.0f, body.x - kSidebarWidth), body.y});
    if (m_menu)
    {
        m_menu->SetPosition(Float2{0.0f, 0.0f});
        m_menu->SetSize(size);
        for (usize i = 0; i < m_menu->ChildCount(); ++i)
            m_menu->GetChildAt(i)->SetSize(size);
    }
}

// The panes' regions in the window: the root on show, and the inspector's pane at its right.
void GUISandbox::Layout()
{
    if (!m_guiHost || m_guiHost->WindowFor(m_root.Get()) == nullptr)
        return;
    const f32 pane = InspectorPixels();
    m_guiHost->SetPaneRegion(*m_root, Rectangle{0.0f, 0.0f, static_cast<f32>(m_width) - pane, static_cast<f32>(m_height)});
    if (m_inspectorOpen)
        m_guiHost->SetPaneRegion(m_inspector->GetRoot(), Rectangle{static_cast<f32>(m_width) - pane, 0.0f, pane, static_cast<f32>(m_height)});
    m_guiHost->SizePanes(); // the roots at this frame's size: the shell is laid out from it
}

// Before the host routes the frame's input: the boundary between the root on show and the pane.
void GUISandbox::RouteInput()
{
    if (m_shell == nullptr || m_shell->Input() == nullptr)
        return;
    (void)ResizeInspector(*m_shell->Input());
    Layout();
}

bool GUISandbox::FilterPointer(gui::SceneRoot& pane, shell::InputSurface& surface)
{
    // While the boundary has the pointer, neither root sees it.
    if (m_resizingInspector)
        return true;
    if (&pane != m_root.Get())
        return false;
    if (m_inspectorOpen && m_inspector->IsPicking())
    {
        // Picking: the pointer over the root on show goes to the inspector, not to it.
        shell::IMouse& mouse = *surface.Mouse();
        if (surface.MouseActive())
        {
            m_inspector->PickHover(Float2{mouse.X(), mouse.Y()});
            if (mouse.ScrollY() != 0.0f)
                m_inspector->PickWheel(mouse.ScrollY());
            if (mouse.IsButtonPressed(shell::MouseButton::Left))
                m_inspector->PickClick();
        }
        return true;
    }
    return m_keys.Size() != 0; // a --keys script owns the pointer: the desk's mouse would move it back
}

void GUISandbox::TypeKeys(gui::SceneRoot& root)
{
    // --keys: the named keystrokes, one every 15 frames once the GUI is up.
    if (m_keys.Size() == 0 || m_frames < 10 || (m_frames - 10) % 15 != 0)
        return;
    const Array<StringView> keys = gui::SplitTopLevel(m_keys.AsView(), u8' ');
    const usize index = static_cast<usize>((m_frames - 10) / 15);
    if (index >= keys.Size())
        return;
    // Pointer steps (logical units, as a screenshot is): click:x,y rclick:x,y move:x,y down:x,y up:x,y,
    // and two fingers' pinch:, turn: and pan2:; or at the middle of what a selector or a text finds:
    // click:#ok, click:text=Show, move:text~=Sett (no spaces: a step ends at one).
    const StringView step = keys[index];
    usize colon = 0;
    while (colon < step.Size() && step[colon] != u8':')
        ++colon;
    if (colon < step.Size())
    {
        const StringView verb = step.SubStr(0, colon);
        const StringView where = step.SubStr(colon + 1, step.Size() - colon - 1);
        usize comma = 0;
        while (comma < where.Size() && where[comma] != u8',')
            ++comma;
        const f32 scale = root.GetDisplayScale();
        Float2 at{static_cast<f32>(ParseFloat(where.SubStr(0, comma)).ValueOr(0.0)) * scale,
                  comma < where.Size() ? static_cast<f32>(ParseFloat(where.SubStr(comma + 1, where.Size() - comma - 1)).ValueOr(0.0)) * scale : 0.0f};
        const bool numeric = where.Size() != 0 && ((where[0] >= u8'0' && where[0] <= u8'9') || where[0] == u8'-');
        if (!numeric)
        {
            const Array<gui::Node*> found = gui::testing::Finder::Parse(where).All(root);
            if (found.IsEmpty())
            {
                std::printf("GUISandbox: --keys: %s found nothing\n", reinterpret_cast<const char*>(String(where).CStr()));
                return;
            }
            const gui::Rect box = found[0]->GetScreenBounds();
            at = Float2{box.x + box.width * 0.5f, box.y + box.height * 0.5f};
        }
        gui::EventDispatcher& d = *root.GetEventDispatcher();
        if (verb == StringView(u8"move"))
            (void)d.InjectMouseMove(at);
        else if (verb == StringView(u8"down"))
            (void)d.InjectMouseDown(at, gui::MouseButton::Left);
        else if (verb == StringView(u8"up"))
            (void)d.InjectMouseUp(at, gui::MouseButton::Left);
        else if (verb == StringView(u8"click") || verb == StringView(u8"rclick"))
        {
            const gui::MouseButton button = verb == StringView(u8"click") ? gui::MouseButton::Left : gui::MouseButton::Right;
            (void)d.InjectMouseMove(at);
            (void)d.InjectMouseDown(at, button);
            (void)d.InjectMouseUp(at, button);
        }
        else if (verb == StringView(u8"pinch") || verb == StringView(u8"turn") || verb == StringView(u8"pan2"))
        {
            // Two fingers about it (E17c): pinch spreads them from 100 to 200 apart, turn turns them a
            // quarter, pan2 moves them together 60 across and 30 down (logical units).
            const f32 half = 50.0f * scale;
            const f32 spread = verb == StringView(u8"pinch") ? 2.0f : 1.0f;
            const f32 turn = verb == StringView(u8"turn") ? kPi * 0.5f : 0.0f;
            const Float2 by = verb == StringView(u8"pan2") ? Float2{60.0f * scale, 30.0f * scale} : Float2{0.0f, 0.0f};
            const auto finger = [&](f32 t, f32 side)
            {
                const f32 reach = half * (1.0f + (spread - 1.0f) * t) * side;
                return Float2{at.x + by.x * t + reach * Cos(turn * t), at.y + by.y * t + reach * Sin(turn * t)};
            };
            (void)d.InjectTouchDown(1u, finger(0.0f, -1.0f));
            (void)d.InjectTouchDown(2u, finger(0.0f, 1.0f));
            for (int i = 1; i <= 8; ++i)
            {
                const f32 t = static_cast<f32>(i) / 8.0f;
                (void)d.InjectTouchMove(1u, finger(t, -1.0f));
                (void)d.InjectTouchMove(2u, finger(t, 1.0f));
            }
            (void)d.InjectTouchUp(2u, finger(1.0f, 1.0f));
            (void)d.InjectTouchUp(1u, finger(1.0f, -1.0f));
        }
        m_menuWantsUpdate = true;
        return;
    }
    if (const Optional<gui::Keystroke> stroke = gui::ParseKeystroke(keys[index]); stroke.HasValue())
    {
        if (stroke.Value().Pad)
            root.GetEventDispatcher()->InjectPadButton(static_cast<gui::PadButton>(stroke.Value().Code));
        else
            root.GetEventDispatcher()->InjectKeyDown(stroke.Value().Code, stroke.Value().Modifiers);
        m_menuWantsUpdate = true;
    }
}

namespace
{
    // The widgets under `node` a sweep visits: shown, sized, in the tree's order.
    void CollectSweep(gui::Node& node, Array<gui::Node*>& out)
    {
        if (!node.IsVisible())
            return;
        if (node.GetSize().x > 0.0f && node.GetSize().y > 0.0f && Cast<gui::UIWidget>(&node) != nullptr)
            out.PushBack(&node);
        for (usize i = 0; i < node.ChildCount(); ++i)
            CollectSweep(*node.GetChildAt(i), out);
    }

}

void GUISandbox::SoakFrame()
{
    if (m_soakStart < 0.0f)
    {
        m_soakStart = m_totalTime;
        m_soakNextRow = m_totalTime + 10.0f;
        m_soakFile = std::fopen(reinterpret_cast<const char*>(m_soakCsv.CStr()), "w");
        if (m_soakFile != nullptr)
            std::fprintf(m_soakFile, "seconds,frames,p50_ms,p95_ms,p99_ms,live_allocations,live_bytes,resident_mib\n");
        std::printf("GUISandbox soak: %.1f minutes, rows in %s\n", static_cast<double>(m_soakSeconds / 60.0f),
                    reinterpret_cast<const char*>(m_soakCsv.CStr()));
    }
    m_soakFrames.PushBack(m_deltaTime * 1000.0f);
    if (m_totalTime < m_soakNextRow || m_soakFrames.IsEmpty())
        return;
    m_soakNextRow += 10.0f;
    Array<f32> sorted = m_soakFrames;
    std::sort(sorted.begin(), sorted.end());
    const auto at = [&sorted](f32 share) { return sorted[Min(sorted.Size() - 1, static_cast<usize>(share * static_cast<f32>(sorted.Size())))]; };
    const TrackingAllocator& tracking = AppRoot();
    std::printf("GUISandbox soak %.0fs: p50 %.2f ms, p95 %.2f ms, p99 %.2f ms, %llu live allocations, %.1f MiB resident\n",
                static_cast<double>(m_totalTime - m_soakStart), static_cast<double>(at(0.5f)), static_cast<double>(at(0.95f)),
                static_cast<double>(at(0.99f)), static_cast<unsigned long long>(tracking.LiveAllocations()), ResidentMiB());
    if (m_soakFile != nullptr)
    {
        std::fprintf(m_soakFile, "%.1f,%llu,%.3f,%.3f,%.3f,%llu,%llu,%.2f\n", static_cast<double>(m_totalTime - m_soakStart),
                     static_cast<unsigned long long>(sorted.Size()), static_cast<double>(at(0.5f)), static_cast<double>(at(0.95f)),
                     static_cast<double>(at(0.99f)), static_cast<unsigned long long>(tracking.LiveAllocations()),
                     static_cast<unsigned long long>(tracking.LiveBytes()), ResidentMiB());
        std::fflush(m_soakFile);
    }
    m_soakFrames.Clear();
    if (m_totalTime - m_soakStart >= m_soakSeconds && m_soakFile != nullptr)
    {
        std::fclose(m_soakFile);
        m_soakFile = nullptr;
    }
}

void GUISandbox::Settle()
{
    LayOutShell();
    m_gui->Update(Duration::FromSeconds(1.0 / 60.0));
    m_styles->SetMediaContext(m_root->GetMediaContext());
    m_styles->ApplyTree(*m_root);
    m_root->UpdateLayout();
}

namespace
{
    // The widgets a mirror audit checks: shown and sized, outside what is placed physically on
    // purpose (a dock's sides, a popup or a window at a point, a canvas's children at theirs; what
    // a window or a canvas's child holds is checked), what runs one way whatever the page (a
    // direction set on it) and an item view's rows, which it recycles from item to item (the unit
    // tests check theirs).
    void CollectMirrored(gui::Node& node, Array<gui::Node*>& out, bool placed = false)
    {
        if (!node.IsVisible() || !node.IsDisplayed() || node.IsInTopLayer())
            return;
        if (!placed && node.GetSize().x > 0.0f && node.GetSize().y > 0.0f && Cast<gui::UIWidget>(&node) != nullptr &&
            Cast<gui::Window>(&node) == nullptr)
            out.PushBack(&node);
        if (node.GetLayoutStyle().Kind == gui::Display::Dock || Cast<gui::ItemView>(&node) != nullptr)
            return;
        for (usize i = 0; i < node.ChildCount(); ++i)
        {
            gui::Node& child = *node.GetChildAt(i);
            const gui::Node::LayoutDirection direction = child.GetLayoutDirection(); // the page's own is the audit's
            if (direction != gui::Node::LayoutDirection::LeftToRight && direction != gui::Node::LayoutDirection::RightToLeft)
                CollectMirrored(child, out, node.GetPlacesChildren());
        }
    }
}

void GUISandbox::MirrorAudit()
{
    // Each widget's layout box within its parent (before its own transform, which CSS keeps
    // physical, and its parent's scroll): in right to left, at the mirror of where it was.
    struct Placed
    {
        gui::Node* node;
        Float2 at;
        Float2 size;
    };
    u32 widgets = 0;
    for (const Page& page : m_pages)
    {
        if (page.id.AsView() == StringView(u8"stress") || page.id.AsView() == StringView(u8"motion"))
            continue; // thousands of widgets all alike; things on the move
        ShowPage(page.id.AsView());
        page.node->SetLayoutDirection(gui::Node::LayoutDirection::LeftToRight);
        for (int i = 0; i < 3; ++i)
            Settle(); // rows measured once styled, a frame on
        Array<gui::Node*> nodes;
        CollectMirrored(*page.node, nodes);
        Array<Placed> before;
        for (gui::Node* node : nodes)
            if (node != page.node && node->GetParent() != nullptr)
                before.PushBack(Placed{node, node->GetPosition(), node->GetSize()});
        page.node->SetLayoutDirection(gui::Node::LayoutDirection::RightToLeft);
        for (int i = 0; i < 3; ++i)
            Settle();
        for (const Placed& p : before)
        {
            ++widgets;
            const Float2 at = p.node->GetPosition();
            const f32 want = p.node->GetParent()->GetSize().x - p.at.x - p.size.x;
            if (Abs(at.x - want) <= 1.0f && Abs(p.node->GetSize().x - p.size.x) <= 1.0f && Abs(at.y - p.at.y) <= 1.0f)
                continue;
            ++m_mirrorMisplaced;
            String what = p.node->DebugName();
            if (const auto* label = Cast<gui::Label>(p.node))
            {
                what.Append(u8" \"");
                what.Append(label->GetText().SubStr(0, Min<usize>(label->GetText().Size(), 24)));
                what.Append(u8"\"");
            }
            std::printf("GUISandbox mirror: %s %s in %s at x %.1f, wanted %.1f (left to right %.1f, %.1f wide; y %.1f from %.1f)\n",
                        reinterpret_cast<const char*>(page.id.CStr()), reinterpret_cast<const char*>(what.CStr()),
                        reinterpret_cast<const char*>(p.node->GetParent()->DebugName().CStr()), static_cast<double>(at.x),
                        static_cast<double>(want), static_cast<double>(p.at.x), static_cast<double>(p.size.x),
                        static_cast<double>(at.y), static_cast<double>(p.at.y));
        }
        page.node->SetLayoutDirection(gui::Node::LayoutDirection::Inherit);
    }
    ShowPage(m_startPage.AsView());
    std::printf("GUISandbox mirror: %u widgets, %u misplaced\n", widgets, m_mirrorMisplaced);
    std::fflush(stdout);
    m_mirrorAuditDone = true;
    Exit();
}

void GUISandbox::Sweep()
{
    if (m_frames < 10)
        return;
    if (m_sweepSteps.IsEmpty() && m_sweepNext == 0)
    {
        // Plan it: each page shown in turn, its widgets' centres as they lie once shown.
        for (const Page& page : m_pages)
        {
            if (page.id.AsView() == StringView(u8"stress"))
                continue; // thousands of widgets: a smoke test of every one would take minutes
            ShowPage(page.id.AsView());
            m_root->UpdateLayout();
            Array<gui::Node*> nodes;
            CollectSweep(*page.node, nodes);
            for (gui::Node* node : nodes)
            {
                const gui::Rect bounds = node->GetScreenBounds();
                if (bounds.y + bounds.height * 0.5f > static_cast<f32>(m_height))
                    continue; // below the fold
                m_sweepSteps.PushBack(SweepStep{page.id, false, false, Float2{bounds.x + bounds.width * 0.5f, bounds.y + bounds.height * 0.5f}, node->DebugName()});
            }
            m_sweepSteps.PushBack(SweepStep{page.id, false, true, Float2{}, String(u8"keys and pad")});
        }
        ShowPage(m_startPage.AsView());
        m_sweepSteps.PushBack(SweepStep{String(), true, false, Float2{}, String(u8"open the game menu")});
        std::printf("GUISandbox sweep: %llu steps\n", static_cast<unsigned long long>(m_sweepSteps.Size()));
        GlobalLogger().AddSink(&m_sweepLog); // from here on, a warning fails the sweep
    }
    if (m_soakSeconds > 0.0f && m_sweepNext >= m_sweepSteps.Size() && m_totalTime - m_soakStart < m_soakSeconds)
        m_sweepNext = 0; // soaking: round again
    if (m_sweepNext >= m_sweepSteps.Size())
    {
        GlobalLogger().RemoveSink(&m_sweepLog);
        m_sweepDone = true;
        std::printf("GUISandbox sweep: done\n");
        std::fflush(stdout);
        Exit();
        return;
    }
    const SweepStep& step = m_sweepSteps[m_sweepNext++];
    std::printf("GUISandbox sweep %llu: %s %s at %.0f, %.0f\n", static_cast<unsigned long long>(m_sweepNext),
                reinterpret_cast<const char*>(step.page.CStr()), reinterpret_cast<const char*>(step.what.CStr()), step.at.x, step.at.y);
    std::fflush(stdout);
    if (step.menu)
    {
        OpenMenu();
        return;
    }
    if (step.page.AsView() != m_current.AsView())
        ShowPage(step.page.AsView());
    if (step.keys)
    {
        // Through the page by Tab, the arrows and the pad: what a keyboard or pad player reaches.
        gui::EventDispatcher& keys = *m_root->GetEventDispatcher();
        const gui::KeyCode codes[] = {gui::KeyCode::Tab, gui::KeyCode::Tab, gui::KeyCode::Down, gui::KeyCode::Right,
                                      gui::KeyCode::Up, gui::KeyCode::Left, gui::KeyCode::Space};
        for (const gui::KeyCode code : codes)
        {
            keys.InjectKeyDown(static_cast<u32>(code));
            keys.InjectKeyUp(static_cast<u32>(code));
        }
        keys.InjectPadButton(gui::PadButton::South);
        keys.InjectPadButton(gui::PadButton::East);
        keys.InjectKeyDown(static_cast<u32>(gui::KeyCode::Escape));
        return;
    }
    // Device pixels: the root's transform maps them (its display scale).
    const Float2 at{step.at.x * m_root->GetDisplayScale(), step.at.y * m_root->GetDisplayScale()};
    gui::EventDispatcher& d = *m_root->GetEventDispatcher();
    d.InjectMouseMove(at);
    d.InjectMouseDown(at, gui::MouseButton::Left);
    d.InjectMouseUp(at, gui::MouseButton::Left);
    d.InjectMouseDown(at, gui::MouseButton::Right);
    d.InjectMouseUp(at, gui::MouseButton::Right);
    d.InjectKeyDown(static_cast<u32>(gui::KeyCode::Escape)); // close what a click opened
}

void GUISandbox::UpdateMenu()
{
    // --menu-call: once the menu has been up a few frames, as a click would come.
    if (m_menuScript && m_menuCall.Size() != 0 && m_frames == 10)
    {
        if (!m_menuScript->Call(m_menuCall.AsView(), Span<Variant>{}).HasValue())
            std::fprintf(stderr, "GUISandbox: the game menu's script has no %s()\n", reinterpret_cast<const char*>(m_menuCall.CStr()));
        m_menuWantsUpdate = true;
    }
    // Its update runs while it asks, and on a frame with input; an idle menu calls no script.
    const bool input = m_shell != nullptr && m_shell->Input() != nullptr && !m_shell->Input()->Events().IsEmpty();
    if (m_menuScript && (m_menuWantsUpdate || input) && m_menuScript->HasFunction(u8"update"))
    {
        Variant args[1] = {Variant::From<f64>(static_cast<f64>(m_deltaTime))};
        Result<Variant> result = m_menuScript->Call(u8"update", Span<Variant>(args, 1));
        const bool* more = result.HasValue() ? result.Value().TryGet<bool>() : nullptr;
        m_menuWantsUpdate = more != nullptr && *more;
    }
    if (m_menuLeaveAt >= 0.0f && m_totalTime >= m_menuLeaveAt)
        CloseMenu();
}

void GUISandbox::OnUpdate(runtime::IApplicationHost&, f32 deltaTime)
{
    if (!m_guiHost)
        return;
    m_deltaTime = deltaTime;
    m_totalTime += deltaTime;
    FinishScreenshot(); // last frame's, now the GPU has run it
    m_width = m_window->Width();
    m_height = m_window->Height();
    if (!m_benchPage.IsEmpty())
    {
        RunBench();
        return;
    }
    if (m_imageTests)
    {
        RunImageTests();
        return;
    }
    if (m_mirrorAudit && m_frames >= 10 && !m_mirrorAuditDone)
    {
        MirrorAudit();
        return;
    }
    if (shell::IInputManager* input = m_shell->Input(); input != nullptr && input->Keyboard() != nullptr &&
                                                       input->Keyboard()->IsKeyPressed(shell::KeyCode::F12))
        RequestScreenshot();
    RouteInput();
    TypeKeys(*m_root);
    // --scroll: once the GUI is up (held a few frames while the page settles).
    if (m_scroll > 0.0f && m_frames >= 10 && m_frames <= 20 && m_content != nullptr)
        m_content->SetScrollOffset(Float2{0.0f, m_scroll});
    if (m_sweep)
    {
        Sweep();
        if (m_soakSeconds > 0.0f)
            SoakFrame();
    }
    LayOutShell();
    if (m_showingMenu)
        UpdateMenu();
    if (m_inspectorOpen)
    {
        if (m_inspector->GetTarget() != m_root.Get())
            m_inspector->Inspect(m_root.Get(), m_styles);
        if (m_inspectSelector.Size() != 0 && m_frames == 10)
            (void)m_inspector->SelectQuery(m_inspectSelector.AsView());
        m_inspector->Refresh();
    }
    // The host: each pane's input, the GUI's clock, styles and layout; whether a frame is needed.
    m_guiHost->Update(deltaTime);
    // The Viewport page's camera reads the widget's gated input while it is hovered or focused.
    if (m_viewport && m_viewport->IsTreeVisible())
    {
        m_spin += deltaTime;
        if (m_viewport->IsActive())
            m_camera.Update(m_viewport->Keyboard(), m_viewport->Mouse(), deltaTime);
    }

    ++m_frames;
    if (m_frameStats && m_totalTime >= m_nextStatsTime)
    {
        std::printf("GUISandbox: drew %llu of %llu frames\n", static_cast<unsigned long long>(m_guiHost->FramesDrawn()),
                    static_cast<unsigned long long>(m_frames));
        // The last drawn frame's costs and what asked for it (E8a).
        std::printf("GUISandbox: last frame: %s\n", reinterpret_cast<const char*>(m_root->GetLastFrameStats().Describe().CStr()));
        std::fflush(stdout);
        m_nextStatsTime = m_totalTime + 1.0f;
    }
    // The Code page checks its script a moment after an edit.
    if (m_code)
        m_code->Update(deltaTime);
    // The Stress page shows the last frame's costs, each second.
    if (m_stress && m_current.AsView() == StringView(u8"stress") && m_totalTime >= m_nextStressStatsTime)
    {
        m_stress->ShowStats(m_root->GetLastFrameStats());
        m_nextStressStatsTime = m_totalTime + 1.0f;
    }
    if (m_alwaysRedraw)
        m_root->Invalidate();
}

void GUISandbox::OnRenderWindow(runtime::IApplicationHost&, graphics::FrameContext& frame)
{
    if (!m_guiHost || !frame.valid)
        return;
    m_guiHost->RenderWindow(frame);
    if (frame.window != m_mainWindow || frame.encoder == nullptr)
        return;
    // F12 or --screenshot: this frame, as presented.
    ++m_presentedFrames;
    if (m_screenshotOptions.Requested() && m_screenshotsTaken < m_screenshotOptions.count &&
        (m_screenshotsTaken > 0 || m_screenshotOptions.Due(m_presentedFrames, m_totalTime)))
    {
        m_screenshot.Request(m_screenshotOptions.PathFor(m_screenshotsTaken).AsView());
        ++m_screenshotsTaken;
        m_screenshotExitPending = m_screenshotOptions.exitAfter && m_screenshotsTaken == m_screenshotOptions.count;
    }
    if (m_screenshot.Armed() &&
        !m_screenshot.Record(*m_device, *frame.encoder, frame.backbuffer, m_mainWindow->Swap()->Format(), frame.width, frame.height) &&
        m_screenshotExitPending)
    {
        std::fprintf(stderr, "GUISandbox: the screenshot could not be taken (this surface cannot be copied)\n");
        Exit();
    }
}

// The Docking page's layout as it starts and resets: the scene in the middle, the hierarchy on the
// left, the inspector on the right, the console, the log and the assets under the scene, and a
// profiler the layout names before it is registered (a placeholder until it is).
static gui::DockLayout DefaultDockLayout()
{
    gui::DockLayout layout;
    const gui::DockNodeId central = layout.CentralStack();
    (void)layout.InsertTab(u8"scene", central);
    (void)layout.InsertBeside(u8"hierarchy", central, gui::DockSide::Start, 0.22f);
    (void)layout.InsertBeside(u8"inspector", central, gui::DockSide::End, 0.3f);
    (void)layout.InsertBeside(u8"console", central, gui::DockSide::Bottom, 0.34f);
    const gui::DockNodeId bottom = layout.StackOf(u8"console");
    (void)layout.InsertTab(u8"log", bottom);
    (void)layout.InsertTab(u8"assets", bottom);
    (void)layout.InsertTab(u8"profiler", bottom);
    (void)layout.Activate(u8"console");
    (void)layout.Float(u8"assets", Rectangle{350.0f, 70.0f, 220.0f, 160.0f}); // a float, over them
    return layout;
}

void GUISandbox::RegisterDockPanel(StringView id, StringView title, gui::DockClosePolicy close, StringView line)
{
    const usize index = m_dockPanels.Size();
    m_dockPanels.PushBack(String(id));
    gui::DockPanelDescription description;
    description.Id = String(id);
    description.Title = String(title);
    description.Close = close;
    description.Closable = id != StringView(u8"scene");
    description.Default.Central = id == StringView(u8"scene");
    GUISandbox* self = this;
    const String text(line);
    const StringView policy = close == gui::DockClosePolicy::Hide      ? StringView(u8"closing hides it, its content kept")
                              : close == gui::DockClosePolicy::Rebuild ? StringView(u8"closing lets its content go; shown again, it is made anew")
                                                                       : StringView(u8"closing forgets it, its place too");
    const String note = description.Closable ? String(policy) : String(u8"it cannot be closed");
    description.Factory = [self, index, text, note]()
    {
        ++self->m_dockMade[index];
        RefPtr<gui::Panel> content = MakeRef<gui::Panel>(AppRoot());
        content->AddClass(u8"dock-content");
        content->EditLayoutStyle([](gui::LayoutStyle& s) { s.Direction = gui::FlexDirection::Column; });
        const String lines[] = {text, note, Format(u8"Made {} time{}.", self->m_dockMade[index], self->m_dockMade[index] == 1 ? u8"" : u8"s")};
        for (const String& l : lines)
        {
            RefPtr<gui::Label> label = MakeRef<gui::Label>(AppRoot());
            label->SetText(l.AsView());
            content->AddChild(label.Get());
        }
        return RefPtr<gui::Node>(content);
    };
    (void)m_dock->Register(Move(description));
}

void GUISandbox::FillDocking(gui::Node& host)
{
    gui::DefineDockingCommands(*m_gui);
    m_dock = MakeUnique<gui::DockController>(AppRoot(), AppRoot());
    RegisterDockPanel(u8"scene", u8"Scene", gui::DockClosePolicy::Hide, u8"The central stack: it stays when every tab leaves it.");
    RegisterDockPanel(u8"hierarchy", u8"Hierarchy", gui::DockClosePolicy::Hide, u8"World, Camera, Light, Cube.");
    RegisterDockPanel(u8"inspector", u8"Inspector", gui::DockClosePolicy::Hide, u8"The cube: position 0 0 0, spin 1.");
    RegisterDockPanel(u8"console", u8"Console", gui::DockClosePolicy::Rebuild, u8"> ready");
    RegisterDockPanel(u8"log", u8"Log", gui::DockClosePolicy::Hide, u8"Loaded the sandbox.");
    RegisterDockPanel(u8"assets", u8"Assets", gui::DockClosePolicy::Destroy, u8"cube.glb, sky.png, theme.css.");
    (void)m_dock->Adopt(DefaultDockLayout());
    m_dockArea = MakeRef<gui::DockArea>(AppRoot());
    host.AddChild(m_dockArea.Get());
    m_dockArea->Show(*m_dock);

    GUISandbox* self = this;
    (void)m_root->OnCommand(u8"docking.reset",
                            [self](gui::CommandEvent&)
                            {
                                // The default layout's float stands in the area's units: adopted
                                // there, then taken back to its own window when floats are.
                                const bool own = self->m_dockWindows.Get() != nullptr;
                                self->SetDockWindows(false);
                                (void)self->m_dock->Adopt(DefaultDockLayout());
                                self->SetDockWindows(own);
                            });
    // The floats in the area or in OS windows of their own (D6), where the host opens windows.
    (void)m_root->OnCommand(u8"docking.os-windows", [self](gui::CommandEvent&) { self->SetDockWindows(self->m_dockWindows.Get() == nullptr); });
    (void)m_root->OnCommand(u8"docking.show-closed",
                            [self](gui::CommandEvent&)
                            {
                                for (const String& id : self->m_dockPanels)
                                    if (self->m_dock->GetLayout().StackOf(id.AsView()) == gui::kNoDock)
                                        (void)self->m_dock->Show(id.AsView());
                            });
    (void)m_root->OnCommand(u8"docking.register",
                            [self](gui::CommandEvent&)
                            {
                                if (self->m_dock->Describe(u8"profiler") == nullptr)
                                    self->RegisterDockPanel(u8"profiler", u8"Profiler", gui::DockClosePolicy::Hide,
                                                            u8"Registered late: it fills the place the layout kept for it.");
                            });
    // What a torn tab leaves, both to try: its strip closing up, or it dimmed in place (the page's
    // sheet, for every dock space in the area: the floats' too).
    (void)m_root->OnCommand(u8"docking.torn-tab",
                            [&host](gui::CommandEvent&)
                            {
                                auto* holder = Cast<gui::UIWidget>(&host);
                                if (holder == nullptr)
                                    return;
                                const bool dim = holder->HasClass(u8"torn-close");
                                if (dim)
                                    holder->RemoveClass(u8"torn-close");
                                else
                                    holder->AddClass(u8"torn-close");
                                gui::Node* page = host.GetParent() != nullptr ? host.GetParent()->GetParent() : nullptr;
                                if (auto* button = page != nullptr ? Cast<gui::Button>(FindById(*page, u8"docking-torn")) : nullptr)
                                    button->SetText(dim ? u8"A torn tab dims" : u8"A torn tab closes up");
                            });
}

// The Toolkit page's commands: Save, Undo and Redo disabled until there is something to do, with
// the reason a tooltip shows; Grid and Snap checked; Play and Add saying what they did on the
// status bar; Narrow showing the tool bar's overflow.
void GUISandbox::FillToolkit(gui::Node& frame)
{
    gui::GUIContext& context = m_root->GetContext();
    struct Named
    {
        const char8_t* id;
        const char8_t* label;
        const char8_t* keys;
    };
    const Named kCommands[] = {
        {u8"toolkit.new", u8"New", u8"ctrl-n"},         {u8"toolkit.open", u8"Open", u8"ctrl-o"},
        {u8"toolkit.save", u8"Save", u8"ctrl-s"},       {u8"toolkit.undo", u8"Undo", u8"ctrl-z"},
        {u8"toolkit.redo", u8"Redo", u8"ctrl-y"},       {u8"toolkit.grid", u8"Grid", nullptr},
        {u8"toolkit.snap", u8"Snap", nullptr},          {u8"toolkit.play", u8"Play", u8"f5"},
        {u8"toolkit.play-here", u8"Play from here", nullptr}, {u8"toolkit.play-window", u8"Play in a window", nullptr},
        {u8"toolkit.add-cube", u8"Cube", nullptr},      {u8"toolkit.add-sphere", u8"Sphere", nullptr},
        {u8"toolkit.add-light", u8"Light", nullptr},    {u8"toolkit.settings", u8"Settings", nullptr},
    };
    for (const Named& named : kCommands)
    {
        context.DefineCommand(named.id).SetLabel(named.label);
        if (named.keys != nullptr)
            (void)context.GetKeymap().Bind(named.keys, named.id, u8"toolkit"); // while the focus is in the frame
    }
    context.DefineCommand(u8"toolkit.grid").SetChecked(true);
    // The canvas takes the focus a click gives it, as an editor's view does: the frame's keys run
    // while the focus is in it.
    if (gui::Node* canvas = FindById(frame, u8"toolkit-canvas"))
        canvas->SetTabFocusable(true);

    GUISandbox* self = this;
    gui::Node* page = &frame;
    const auto status = [page](StringView text)
    {
        if (auto* bar = Cast<gui::StatusBar>(FindById(*page, u8"toolkit-status")))
            bar->ShowMessage(text, 3.0f);
    };
    // Save, Undo and Redo over an edit history of counts: what is left to save, undo and redo.
    const auto update = [self]()
    {
        gui::GUIContext& c = self->m_root->GetContext();
        gui::Command& save = c.DefineCommand(u8"toolkit.save");
        save.SetEnabled(self->m_toolkitUnsaved > 0);
        save.SetDisabledReason(u8"Nothing to save: make a change first");
        gui::Command& undo = c.DefineCommand(u8"toolkit.undo");
        undo.SetEnabled(self->m_toolkitDone > 0);
        undo.SetDisabledReason(u8"Nothing to undo");
        gui::Command& redo = c.DefineCommand(u8"toolkit.redo");
        redo.SetEnabled(self->m_toolkitUndone > 0);
        redo.SetDisabledReason(u8"Nothing to redo");
    };
    update();
    const auto on = [self](const char8_t* id, Function<void()> run)
    { (void)self->m_root->OnCommand(id, [run = Move(run)](gui::CommandEvent&) { run(); }); };
    on(u8"toolkit.change", [self, update, status]()
    {
        ++self->m_toolkitUnsaved;
        ++self->m_toolkitDone;
        self->m_toolkitUndone = 0;
        update();
        status(u8"Changed the scene");
    });
    on(u8"toolkit.save", [self, update, status]()
    {
        self->m_toolkitUnsaved = 0;
        update();
        status(u8"Saved");
    });
    on(u8"toolkit.undo", [self, update, status]()
    {
        --self->m_toolkitDone;
        ++self->m_toolkitUndone;
        ++self->m_toolkitUnsaved;
        update();
        status(u8"Undid the change");
    });
    on(u8"toolkit.redo", [self, update, status]()
    {
        --self->m_toolkitUndone;
        ++self->m_toolkitDone;
        ++self->m_toolkitUnsaved;
        update();
        status(u8"Redid the change");
    });
    on(u8"toolkit.new", [status]() { status(u8"A new scene"); });
    on(u8"toolkit.open", [status]() { status(u8"Opened a scene"); });
    on(u8"toolkit.settings", [status]() { status(u8"Settings would open here"); });
    on(u8"toolkit.grid", [self, page, status]()
    {
        gui::Command& grid = self->m_root->GetContext().DefineCommand(u8"toolkit.grid");
        grid.SetChecked(!grid.IsChecked());
        if (auto* label = Cast<gui::Label>(FindById(*page, u8"toolkit-grid-state")))
            label->SetText(grid.IsChecked() ? u8"Grid on" : u8"Grid off");
        status(grid.IsChecked() ? u8"The grid shows" : u8"The grid hides");
    });
    on(u8"toolkit.snap", [self, status]()
    {
        gui::Command& snap = self->m_root->GetContext().DefineCommand(u8"toolkit.snap");
        snap.SetChecked(!snap.IsChecked());
        status(snap.IsChecked() ? u8"Snapping to the grid" : u8"Not snapping");
    });
    on(u8"toolkit.play", [status]() { status(u8"Playing"); });
    on(u8"toolkit.play-here", [status]() { status(u8"Playing from here"); });
    on(u8"toolkit.play-window", [status]() { status(u8"Playing in a window"); });
    on(u8"toolkit.add-cube", [status]() { status(u8"Added a cube"); });
    on(u8"toolkit.add-sphere", [status]() { status(u8"Added a sphere"); });
    on(u8"toolkit.add-light", [status]() { status(u8"Added a light"); });
    on(u8"toolkit.narrow", [page]()
    {
        auto* holder = Cast<gui::UIWidget>(page);
        if (holder == nullptr)
            return;
        const bool narrow = !holder->HasClass(u8"narrow");
        if (narrow)
            holder->AddClass(u8"narrow");
        else
            holder->RemoveClass(u8"narrow");
        gui::Node* section = page->GetParent();
        if (auto* button = section != nullptr ? Cast<gui::Button>(FindById(*section, u8"toolkit-narrow")) : nullptr)
            button->SetText(narrow ? u8"Widen the tool bar" : u8"Narrow the tool bar");
    });
}

// The Toolkit page's property grid: three lamps behind a selection, a search, and the page's undo.
void GUISandbox::FillProperties(gui::PropertyGrid& grid)
{
    m_lamps = MakeUnique<sandbox::LampSource>(AppRoot(), AppRoot());
    grid.SetSource(m_lamps.Get());
    gui::Node* section = grid.GetParent();
    if (section == nullptr)
        return;
    auto* undo = Cast<gui::Button>(FindById(*section, u8"props-undo"));
    auto* redo = Cast<gui::Button>(FindById(*section, u8"props-redo"));
    auto* said = Cast<gui::Label>(FindById(*section, u8"props-said"));
    sandbox::LampSource* lamps = m_lamps.Get();
    const auto history = [lamps, undo, redo]()
    {
        if (undo != nullptr)
            undo->SetEnabled(lamps->CanUndo());
        if (redo != nullptr)
            redo->SetEnabled(lamps->CanRedo());
    };
    history();
    lamps->SetOnHistoryChanged([history, said](StringView words)
    {
        history();
        if (said != nullptr)
            said->SetText(words);
    });
    if (undo != nullptr)
        undo->SetOnClick([lamps]() { lamps->Undo(); });
    if (redo != nullptr)
        redo->SetOnClick([lamps]() { lamps->Redo(); });
    grid.SetOnMessage([said](StringView words) // why a paste was refused
    {
        if (said != nullptr)
            said->SetText(words);
    });
    if (auto* search = Cast<gui::TextField>(FindById(*section, u8"props-search")))
    {
        gui::PropertyGrid* shown = &grid;
        search->SetOnTextChanging([shown](StringView text) { shown->SetFilter(text); });
    }
    if (auto* objects = Cast<gui::ComboBox>(FindById(*section, u8"props-objects")))
        objects->SetOnSelectionChanged([lamps](i32 index)
        {
            if (index >= 0)
                lamps->SetSelection(static_cast<usize>(index));
        });
}

// The Toolkit page's reflected grid: two camera rigs, one or both edited, the source's changes kept
// here for Undo and Redo.
void GUISandbox::FillReflected(gui::PropertyGrid& grid)
{
    sandbox::RegisterCameraTypes(AppRoot());
    const char8_t* const names[] = {u8"Camera A", u8"Camera B"};
    for (usize i = 0; i < 2; ++i)
    {
        m_cameras[i] = MakeRef<sandbox::CameraRig>(AppRoot());
        m_cameras[i]->name = String(names[i]);
        m_cameras[i]->serial = 7001 + static_cast<u32>(i);
    }
    // The second differs, so both show mixed.
    m_cameras[1]->fieldOfView = 45.0f;
    m_cameras[1]->position.x = 3.0f;
    m_cameras[1]->effects.PushBack(MakeRef<sandbox::BloomEffect>(AppRoot()));
    m_cameraFormat = MakeUnique<sandbox::XmlTextFormat>(AppRoot(), AppRoot());
    m_reflected = MakeUnique<gui::ReflectedPropertySource>(AppRoot(), AppRoot());
    m_reflected->SetTextFormat(m_cameraFormat.Get());
    // The sky is a gradient: its stops and blend, as the application says (T5).
    m_reflected->RegisterGradientType(u8"SkyGradient", gui::ReflectedGradientParts{String(u8"colors"), String(u8"alphas"), String(u8"interpolation")});
    SelectCameras(0);
    grid.SetSource(m_reflected.Get());

    gui::Node* section = grid.GetParent();
    if (section == nullptr)
        return;
    m_cameraSaid = Cast<gui::Label>(FindById(*section, u8"reflected-said"));
    m_cameraUndoButton = Cast<gui::Button>(FindById(*section, u8"reflected-undo"));
    m_cameraRedoButton = Cast<gui::Button>(FindById(*section, u8"reflected-redo"));
    GUISandbox* self = this;
    const auto buttons = [self]()
    {
        if (self->m_cameraUndoButton != nullptr)
            self->m_cameraUndoButton->SetEnabled(!self->m_cameraUndo.IsEmpty());
        if (self->m_cameraRedoButton != nullptr)
            self->m_cameraRedoButton->SetEnabled(!self->m_cameraRedo.IsEmpty());
    };
    buttons();
    m_reflected->SetOnChange([self, buttons](const gui::ReflectedChange& change)
    {
        self->m_cameraUndo.PushBack(CameraStep{change, self->m_cameraSelection});
        self->m_cameraRedo.Clear();
        buttons();
        if (self->m_cameraSaid != nullptr)
            self->m_cameraSaid->SetText(change.Words.AsView());
    });
    if (m_cameraUndoButton != nullptr)
        m_cameraUndoButton->SetOnClick([self, buttons]() { self->StepCameras(true); buttons(); });
    if (m_cameraRedoButton != nullptr)
        m_cameraRedoButton->SetOnClick([self, buttons]() { self->StepCameras(false); buttons(); });
    grid.SetOnMessage([self](StringView words)
    {
        if (self->m_cameraSaid != nullptr)
            self->m_cameraSaid->SetText(words);
    });
    if (auto* search = Cast<gui::TextField>(FindById(*section, u8"reflected-search")))
    {
        gui::PropertyGrid* shown = &grid;
        search->SetOnTextChanging([shown](StringView text) { shown->SetFilter(text); });
    }
    if (auto* objects = Cast<gui::ComboBox>(FindById(*section, u8"reflected-objects")))
        objects->SetOnSelectionChanged([self](i32 index)
        {
            if (index >= 0)
                self->SelectCameras(static_cast<usize>(index));
        });
}

// Camera A (0), Camera B (1) or both (2) in the reflected grid.
void GUISandbox::SelectCameras(usize which)
{
    m_cameraSelection = which;
    Instance objects[2];
    usize count = 0;
    for (usize i = 0; i < 2; ++i)
        if (which == i || which >= 2)
            objects[count++] = Instance(m_cameras[i].Get(), m_cameras[i]->GetType());
    m_reflected->SetObjects(Span<const Instance>(objects, count));
}

// The Toolkit page's clip: eight tracks of the lamps' values ("Lamp A.intensity", "Lamp A.position.y"
// and the rest, the dopesheet folding them by lamp and property, more rows than it shows at once), a ruler, a dopesheet and a curve view on one axis. Scrubbing plays
// the tracks into the lamps, so the grid above follows; each edit of the clip is a step of its Undo.
void GUISandbox::FillClip(gui::Node& section)
{
    if (!m_lamps)
        return;
    using K = CurveKey;
    const auto key = [](f32 time, f32 value) { return K{time, value, 0.0f, 0.0f, CurveKeyInterpolation::Cubic, CurveTangentMode::Auto}; };
    m_clip = MakeUnique<gui::CurveSet>(AppRoot());
    struct Track
    {
        const char8_t* Path;
        Color Stroke;
        K Keys[4];
        usize Count;
    };
    const Track tracks[] = {
        {u8"Lamp A.intensity", Color{0.95f, 0.75f, 0.3f, 1.0f}, {key(0.0f, 5.0f), key(1.0f, 14.0f), key(2.5f, 3.0f), key(4.0f, 5.0f)}, 4},
        {u8"Lamp A.range", Color{0.45f, 0.8f, 0.55f, 1.0f}, {key(0.0f, 10.0f), key(2.0f, 16.0f), key(4.0f, 10.0f)}, 3},
        {u8"Lamp B.intensity", Color{0.45f, 0.65f, 1.0f, 1.0f}, {key(0.0f, 12.5f), key(1.5f, 4.0f), key(3.0f, 12.5f)}, 3},
        {u8"Lamp C.intensity", Color{0.9f, 0.45f, 0.6f, 1.0f}, {key(0.5f, 5.0f), key(2.0f, 18.0f), key(3.5f, 5.0f)}, 3},
        {u8"Lamp A.position.y", Color{0.7f, 0.55f, 0.95f, 1.0f}, {key(0.0f, 3.0f), key(2.0f, 6.0f), key(4.0f, 3.0f)}, 3},
        {u8"Lamp B.range", Color{0.4f, 0.85f, 0.85f, 1.0f}, {key(0.0f, 10.0f), key(1.0f, 7.0f), key(3.0f, 15.0f), key(4.0f, 10.0f)}, 4},
        {u8"Lamp B.position.y", Color{0.85f, 0.85f, 0.45f, 1.0f}, {key(0.5f, 3.0f), key(2.5f, 1.0f), key(4.0f, 3.0f)}, 3},
        {u8"Lamp C.range", Color{0.95f, 0.6f, 0.4f, 1.0f}, {key(0.0f, 10.0f), key(2.0f, 4.0f), key(4.0f, 10.0f)}, 3},
    };
    for (const Track& track : tracks)
    {
        gui::CurveInfo info;
        info.Name = String(track.Path);
        info.StrokeColor = track.Stroke;
        info.HasRange = true;
        info.Min = 0.0f;
        info.Max = 20.0f;
        K keys[4];
        for (usize i = 0; i < track.Count; ++i)
            keys[i] = track.Keys[i];
        ApplyTangentModes(Span<K>(keys, track.Count));
        m_clip->AddCurve(info, Span<const K>(keys, track.Count));
    }
    m_clipAxis = MakeRef<gui::TimeAxis>(AppRoot());
    m_clipAxis->SetDuration(4.0f);
    m_clipAxis->SetPixelsPerSecond(100.0f);
    m_clipAxis->SetFrameRate(30.0f);
    auto* ruler = Cast<gui::TimeRuler>(FindById(section, u8"clip-ruler"));
    auto* sheet = Cast<gui::Dopesheet>(FindById(section, u8"clip-sheet"));
    auto* curves = Cast<gui::CurveView>(FindById(section, u8"clip-curves"));
    if (ruler != nullptr)
        ruler->SetTimeAxis(m_clipAxis);
    if (sheet != nullptr)
    {
        sheet->SetTimeAxis(m_clipAxis);
        sheet->SetSource(m_clip.Get());
    }
    if (curves != nullptr)
    {
        curves->SetTimeAxis(m_clipAxis);
        curves->SetValueRange(-1.0f, 21.0f);
        curves->SetSource(m_clip.Get());
    }
    GUISandbox* self = this;
    auto* said = Cast<gui::Label>(FindById(section, u8"clip-said"));
    auto* undo = Cast<gui::Button>(FindById(section, u8"clip-undo"));
    auto* redo = Cast<gui::Button>(FindById(section, u8"clip-redo"));
    const auto buttons = [self, undo, redo]()
    {
        if (undo != nullptr)
            undo->SetEnabled(!self->m_clipUndo.IsEmpty());
        if (redo != nullptr)
            redo->SetEnabled(!self->m_clipRedo.IsEmpty());
    };
    buttons();
    m_clipAxis->SetOnPlayheadChanged([self, said](f32 time)
    {
        self->PlayClip(time);
        if (said != nullptr)
            said->SetText(Format(u8"At frame {} ({} s): the lamps above show the tracks there.", static_cast<i64>(Round(time * 30.0f)), gui::FormatStepped(time, 0.01f))
                              .AsView());
    });
    m_clip->SetOnCommit([self, buttons, said](const gui::CurveChange& change)
    {
        self->m_clipUndo.PushBack(change);
        self->m_clipRedo.Clear();
        buttons();
        self->PlayClip(self->m_clipAxis->Playhead());
        if (said != nullptr)
            said->SetText(Format(u8"Changed {} track(s).", change.Curves.Size()).AsView());
    });
    const auto step = [self, buttons, said](bool back)
    {
        Array<gui::CurveChange>& from = back ? self->m_clipUndo : self->m_clipRedo;
        Array<gui::CurveChange>& to = back ? self->m_clipRedo : self->m_clipUndo;
        if (from.IsEmpty())
            return;
        gui::CurveChange change = Move(from.Back());
        from.PopBack();
        self->m_clip->Apply(change, back);
        to.PushBack(Move(change));
        buttons();
        self->PlayClip(self->m_clipAxis->Playhead());
        if (said != nullptr)
            said->SetText(back ? StringView(u8"Undid a clip change.") : StringView(u8"Redid a clip change."));
    };
    if (undo != nullptr)
        undo->SetOnClick([step]() { step(true); });
    if (redo != nullptr)
        redo->SetOnClick([step]() { step(false); });
    if (auto* frame = Cast<gui::Button>(FindById(section, u8"clip-frame")))
    {
        gui::CurveView* view = curves;
        frame->SetOnClick([view]()
        {
            if (view != nullptr)
                view->FrameAll();
        });
    }
}

// A graph of the Toolkit page and its controls ("<prefix>-graph", "-undo", "-redo", "-frame", "-said"):
// each change the graph tells goes on its Undo, and `changed` hears it and each step back or on.
void GUISandbox::WireGraph(GraphHistory& graph, gui::Node& section, StringView prefix, Function<void()> changed)
{
    const auto byId = [&section, prefix](const char8_t* suffix)
    {
        String id(prefix);
        id += StringView(suffix);
        return FindById(section, id.AsView());
    };
    auto* view = Cast<gui::GraphView>(byId(u8"-graph"));
    auto* undo = Cast<gui::Button>(byId(u8"-undo"));
    auto* redo = Cast<gui::Button>(byId(u8"-redo"));
    auto* frame = Cast<gui::Button>(byId(u8"-frame"));
    auto* said = Cast<gui::Label>(byId(u8"-said"));
    graph.Set->SetTextFormat(m_graphFormat.Get());
    if (view != nullptr)
    {
        view->SetSource(graph.Set.Get());
        view->FrameAll();
    }
    graph.Changed = Move(changed);
    GraphHistory* history = &graph;
    const auto buttons = [history, undo, redo]()
    {
        if (undo != nullptr)
            undo->SetEnabled(!history->Undo.IsEmpty());
        if (redo != nullptr)
            redo->SetEnabled(!history->Redo.IsEmpty());
    };
    buttons();
    graph.Set->SetOnChange([history, buttons, said](const gui::GraphChange& change)
    {
        history->Undo.PushBack(change);
        history->Redo.Clear();
        buttons();
        if (said != nullptr)
            said->SetText(Format(u8"{}.", change.Words).AsView());
        if (history->Changed)
            history->Changed();
    });
    const auto step = [history, buttons, said](bool back)
    {
        Array<gui::GraphChange>& from = back ? history->Undo : history->Redo;
        Array<gui::GraphChange>& to = back ? history->Redo : history->Undo;
        if (from.IsEmpty())
            return;
        gui::GraphChange change = Move(from.Back());
        from.PopBack();
        history->Set->Apply(change, back);
        if (said != nullptr)
            said->SetText((back ? Format(u8"Undid: {}.", change.Words) : Format(u8"Redid: {}.", change.Words)).AsView());
        to.PushBack(Move(change));
        buttons();
        if (history->Changed)
            history->Changed();
    };
    if (undo != nullptr)
        undo->SetOnClick([step]() { step(true); });
    if (redo != nullptr)
        redo->SetOnClick([step]() { step(false); });
    if (frame != nullptr)
        frame->SetOnClick([view]()
        {
            if (view != nullptr)
                view->FrameAll();
        });
}

// The Toolkit page's graphs. A dataflow graph: two Numbers mixed into a lamp's intensity and a Colour
// tinted into its colour, its kinds of node under Values, Maths, Colour and Output, a pin's colour its
// type's (a float's green, a colour's amber), a link only between pins of one type. And the lamp's
// state machine: Off, On and Flicker and the transitions between them (node links), a double click
// making a state the lamp's, which it and its transitions out show highlighted.
// T7: two breadcrumb bars over an invented asset tree, a path not in it answered by a toast.
void GUISandbox::FillCrumbs(gui::Node& section)
{
    static constexpr const char8_t* kFolders[] = {
        u8"Content",
        u8"Content/Models",
        u8"Content/Models/Characters",
        u8"Content/Models/Characters/Fox",
        u8"Content/Models/Characters/Robot",
        u8"Content/Models/Props",
        u8"Content/Models/Props/Crate",
        u8"Content/Models/Props/Lamp",
        u8"Content/Textures",
        u8"Content/Textures/Wood",
        u8"Content/Textures/Stone",
        u8"Content/Audio",
        u8"Content/Audio/Music",
        u8"Content/Audio/Effects",
        u8"Content/Audio/Effects/Footsteps",
        u8"Content/Scenes",
        u8"Content/Scenes/Town",
        u8"Content/Scenes/Forest",
    };
    const auto exists = [](StringView path)
    {
        for (const char8_t* folder : kFolders)
            if (StringView(folder) == path)
                return true;
        return false;
    };
    auto* wide = Cast<gui::BreadcrumbBar>(FindById(section, u8"crumbs-bar"));
    auto* narrow = Cast<gui::BreadcrumbBar>(FindById(section, u8"crumbs-narrow"));
    auto* said = Cast<gui::Label>(FindById(section, u8"crumbs-said"));
    if (wide == nullptr || narrow == nullptr)
        return;
    GUISandbox* self = this;
    const auto go = [wide, narrow, said](StringView path)
    {
        wide->SetPath(path);
        narrow->SetPath(path);
        if (said != nullptr)
            said->SetText(Format(u8"In {}.", path).AsView());
    };
    const auto children = [](const gui::BreadcrumbItem& of, Array<gui::BreadcrumbItem>& out)
    {
        for (const char8_t* folder : kFolders)
        {
            const StringView path(folder);
            if (path.Size() <= of.Id.Size() + 1 || path.SubStr(0, of.Id.Size()) != of.Id.AsView() || path[of.Id.Size()] != u8'/')
                continue;
            const StringView name = path.SubStr(of.Id.Size() + 1, path.Size() - of.Id.Size() - 1);
            bool direct = true;
            for (const char8_t c : name)
                direct = direct && c != u8'/';
            if (direct)
                out.PushBack(gui::BreadcrumbItem{String(path), String(name), String(path), {}});
        }
    };
    gui::BreadcrumbBar* const bars[] = {wide, narrow};
    for (gui::BreadcrumbBar* bar : bars)
    {
        bar->SetOnNavigate([go](const gui::BreadcrumbItem& item) { go(item.Id.AsView()); });
        bar->SetOnChildren(children);
        bar->SetSegmentDropTypes(StringView(u8"asset"));
        bar->SetOnSegmentDrop([said](const gui::BreadcrumbItem& item, const gui::DragPayload& payload, gui::DropEffect)
        {
            if (said != nullptr)
                said->SetText(Format(u8"Moved {} into {}.", payload.Label, item.Id).AsView());
        });
    }
    wide->SetPathEditable(true);
    wide->SetOnPathSubmitted([self, go, exists](StringView typed)
    {
        String path(Trim(typed));
        while (path.Size() > 1 && path.AsView()[path.Size() - 1] == u8'/')
            path = String(path.AsView().SubStr(0, path.Size() - 1));
        if (exists(path.AsView()))
        {
            go(path.AsView());
            return;
        }
        gui::ToastRequest request;
        request.Severity = gui::ToastSeverity::Warning;
        request.Title = String(u8"No such folder");
        request.Message = Format(u8"{} is not in the asset tree.", path);
        request.Key = String(u8"crumbs-path");
        (void)self->m_toasts->Post(Move(request));
    });
    go(StringView(u8"Content/Models/Characters/Fox"));
    if (auto* up = Cast<gui::Button>(FindById(section, u8"crumbs-up")))
        up->SetOnClick([wide, go]()
        {
            if (wide->ItemCount() > 1)
                go(wide->ItemAt(wide->ItemCount() - 2).Id.AsView());
        });
    if (gui::Node* chip = FindById(section, u8"crumbs-chip"))
        chip->SetDragSource([](gui::DragRequest& r)
        {
            r.Payload.Type = String(u8"asset");
            r.Payload.Label = String(u8"fox.glb");
            return true;
        });
}

// T7: buttons posting each kind of toast to the shell's host (the core's, over the whole window).
void GUISandbox::FillToasts(gui::Node& section)
{
    GUISandbox* self = this;
    auto* toastSaid = Cast<gui::Label>(FindById(section, u8"toast-said"));
    const auto tell = [self, toastSaid]()
    {
        if (toastSaid != nullptr)
            toastSaid->SetText(Format(u8"{} posted, {} closed by you, {} showing, {} waiting.", self->m_toastsPosted, self->m_toastsClosed,
                                      self->m_toasts->ShownCount(), self->m_toasts->WaitingCount())
                                   .AsView());
    };
    m_toasts->SetOnPosted([self, tell](gui::ToastId, const gui::ToastCard&)
    {
        ++self->m_toastsPosted;
        tell();
    });
    m_toasts->SetOnDismissed([self, tell](gui::ToastId, bool byUser)
    {
        self->m_toastsClosed += byUser ? 1u : 0u;
        tell();
    });
    const auto text = [](gui::ToastSeverity severity, const char8_t* title, const char8_t* message)
    {
        gui::ToastRequest request;
        request.Severity = severity;
        request.Title = String(title);
        request.Message = String(message);
        return request;
    };
    const auto button = [&section](const char8_t* id, Function<void()> click)
    {
        if (auto* found = Cast<gui::Button>(FindById(section, id)))
            found->SetOnClick(Move(click));
    };
    button(u8"toast-info", [self, text]() { (void)self->m_toasts->Post(text(gui::ToastSeverity::Info, u8"", u8"Autosaved the scene.")); });
    button(u8"toast-success", [self, text, toastSaid]()
    {
        gui::ToastRequest request = text(gui::ToastSeverity::Success, u8"Exported", u8"Town exported to Dist/Town.");
        request.Actions.PushBack(gui::ToastAction{String(u8"reveal"), String(u8"Reveal"), {}});
        (void)self->m_toasts->Post(Move(request), [toastSaid](const gui::ToastAction&)
        {
            if (toastSaid != nullptr)
                toastSaid->SetText(StringView(u8"Revealed Dist/Town (the toast's action)."));
        });
    });
    button(u8"toast-warning", [self, text]()
    {
        (void)self->m_toasts->Post(text(gui::ToastSeverity::Warning, u8"Large textures", u8"3 textures are larger than 4096 pixels."));
    });
    button(u8"toast-error", [self, text]()
    {
        gui::ToastRequest request = text(gui::ToastSeverity::Error, u8"Cook failed", u8"Models/Fox.glb: the material [b]fur[/b] is missing.");
        request.Rich = true;
        (void)self->m_toasts->Post(Move(request));
    });
    button(u8"toast-repeat", [self, text]()
    {
        gui::ToastRequest request = text(gui::ToastSeverity::Warning, u8"", u8"Shader compiled with a warning.");
        request.Key = String(u8"shader");
        (void)self->m_toasts->Post(Move(request));
    });
    button(u8"toast-progress", [self, text]()
    {
        self->m_cookPercent = self->m_cookPercent >= 100 ? 20 : self->m_cookPercent + 20;
        const bool done = self->m_cookPercent >= 100;
        gui::ToastRequest request = done ? text(gui::ToastSeverity::Success, u8"Cooked", u8"Every asset is cooked.")
                                         : text(gui::ToastSeverity::Info, u8"Cooking", u8"");
        if (!done)
        {
            request.Message = Format(u8"{}% of the assets, click again to go on.", self->m_cookPercent);
            request.Duration = 0.0f; // until it is done
        }
        request.Key = String(u8"cook");
        (void)self->m_toasts->Post(Move(request));
    });
    button(u8"toast-widget", [self]()
    {
        auto content = MakeRef<gui::Panel>(AppRoot());
        content->EditLayoutStyle([](gui::LayoutStyle& s)
        {
            s.Direction = gui::FlexDirection::Column;
            s.RowGap = 6.0f;
        });
        auto label = MakeRef<gui::Label>(AppRoot());
        label->SetText(StringView(u8"Baking the lights of Town"));
        auto bar = MakeRef<gui::ProgressBar>(AppRoot());
        bar->AddClass(StringView(u8"toast-progress"));
        bar->SetValue(0.6);
        content->AddChild(label.Get());
        content->AddChild(bar.Get());
        content->SetAccessLabel(String(u8"Baking the lights of Town, 60 percent"));
        gui::ToastRequest request;
        request.Content = content;
        (void)self->m_toasts->Post(Move(request));
    });
    button(u8"toast-bare", [self]()
    {
        auto banner = MakeRef<gui::Label>(AppRoot());
        banner->AddClass(StringView(u8"achievement"));
        banner->SetText(StringView(u8"Achievement: First steps"));
        gui::ToastRequest request;
        request.Content = banner;
        request.Bare = true;
        request.Announcement = String(u8"Achievement unlocked: First steps");
        (void)self->m_toasts->Post(Move(request));
    });
    button(u8"toast-thread", [self]()
    {
        gui::ToastHost* host = self->m_toasts.Get();
        Thread worker([host]()
        {
            gui::ToastRequest request;
            request.Title = String(u8"From a worker");
            request.Message = String(u8"Posted from another thread, shown on the GUI's next frame.");
            (void)host->PostFromAnyThread(Move(request));
        });
        worker.Join();
    });
    button(u8"toast-clear", [self]() { self->m_toasts->DismissAll(); });
}

void GUISandbox::FillGraphs(gui::Node& section)
{
    m_graphFormat = MakeUnique<sandbox::XmlTextFormat>(AppRoot(), AppRoot());
    const Color floatColor{0.55f, 0.85f, 0.45f, 1.0f}, colorColor{0.95f, 0.72f, 0.3f, 1.0f};
    const auto pin = [floatColor, colorColor](const char8_t* name, gui::GraphPinDirection direction, const char8_t* type)
    {
        gui::GraphPinInfo info;
        info.Name = String(name);
        info.Direction = direction;
        info.Type = String(type);
        info.TypeColor = StringView(type) == StringView(u8"color") ? colorColor : floatColor;
        info.Many = direction == gui::GraphPinDirection::Output;
        return info;
    };
    const auto in = [pin](const char8_t* name, const char8_t* type) { return pin(name, gui::GraphPinDirection::Input, type); };
    const auto out = [pin](const char8_t* name, const char8_t* type) { return pin(name, gui::GraphPinDirection::Output, type); };
    const auto node = [](const char8_t* type, const char8_t* title, Color header)
    {
        gui::GraphNodeInfo info;
        info.Type = String(type);
        info.Title = String(title);
        info.HeaderColor = header;
        return info;
    };
    const Color values{0.27f, 0.47f, 0.73f, 1.0f}, maths{0.36f, 0.55f, 0.36f, 1.0f}, colour{0.66f, 0.45f, 0.22f, 1.0f}, output{0.6f, 0.3f, 0.35f, 1.0f};

    m_flow.Set = MakeUnique<gui::GraphSet>(AppRoot());
    gui::GraphSet& flow = *m_flow.Set;
    gui::GraphNodeInfo number = node(u8"number", u8"Number", values);
    number.Pins.PushBack(out(u8"value", u8"float"));
    gui::GraphNodeInfo tone = node(u8"colour", u8"Colour", values);
    tone.Pins.PushBack(out(u8"color", u8"color"));
    gui::GraphNodeInfo mix = node(u8"mix", u8"Mix", maths);
    mix.Pins.PushBack(in(u8"a", u8"float"));
    mix.Pins.PushBack(in(u8"b", u8"float"));
    mix.Pins.PushBack(in(u8"amount", u8"float"));
    mix.Pins.PushBack(out(u8"result", u8"float"));
    gui::GraphNodeInfo multiply = node(u8"multiply", u8"Multiply", maths);
    multiply.Pins.PushBack(in(u8"a", u8"float"));
    multiply.Pins.PushBack(in(u8"b", u8"float"));
    multiply.Pins.PushBack(out(u8"result", u8"float"));
    gui::GraphNodeInfo tint = node(u8"tint", u8"Tint", colour);
    tint.Pins.PushBack(in(u8"color", u8"color"));
    tint.Pins.PushBack(in(u8"amount", u8"float"));
    tint.Pins.PushBack(out(u8"color", u8"color"));
    gui::GraphNodeInfo lamp = node(u8"lamp", u8"Lamp", output);
    lamp.Subtitle = String(u8"Lamp A");
    lamp.Pins.PushBack(in(u8"intensity", u8"float"));
    lamp.Pins.PushBack(in(u8"color", u8"color"));
    lamp.Deletable = false;
    flow.AddNodeType(gui::GraphNodeType{String(u8"number"), String(u8"Number"), String(u8"Values")}, number);
    flow.AddNodeType(gui::GraphNodeType{String(u8"colour"), String(u8"Colour"), String(u8"Values")}, tone);
    flow.AddNodeType(gui::GraphNodeType{String(u8"mix"), String(u8"Mix"), String(u8"Maths")}, mix);
    flow.AddNodeType(gui::GraphNodeType{String(u8"multiply"), String(u8"Multiply"), String(u8"Maths")}, multiply);
    flow.AddNodeType(gui::GraphNodeType{String(u8"tint"), String(u8"Tint"), String(u8"Colour")}, tint);
    const auto place = [](gui::GraphNodeInfo info, f32 x, f32 y, const char8_t* subtitle)
    {
        info.Position = Float2{x, y};
        if (subtitle != nullptr)
            info.Subtitle = String(subtitle);
        return info;
    };
    const gui::GraphId low = flow.AddNode(place(number, 0.0f, 0.0f, u8"5"));
    const gui::GraphId high = flow.AddNode(place(number, 0.0f, 112.0f, u8"14"));
    const gui::GraphId mixed = flow.AddNode(place(mix, 224.0f, 32.0f, nullptr));
    const gui::GraphId warm = flow.AddNode(place(tone, 224.0f, 208.0f, u8"warm white"));
    const gui::GraphId tinted = flow.AddNode(place(tint, 432.0f, 192.0f, nullptr));
    const gui::GraphId lit = flow.AddNode(place(lamp, 640.0f, 96.0f, nullptr));
    const auto link = [&flow](gui::GraphId from, const char8_t* output, gui::GraphId to, const char8_t* input)
    {
        gui::GraphLinkInfo made;
        made.FromNode = from;
        made.FromPin = flow.FindPin(from, StringView(output), gui::GraphPinDirection::Output);
        made.ToNode = to;
        made.ToPin = flow.FindPin(to, StringView(input), gui::GraphPinDirection::Input);
        (void)flow.AddLink(made);
    };
    link(low, u8"value", mixed, u8"a");
    link(high, u8"value", mixed, u8"b");
    link(mixed, u8"result", lit, u8"intensity");
    link(warm, u8"color", tinted, u8"color");
    link(tinted, u8"color", lit, u8"color");
    WireGraph(m_flow, section, StringView(u8"flow"), {});

    // The lamp's states.
    m_states.Set = MakeUnique<gui::GraphSet>(AppRoot());
    gui::GraphSet& states = *m_states.Set;
    states.SetNodeLinks(true);
    gui::GraphNodeInfo state = node(u8"state", u8"State", Color{0.4f, 0.42f, 0.5f, 1.0f});
    states.AddNodeType(gui::GraphNodeType{String(u8"state"), String(u8"State"), String(u8"States")}, state);
    const gui::GraphId off = states.AddNode(place(node(u8"state", u8"Off", Color{0.32f, 0.34f, 0.4f, 1.0f}), 0.0f, 64.0f, u8"intensity 0"));
    const gui::GraphId on = states.AddNode(place(node(u8"state", u8"On", Color{0.75f, 0.6f, 0.25f, 1.0f}), 256.0f, 0.0f, u8"steady"));
    const gui::GraphId flicker = states.AddNode(place(node(u8"state", u8"Flicker", Color{0.7f, 0.4f, 0.2f, 1.0f}), 256.0f, 160.0f, u8"its Flicker curve"));
    const auto transition = [&states](gui::GraphId from, gui::GraphId to)
    {
        gui::GraphLinkInfo made;
        made.Kind = gui::GraphLinkKind::Nodes;
        made.FromNode = from;
        made.ToNode = to;
        (void)states.AddLink(made);
    };
    transition(off, on);
    transition(on, off);
    transition(on, flicker);
    transition(flicker, on);
    m_lampState = on;
    auto* view = Cast<gui::GraphView>(FindById(section, u8"states-graph"));
    auto* said = Cast<gui::Label>(FindById(section, u8"states-said"));
    GUISandbox* self = this;
    const auto show = [self, view]()
    {
        if (view == nullptr)
            return;
        const gui::GraphNodeInfo* active = self->m_states.Set->GetNode(self->m_lampState);
        if (active == nullptr)
            self->m_lampState = 0;
        view->SetHighlightedNodes(Span<const gui::GraphId>(&self->m_lampState, active != nullptr ? 1 : 0));
        Array<gui::GraphId> leaving;
        for (const gui::GraphLinkInfo& at : self->m_states.Set->State().Links)
            if (at.Kind == gui::GraphLinkKind::Nodes && at.FromNode == self->m_lampState)
                leaving.PushBack(at.Id);
        view->SetHighlightedLinks(leaving.AsSpan());
    };
    WireGraph(m_states, section, StringView(u8"states"), show);
    show();
    if (view != nullptr)
        view->SetOnNodeDoubleClick([self, show, said](gui::GraphId chosen)
        {
            const gui::GraphNodeInfo* info = self->m_states.Set->GetNode(chosen);
            if (info == nullptr)
                return;
            self->m_lampState = chosen;
            show();
            if (said != nullptr)
                said->SetText(Format(u8"The lamp is {}.", info->Title).AsView());
        });
}

// The clip's tracks at `time` played into the lamps they name ("Lamp B.intensity": Lamp B's intensity).
void GUISandbox::PlayClip(f32 time)
{
    if (!m_clip || !m_lamps)
        return;
    for (usize c = 0; c < m_clip->CurveCount(); ++c)
    {
        const String path = m_clip->GetChannelPath(c);
        usize dot = 0;
        while (dot < path.Size() && path[dot] != u8'.')
            ++dot;
        if (dot >= path.Size())
            continue;
        const usize lamp = m_lamps->FindLamp(path.AsView().SubStr(0, dot));
        const Span<const CurveKey> keys = m_clip->GetKeys(c);
        if (!keys.IsEmpty())
            m_lamps->SetAnimatedValue(lamp, path.AsView().SubStr(dot + 1, path.Size() - dot - 1), static_cast<f64>(EvaluateCurve(keys, time)));
    }
}

// A change back (undo) or again (redo), on the cameras it was made on.
void GUISandbox::StepCameras(bool undo)
{
    Array<CameraStep>& from = undo ? m_cameraUndo : m_cameraRedo;
    Array<CameraStep>& to = undo ? m_cameraRedo : m_cameraUndo;
    if (from.IsEmpty())
        return;
    CameraStep step = Move(from.Back());
    from.PopBack();
    if (step.Selection != m_cameraSelection)
        SelectCameras(step.Selection);
    (void)m_reflected->Restore(step.Change, undo);
    if (m_cameraSaid != nullptr)
        m_cameraSaid->SetText((undo ? Format(u8"Undid: {}", step.Change.Words) : Format(u8"Redid: {}", step.Change.Words)).AsView());
    to.PushBack(Move(step));
}

// The Docking page's floats in OS windows of their own (`own`), or in the area. A window's root is
// styled as the page is, its sheet scoped to the page reaching no other root.
void GUISandbox::SetDockWindows(bool own)
{
    if (!m_dockArea || own == (m_dockWindows.Get() != nullptr))
        return;
    if (own)
    {
        if (!m_guiHost->CanOpenWindows())
            return;
        m_dockWindows = MakeUnique<gui::DockHostWindows>(AppRoot(), AppRoot(), *m_guiHost, *m_dockArea);
        GUISandbox* self = this;
        m_dockWindows->SetOnRootMade([self](gui::SceneRoot& root)
        {
            for (const Page& page : self->m_pages)
                if (page.id == StringView(u8"docking"))
                    (void)self->m_styles->SetSubtreeSheet(root, gui::CSSParser::Parse(page.sheet.AsView(), u8"pages/docking.css"));
        });
        m_dockArea->SetWindows(m_dockWindows.Get());
        if (m_dockArea->GetWindows() == nullptr)
            m_dockWindows.Reset(); // a window would not open: the floats stayed in the area
    }
    else
    {
        m_dockArea->SetWindows(nullptr);
        m_dockWindows.Reset();
    }
    if (auto* button = m_root ? Cast<gui::Button>(FindById(*m_root, u8"docking-windows")) : nullptr)
        button->SetText(m_dockWindows ? u8"Floats in OS windows" : u8"Floats in the window");
}

// The Viewport page's camera, framing the cube.
void GUISandbox::ResetCamera()
{
    m_camera.position = Float3{0.0f, 0.0f, 4.5f};
    m_camera.yaw = 0.0f;
    m_camera.pitch = 0.0f;
    m_camera.moveSpeed = 4.0f;
    m_camera.fastSpeed = 12.0f;
}

// F12: the next frame, to <user data>/screenshots.
void GUISandbox::RequestScreenshot()
{
    const String dir = PathJoin(GetUserDataDirectory().AsView(), u8"screenshots");
    if (!CreateDirectories(dir.AsView()))
    {
        std::fprintf(stderr, "GUISandbox: could not create the screenshots directory\n");
        return;
    }
    m_screenshot.Request(PathJoin(dir.AsView(), Format(u8"gui-sandbox-{}-{}.png", ProcessId(), ++m_screenshotSerial).AsView()).AsView());
}

// A screenshot recorded last frame: once the GPU has run it (a one-off, so wait for all), map,
// write, and honour --screenshot-exit.
void GUISandbox::FinishScreenshot()
{
    if (!m_screenshot.Recorded())
        return;
    m_device->WaitIdle();
    image::Image written;
    if (m_screenshot.Complete(*m_device, AppRoot(), written).IsOk())
        std::printf("GUISandbox: screenshot written to %s\n", reinterpret_cast<const char*>(String(m_screenshot.Path()).CStr()));
    if (m_screenshotExitPending)
        Exit();
}

// The image tests (E8g): each page shown, run on a fixed clock at a fixed size and scale 1, drawn
// offscreen and read back through the RHI, so the backend in use is the one tested; the picture
// goes to --image-out, and is compared with its reference under Data/Tests/GUI/Images: its own
// backend's when there is one, else the one the backends share. A miss writes a diff beside the
// picture. --approve-images writes the shared reference (or, with "backend", this backend's own),
// which is for after the user has looked at the pictures.
void GUISandbox::RunImageTests()
{
    if (m_imagePages.IsEmpty() && m_imagePage == 0)
    {
        for (const Page& page : m_pages)
            if (page.id.AsView() != StringView(u8"stress")) // its numbers are the machine's
            {
                m_imagePages.PushBack(page.id);
                if (page.id.AsView() == StringView(u8"language"))
                    m_imagePages.PushBack(String(u8"language@ar")); // and right to left, in Arabic (E9e)
            }
        if (!m_offscreen || !m_offscreen->IsReady())
        {
            std::printf("GUISandbox: image tests: no offscreen target\n");
            Exit();
            return;
        }
        (void)CreateDirectories(m_imageOut.AsView());
    }
    if (m_imagePage >= m_imagePages.Size())
    {
        std::printf("GUISandbox: image tests on %s: %u pictures, %u failed\n", reinterpret_cast<const char*>(m_backendName.CStr()),
                    m_imagesDone, m_imageFailures);
        std::fflush(stdout);
        Exit();
        return;
    }
    // "<page>@<language>": the page in that language; any other in English. Pictured as
    // <page>.<language>.
    const String& entry = m_imagePages[m_imagePage];
    usize at = entry.Size();
    for (usize i = 0; i < entry.Size(); ++i)
        if (entry[i] == u8'@')
            at = i;
    const bool another = at < entry.Size();
    const StringView pageId = entry.AsView().SubStr(0, at);
    const StringView language = another ? entry.AsView().SubStr(at + 1, entry.Size() - at - 1) : StringView(u8"en");
    const String id = another ? Format(u8"{}.{}", pageId, language) : entry;
    if (m_imageFrame == 0)
    {
        if (m_localization.Language() != language || m_localization.GetPseudolocalization().Enabled)
            SetLanguage(language);
        ShowPage(pageId);
    }
    // A fixed size and scale and a fixed clock: the same frames on every machine.
    m_root->SetDisplayScale(1.0f);
    m_root->SetViewportSize(Float2{static_cast<f32>(kImageWidth), static_cast<f32>(kImageHeight)});
    LayOutShell();
    m_gui->Update(Duration::FromSeconds(1.0 / 60.0));
    m_styles->SetMediaContext(m_root->GetMediaContext());
    m_styles->ApplyTree(*m_root);
    m_root->UpdateLayout();
    if (++m_imageFrame < kImageFrames)
        return;
    m_imageFrame = 0;
    ++m_imagePage;

    const String name = Format(u8"{}.{}", id, m_backendName);
    const String picturePath = PathJoin(m_imageOut.AsView(), Format(u8"{}.png", name).AsView());
    image::Image picture;
    // A frame first, uncaptured, when a picture is waiting to be baked: the capture shows the
    // page as every frame after its first does.
    if (gui::GpuPictureBaker* baker = m_guiHost->Baker())
    {
        const u64 bakes = baker->Generation();
        (void)m_offscreen->Draw(*m_root);
        if (baker->Generation() != bakes)
            (void)m_root->NeedsFrame(); // the root redraws from the bakes
    }
    if (!m_offscreen->Picture(*m_root, picturePath.AsView(), picture))
    {
        std::printf("GUISandbox: image %s: could not be drawn\n", reinterpret_cast<const char*>(name.CStr()));
        ++m_imageFailures;
        return;
    }
    ++m_imagesDone;
    const String shared = DataPath(Format(u8"Tests/GUI/Images/{}.png", id).AsView());
    const String own = DataPath(Format(u8"Tests/GUI/Images/{}.png", name).AsView());
    if (m_approve.Size() != 0)
    {
        const String& to = m_approve.AsView() == StringView(u8"backend") ? own : shared;
        (void)CreateDirectories(DataPath(u8"Tests/GUI/Images").AsView());
        const bool saved = image::io::SaveImage(picture, to.AsView(), image::io::ImageFileFormat::PNG).IsOk();
        std::printf("GUISandbox: image %s: %s %s\n", reinterpret_cast<const char*>(name.CStr()), saved ? "approved as" : "could not write",
                    reinterpret_cast<const char*>(to.CStr()));
        m_imageFailures += saved ? 0u : 1u;
        return;
    }
    const String& referencePath = FileExists(own.AsView()) ? own : shared;
    image::Image reference;
    if (!FileExists(referencePath.AsView()) || !image::io::LoadImage(referencePath.AsView(), reference).IsOk())
    {
        std::printf("GUISandbox: image %s: FAIL, no reference (look at %s, then --approve-images)\n",
                    reinterpret_cast<const char*>(name.CStr()), reinterpret_cast<const char*>(picturePath.CStr()));
        ++m_imageFailures;
        return;
    }
    reference = reference.ConvertFormat(image::PixelFormat::RGBA8);
    image::Image diff;
    const gui::testing::ImageComparison result = gui::testing::CompareImages(picture, reference, 8, 0.001, &diff);
    if (result.Matches)
    {
        std::printf("GUISandbox: image %s: ok (%llu pixels past 8, largest difference %u)\n", reinterpret_cast<const char*>(name.CStr()),
                    static_cast<unsigned long long>(result.Differing), result.LargestDelta);
        return;
    }
    ++m_imageFailures;
    const String diffPath = PathJoin(m_imageOut.AsView(), Format(u8"{}.diff.png", name).AsView());
    if (result.SameSize)
        (void)image::io::SaveImage(diff, diffPath.AsView(), image::io::ImageFileFormat::PNG);
    std::printf("GUISandbox: image %s: FAIL against %s: %s%llu of %llu pixels past 8 (largest %u); see %s\n",
                reinterpret_cast<const char*>(name.CStr()), reinterpret_cast<const char*>(referencePath.CStr()),
                result.SameSize ? "" : "not the same size; ", static_cast<unsigned long long>(result.Differing),
                static_cast<unsigned long long>(result.Pixels), result.LargestDelta, reinterpret_cast<const char*>(diffPath.CStr()));
}

// The bench (E15): settle the page, then time frames that each change the page title's text.
void GUISandbox::RunBench()
{
    constexpr u32 kSettle = 30;
    if (m_benchFrame == 0)
    {
        if (!m_offscreen || !m_offscreen->IsReady())
        {
            std::printf("GUISandbox: bench: no offscreen target\n");
            Exit();
            return;
        }
        ShowPage(m_benchPage.AsView());
    }
    m_root->SetDisplayScale(1.0f);
    m_root->SetViewportSize(Float2{static_cast<f32>(kImageWidth), static_cast<f32>(kImageHeight)});
    const u32 measured = m_benchFrame >= kSettle ? m_benchFrame - kSettle : 0u;
    if (m_benchFrame >= kSettle)
        for (Page& p : m_pages)
            if (p.id == m_benchPage && p.node != nullptr && p.node->ChildCount() > 0)
                if (gui::Label* title = Cast<gui::Label>(p.node->GetChildAt(0))) // the page's title
                    title->SetText(Format(u8"{} {}", m_benchPage, measured).AsView());
    LayOutShell();
    m_gui->Update(Duration::FromSeconds(1.0 / 60.0));
    m_styles->SetMediaContext(m_root->GetMediaContext());
    m_styles->ApplyTree(*m_root);
    m_root->UpdateLayout();
    gui::GuiOffscreen::Times times;
    if (!m_offscreen->Draw(*m_root, &times))
    {
        std::printf("GUISandbox: bench: a frame could not be drawn\n");
        Exit();
        return;
    }
    if (m_benchFrame++ < kSettle)
        return;
    const gui::FrameStats& stats = m_root->GetLastFrameStats();
    m_bench.Draw += stats.DrawMs;
    m_bench.Prepare += times.Prepare;
    m_bench.Gpu += times.Gpu;
    m_bench.Vertices += stats.Vertices;
    m_bench.Commands += stats.Commands;
    m_bench.Drawn += stats.NodesDrawn;
    m_bench.Culled += stats.NodesCulled;
    const gui::Rect& damage = m_root->GetLastDamageBounds();
    m_bench.Damaged += static_cast<f64>(damage.width * damage.height) / static_cast<f64>(kImageWidth * kImageHeight);
    if (measured + 1 < m_benchFrames)
        return;
    const f64 n = static_cast<f64>(m_benchFrames);
    std::printf("GUISandbox bench %s on %s, %u frames, %ux%u, each changing one label: draw %.3f ms, prepare %.3f ms, gpu+wait %.3f ms; "
                "%.0f nodes drawn, %.0f culled, %.0f vertices, %.0f commands; damage %.1f%% of the window\n",
                reinterpret_cast<const char*>(m_benchPage.CStr()), reinterpret_cast<const char*>(m_backendName.CStr()), m_benchFrames,
                kImageWidth, kImageHeight, m_bench.Draw / n, m_bench.Prepare / n, m_bench.Gpu / n, static_cast<f64>(m_bench.Drawn) / n,
                static_cast<f64>(m_bench.Culled) / n, static_cast<f64>(m_bench.Vertices) / n, static_cast<f64>(m_bench.Commands) / n,
                100.0 * m_bench.Damaged / n);
    std::fflush(stdout);
    Exit();
}

void GUISandbox::OnShutdown(runtime::IApplicationHost&)
{
    if (!m_guiHost)
        return;
    std::printf("GUISandbox: drew %llu of %llu frames\n", static_cast<unsigned long long>(m_guiHost->FramesDrawn()),
                static_cast<unsigned long long>(m_frames));
    m_device->WaitIdle();
    if (m_gui)
        gui::InputPrompts::Uninstall(*m_gui); // the GUI may outlive the menu's actions
    // Scripts first: their handles and handlers reach the trees.
    const auto closeScript = [](RefPtr<script::IScriptContext>& context)
    {
        if (!context)
            return;
        gui::ClearGuiScriptService(*context);
        context->SetErrorHandler(nullptr);
        context.Reset();
    };
    for (Page& page : m_pages)
        closeScript(page.script);
    closeScript(m_menuScript);
    m_scripts.Reset();
    m_screenshot.Release(*m_device); // its readback buffer
    m_cube.Shutdown();
    if (m_cubeCompiler != nullptr)
        m_cubeCompiler->Destroy();
    m_cubeCompiler = nullptr;
    m_offscreen.Reset();
    // The Docking page's float windows close first (their roots on the GUI's context).
    SetDockWindows(false);
    // The window's panes leave the host (their renderer forgets the bakes) before the trees go.
    if (m_guiHost->WindowFor(m_root.Get()) != nullptr)
        m_guiHost->DetachWindow(*m_mainWindow);
    m_inspector.Reset(); // its root on the GUI's context, before the context
    m_pages.Clear();
    m_contextMenu.Reset();
    m_floating.Reset();
    m_dialog.Reset();
    m_shellNode.Reset();
    m_viewport.Reset(); // its targets go with the tree, while the host and the device are here
    m_dockArea.Reset();
    m_root.Reset(); // the widgets go with the tree, before the models they read
    m_dock.Reset(); // after the dock space that showed its layout
    m_menu.Reset();
    m_gui.Reset();
    m_tableProxy.Reset();
    m_tableModel.Reset();
    m_listModel.Reset();
    m_treeModel.Reset();
    m_checker.Reset();
    m_styles = nullptr;
    m_guiHost.Reset(); // the context, the baker
    m_fontService.Reset();
    m_shaders.Reset(); // the shader modules are its, the host drew with them
}

int main(int argc, char** argv)
{
    GUISandbox app;
    // --page <id>: open on that page (controls, text, layout, data-views, menus, styling, effects,
    // motion, binding, navigation, game-menu). --showcase: open the game menu at once.
    // --menu-call <function>: call one of the game menu's script functions once it is up (onSettings,
    // onPlay, onQuit). --keys "<keys>": type keystrokes into what is shown, one every 15 frames
    // (pointer steps too, in logical units: click:x,y rclick:x,y move:x,y down:x,y up:x,y, or at
    // what a selector or a text finds: click:#ok, click:text=Show, move:text~=Sett)
    // ("down down return", "pad-east"). --always-redraw: draw every frame. --frame-stats: print,
    // each second, how many frames drew. --sweep: hover, click and right-click every widget of every
    // page, then open the game menu, printing each step, and exit (a smoke test; a crash's last line
    // names its widget). --scroll <px>: scroll the page down that far once it is up.
    // --layout-overlay: start with the layout overlay on (F9 toggles it). --input-overlay: start with
    // the input overlay on (F8 toggles it: focus path, tab order, navigation, pointer, redraws).
    // --inspector: start with the inspector's pane open (Ctrl+Shift+I toggles it). --inspect <selector>:
    // open it with the first widget the selector matches selected. --image-tests: draw each page
    // offscreen at 960x720 on a fixed clock and compare it with its reference (Data/Tests/GUI/
    // Images; the pictures go to --image-out <dir>, build/gui-images by default; exit 1 on a miss,
    // 77 with no device); --approve-images [backend]: write them as the references instead, after
    // looking at them. --lang <locale>: start in that language (en, ar, or pseudo: English
    // pseudolocalized). --narrate: print what a screen reader would say (each focus change and
    // announcement). --stress <n>: start on
    // the Stress page, built at load n (1 to 20; measure in RelWithDebInfo). With the
    // framework's --screenshot flags, a picture of any of it.
    for (int i = 1; i < argc; ++i)
    {
        const StringView arg(reinterpret_cast<const utf8char*>(argv[i]));
        const auto next = [&]() { return StringView(reinterpret_cast<const utf8char*>(argv[++i])); };
        if (arg == StringView(u8"--page") && i + 1 < argc)
            app.SetStartPage(next());
        else if (arg == StringView(u8"--showcase"))
            app.SetOpenMenu(true);
        else if (arg == StringView(u8"--light"))
            app.SetLightAtStart(true);
        else if (arg == StringView(u8"--menu-call") && i + 1 < argc)
            app.SetMenuCall(next());
        else if (arg == StringView(u8"--keys") && i + 1 < argc)
            app.SetKeys(next());
        else if (arg == StringView(u8"--always-redraw"))
            app.SetAlwaysRedraw(true);
        else if (arg == StringView(u8"--frame-stats"))
            app.SetFrameStats(true);
        else if (arg == StringView(u8"--sweep"))
            app.SetSweep(true);
        else if (arg == StringView(u8"--mirror-audit"))
            app.SetMirrorAudit(true);
        else if (arg == StringView(u8"--soak") && i + 1 < argc)
            app.SetSoak(static_cast<f32>(std::atof(argv[++i])));
        else if (arg == StringView(u8"--soak-csv") && i + 1 < argc)
            app.SetSoakCsv(next());
        else if (arg == StringView(u8"--layout-overlay"))
            app.SetLayoutOverlay(true);
        else if (arg == StringView(u8"--input-overlay"))
            app.SetInputOverlay(true);
        else if (arg == StringView(u8"--inspector"))
            app.SetOpenInspector(true);
        else if (arg == StringView(u8"--image-tests"))
            app.SetImageTests(true);
        else if (arg == StringView(u8"--bench") && i + 1 < argc)
        {
            const StringView page = next();
            u32 frames = 300;
            if (i + 1 < argc)
                if (Optional<f32> n = gui::ParseLength(StringView(reinterpret_cast<const char8_t*>(argv[i + 1]))); n.HasValue())
                {
                    frames = static_cast<u32>(n.Value());
                    (void)next();
                }
            app.SetBench(page, frames);
        }
        else if (arg == StringView(u8"--approve-images"))
            app.SetApproveImages(i + 1 < argc && StringView(reinterpret_cast<const char8_t*>(argv[i + 1])) == StringView(u8"backend") ? next() : StringView(u8"shared"));
        else if (arg == StringView(u8"--image-out") && i + 1 < argc)
            app.SetImageOut(next());
        else if (arg == StringView(u8"--webgpu") || arg == StringView(u8"--wgpu"))
            app.SetBackendName(u8"webgpu");
        else if (arg == StringView(u8"--dx12") || arg == StringView(u8"--d3d12"))
            app.SetBackendName(u8"dx12");
        else if (arg == StringView(u8"--inspect") && i + 1 < argc)
            app.SetInspectSelector(next());
        else if (arg == StringView(u8"--lang") && i + 1 < argc)
            app.SetStartLanguage(next());
        else if (arg == StringView(u8"--narrate"))
            app.SetNarrate(true);
        else if (arg == StringView(u8"--stress") && i + 1 < argc)
            app.SetStress(std::atoi(reinterpret_cast<const char*>(argv[++i])));
        else if (arg == StringView(u8"--scroll") && i + 1 < argc)
            app.SetScroll(static_cast<f32>(std::atof(reinterpret_cast<const char*>(argv[++i]))));
    }
    app.SetScreenshots(rhi::ScreenshotOptionsFromArguments(argc, argv));

    shell::WindowSettings settings;
    settings.title = u8"GUI Sandbox";
    settings.width = 960;
    settings.height = 820;
    settings.drawsTextComposition = true; // its fields show an IME's composition in place
    UniquePtr<shell::IShell> shellPtr = shell::CreateShell(AppRoot(), settings);
    if (shellPtr.Get() == nullptr || shellPtr->MainWindow() == nullptr)
        return app.ImageExitCode(1);
    Result<UniquePtr<graphics::GraphicsDevice>> device = graphics::CreateGraphicsDevice(graphics::DeviceDescFromArguments(argc, argv));
    if (!device.HasValue())
        return app.ImageExitCode(1); // 77 for the image tests and the sweep: no device to test
    return app.ImageExitCode(runtime::RunApplication(app, *shellPtr, device.Value().Get()));
}
