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
///   Toolbar (Stop)
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
		let stopBtn = toolbar.AddButton("Stop Game");
		stopBtn.OnClick.Add(new [=page, =editorContext] (btn) => {
			// Close deletes this button mid-dispatch. Defer through the
			// UI context's mutation queue so InputManager.DispatchMouseDown
			// doesn't dereference a freed view on unwind.
			let ctx = btn.Context;
			ctx?.MutationQueue.QueueAction(new [=] () => {
				editorContext.PageManager.Close(page);
			});
		});
		container.AddView(toolbar, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Wrap
		});

		// === Viewport ===
		// Phase 6A: empty viewport. Phase 6C wires the OnRender callback up to
		// sceneRenderer.RenderScene with the module's RuntimeScene.
		let viewportView = new ViewportView();
		viewportView.Initialize(device, vgRenderer);
		container.AddView(viewportView, new FlexLayout.LayoutParams() {
			Width = .Match, Grow = 1
		});

		return container;
	}
}
