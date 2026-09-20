using Sedulous.Graphics;
using Sedulous.Runtime.Client;
using Sedulous.UI;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.App;

/// The UI-side extension of the headless EditorPage: a page that owns a content view, docked
/// as a closable centre tab by EditorApplication, and receives the app's frame hooks so it can
/// drive per-page work (viewport binding, camera, offscreen rendering). Every page factory
/// registered into this app's context must produce UIEditorPages; the headless EditorPage
/// stays UI-free for core tests, and this is the one seam where pages meet the UI and runtime.
abstract class UIEditorPage : EditorPage
{
	/// The view docked into the centre document area, owned by the page.
	public abstract View ContentView { get; }

	/// Per frame, after the UI laid out (viewport rects are current).
	public virtual void OnUpdate(IApplicationHost host, float dt) {}

	/// Per window, before the UI draws: offscreen content the UI then samples.
	public virtual void OnRenderWindow(IApplicationHost host, ref FrameContext frame) {}

	/// After the scene renderer's EndRendering, targets composed: overlays that draw on the
	/// page's offscreen content (the Game tab's screen-tier UI).
	public virtual void OnAfterSceneRender(IApplicationHost host, ref FrameContext frame) {}

	/// Right before the page is removed: release GPU and scene resources while the device
	/// and window are still alive.
	public virtual void OnClose() {}
}
