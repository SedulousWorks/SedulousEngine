namespace Sedulous.Editor;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.UI.Viewport;
using Sedulous.RHI;
using Sedulous.VG.Renderer;
using Sedulous.Editor.Core;
using Sedulous.Engine.Render;

/// Builds the internal layout for a GameEditorPage:
///   Toolbar (Play / Stop toggle, status text)
///   Viewport (whole-game viewport, populated in Phase 6C)
///
/// Per page-layout convention each editor page lays out independently - this
/// mirrors ScenePageBuilder rather than sharing helpers with it.
static class GamePageBuilder
{
	public static View Build(GameEditorPage page, EditorContext editorContext,
		IDevice device, VGRenderer vgRenderer, ISceneRenderer sceneRenderer = null)
	{
		let container = new FlexLayout();
		container.Direction = .Vertical;

		// === Toolbar ===
		let toolbar = new Toolbar();
		let playStopBtn = toolbar.AddButton(page.IsRunning ? "Stop" : "Play");
		playStopBtn.OnClick.Add(new [=page] (btn) => {
			if (page.IsRunning) page.StopGame();
			else page.PlayGame();
		});

		// Keep the button label in sync with game state. Page fires this
		// from PlayGame / StopGame after the lifecycle transition completes
		// so the label always reflects the just-applied state.
		page.OnGameStateChanged.Add(new [=playStopBtn] (p) => {
			playStopBtn.SetText(p.IsRunning ? "Stop" : "Play");
		});

		container.AddView(toolbar, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Wrap
		});

		// === Viewport ===
		// Phase 6A/B: empty viewport. Phase 6C wires the OnRender callback
		// up to sceneRenderer.RenderScene with the module's RuntimeScene
		// (only renders when page.IsRunning).
		let viewportView = new ViewportView();
		viewportView.Initialize(device, vgRenderer);
		container.AddView(viewportView, new FlexLayout.LayoutParams() {
			Width = .Match, Grow = 1
		});

		return container;
	}
}
