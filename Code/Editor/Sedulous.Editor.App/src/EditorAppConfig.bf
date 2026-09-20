using System;
using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// What the executable hands the editor application: the data root, the project to open,
/// the fonts, the log capture, the smoke-test aids, and the assembly seams through which the
/// executable composes the engine and the per-subsystem editor plugins, since this library
/// never links them.
class EditorAppConfig
{
	/// The data root, resolved by main; the editor mounts it once for the UI host's shaders,
	/// the embedded runtime and the export's shader cook. Required.
	public String DataRoot = new .() ~ delete _;
	/// Opened on startup; scaffolded if no manifest yet.
	public String ProjectDirectory = new .() ~ delete _;
	/// The name used when scaffolding.
	public String ProjectName = new .("Untitled") ~ delete _;
	/// The UI font (.ttf); empty means no text.
	public String FontPath = new .() ~ delete _;
	/// The fixed-pitch font (.ttf) for code editors; empty means no Mono family, the code
	/// view falling back to the default family.
	public String MonoFontPath = new .() ~ delete _;
	/// The last-resort face, baked into the exe at build time: loads when both the
	/// preference path and the dev-tree path fail. Empty means no embedded fallback, and the
	/// editor may come up textless, loudly. Borrowed.
	public Span<uint8> EmbeddedFont = .();

	/// The log capture registered on the global logger by main before anything else runs,
	/// so early startup logs reach the console panel. Borrowed; main owns it.
	public EditorLogBuffer LogBuffer = null;

	/// Start on the project manager screen instead of opening ProjectDirectory. File > Close
	/// Project returns to the manager only in this mode; a CLI-opened editor keeps its
	/// single-project lifecycle.
	public bool StartInProjectManager = false;
	/// CLI: when the project directory has no manifest and gets scaffolded, also seed the
	/// starter content the manager's New Project flow seeds.
	public bool SeedOnScaffold = false;

	/// A smoke-test aid: a clean shutdown after this many seconds (0 never), exercising the
	/// real teardown path.
	public float AutoExitSeconds = 0.0f;
	/// A smoke-test aid: Build > Rebuild All after this many seconds (0 never).
	public float AutoRebuildSeconds = 0.0f;

	/// From Configure: registers the engine subsystems. Owned.
	public delegate void(IApplicationHost host) ConfigureEngine ~ delete _;
	/// At the end of OnStartup: the per-subsystem editor registrations, plus wiring the app to
	/// the engine interfaces it drives (SetSceneRenderer). Owned.
	public delegate void(EditorApplication app, IApplicationHost embeddedHost, UIHost uiHost) RegisterEditors ~ delete _;
	/// Seeds starter content into a project the manager just created, once, right after the
	/// fresh project opens; the exe composes it because only the exe links every asset type.
	/// Null means new projects start empty. Owned.
	public delegate void(EditorContext context, EditorProject project) SeedNewProject ~ delete _;
}
