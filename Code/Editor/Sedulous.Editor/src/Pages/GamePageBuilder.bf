namespace Sedulous.Editor;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.UI.Viewport;
using Sedulous.RHI;
using Sedulous.VG.Renderer;
using Sedulous.Editor.Core;
using Sedulous.Engine;
using Sedulous.Engine.Core;
using Sedulous.Engine.Render;
using Sedulous.Engine.DefaultApp;
using Sedulous.Engine.UI;

/// Builds the internal layout for a GameEditorPage:
///   Toolbar (Play / Stop toggle, status text)
///   Viewport (renders module.RuntimeScene through ISceneRenderer)
///
/// Per page-layout convention each editor page lays out independently - this
/// mirrors ScenePageBuilder rather than sharing helpers with it.
static class GamePageBuilder
{
	public static View Build(GameEditorPage page, EditorContext editorContext,
		IDevice device, VGRenderer vgRenderer,
		ISceneRenderer sceneRenderer = null,
		IScreenRenderer screenRenderer = null)
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

		toolbar.AddSeparator();

		// Preview-resolution dropdown. Drives the viewport texture size
		// so PIE simulates rendering at the chosen resolution. Sticking
		// to common presets - Custom dialog is a follow-up.
		let previewCombo = new ComboBox();
		previewCombo.AddItem("Match Viewport");
		previewCombo.AddItem("Project Target");
		previewCombo.AddItem("1920 x 1080");
		previewCombo.AddItem("1280 x 720");
		previewCombo.AddItem("854 x 480");
		previewCombo.SelectedIndex = (int32)page.CurrentPreviewMode == 0 ? 0 : 1;
		previewCombo.OnSelectionChanged.Add(new [=page] (cb, idx) =>
		{
			switch (idx)
			{
			case 0:
				page.CurrentPreviewMode = .MatchViewport;
			case 1:
				page.CurrentPreviewMode = .ProjectTarget;
			case 2:
				page.CustomPreviewWidth = 1920;
				page.CustomPreviewHeight = 1080;
				page.CurrentPreviewMode = .Custom;
			case 3:
				page.CustomPreviewWidth = 1280;
				page.CustomPreviewHeight = 720;
				page.CurrentPreviewMode = .Custom;
			case 4:
				page.CustomPreviewWidth = 854;
				page.CustomPreviewHeight = 480;
				page.CurrentPreviewMode = .Custom;
			}
		});
		toolbar.AddItem(previewCombo);

		// Fit mode dropdown - how the texture maps into the page tab
		// when aspect ratios differ. Default Letterbox preserves the
		// project's design aspect; Crop / Stretch are testing modes.
		let fitCombo = new ComboBox();
		fitCombo.AddItem("Stretch");
		fitCombo.AddItem("Letterbox");
		fitCombo.AddItem("Crop");
		fitCombo.SelectedIndex = (int32)page.PreviewFitMode;
		fitCombo.OnSelectionChanged.Add(new [=page] (cb, idx) =>
		{
			page.PreviewFitMode = (Sedulous.Engine.App.FitMode)idx;
		});
		toolbar.AddItem(fitCombo);

		container.AddView(toolbar, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Wrap
		});

		// === Viewport ===
		let viewportView = new ViewportView();
		viewportView.Initialize(device, vgRenderer);
		container.AddView(viewportView, new FlexLayout.LayoutParams() {
			Width = .Match, Grow = 1
		});

		// Mirror the viewport's live texture dims onto the page so the
		// editor can push them into the runtime UI subsystem each frame.
		// Must be subscribed BEFORE applyPreview() so the initial
		// ResizeRenderTarget fires into this handler and seeds the page
		// with the correct dimensions on the first frame.
		viewportView.OnRenderTargetResized.Add(new [=page] (w, h) =>
		{
			page.ViewportRenderWidth = w;
			page.ViewportRenderHeight = h;
		});

		// Apply the current preview-mode size and stay in sync with future
		// selections from the dropdown. Page-level state is the source of
		// truth; the viewport just mirrors it.
		void applyPreview()
		{
			uint32 pw, ph;
			page.GetEffectivePreviewSize(out pw, out ph);
			viewportView.SetFixedRenderSize(pw, ph);
		}
		applyPreview();
		page.OnPreviewModeChanged.Add(new [=viewportView, =page] (p) =>
		{
			uint32 pw, ph;
			page.GetEffectivePreviewSize(out pw, out ph);
			viewportView.SetFixedRenderSize(pw, ph);
		});

		// Mirror page fit mode onto the viewport. The page-app FitMode
		// enum and ViewportFitMode have matching ordinals so the cast
		// works without a switch.
		viewportView.FitMode = (ViewportFitMode)page.PreviewFitMode;
		page.OnPreviewFitModeChanged.Add(new [=viewportView, =page] (p) =>
		{
			viewportView.FitMode = (ViewportFitMode)page.PreviewFitMode;
		});

		// Route mouse events the editor dispatches into this viewport
		// through EngineUISubsystem.Dispatch*. The subsystem walks the
		// same priority chain (screen UI -> scene HUDs -> billboards) it
		// uses in standalone, so anything the module attaches lights up.
		// The handler self-gates on page.IsRunning, so idle pages don't
		// pump stray clicks at a not-yet-launched game.
		let runtimeUISub = editorContext?.RuntimeContext?.GetSubsystem<EngineUISubsystem>();
		if (runtimeUISub != null)
		{
			let inputHandler = new GameInputHandler(page, runtimeUISub);
			page.AddOwnedObject(inputHandler);
			viewportView.AddInputHandler(inputHandler);
		}

		// Render the first active scene each frame while the page is
		// running. When idle (no Play pressed yet), the viewport stays as a
		// flat clear. No editor camera here - the scene's active
		// CameraComponent drives the view, same as in standalone.
		viewportView.OnRender.Add(new [=page, =sceneRenderer, =screenRenderer] (vp, encoder, frameIndex) =>
		{
			if (!vp.IsReady) return;

			encoder.TransitionTexture(vp.ColorTexture, .Undefined, .RenderTarget);

			Scene renderable = null;
			if (page.IsRunning)
			{
				if (let defaultApp = page.EditorContext?.App as DefaultApplication)
					renderable = defaultApp.RuntimeScene;
			}
			if (sceneRenderer != null && renderable != null)
			{
				ColorAttachment[1] clearAttachments = .(.()
				{
					View = vp.ColorTargetView,
					LoadOp = .Clear,
					StoreOp = .Store,
					ClearValue = .(0, 0, 0, 1)
				});
				RenderPassDesc clearDesc = .() { ColorAttachments = .(clearAttachments) };
				let clearPass = encoder.BeginRenderPass(clearDesc);
				clearPass?.End();

				sceneRenderer.RenderScene(renderable, encoder, vp.ColorTexture,
					vp.ColorTargetView, vp.RenderWidth, vp.RenderHeight, frameIndex);

				// Composite the runtime context's screen overlays (TD's
				// HUD, pause / main-menu, etc.) over the scene render so
				// the game's UI appears inside this page tab instead of
				// the editor's own swapchain. LoadOp.Load inside
				// RenderOverlays preserves the scene pixels.
				//
				// RenderScene leaves the texture in ShaderRead for the
				// editor to sample; RenderOverlays' BeginRenderPass
				// expects RenderTarget. Transition back, run the overlay
				// pass, transition back to ShaderRead.
				if (screenRenderer != null)
				{
					encoder.TransitionTexture(vp.ColorTexture, .ShaderRead, .RenderTarget);
					screenRenderer.RenderOverlays(encoder, vp.ColorTargetView,
						vp.RenderWidth, vp.RenderHeight, frameIndex);
					encoder.TransitionTexture(vp.ColorTexture, .RenderTarget, .ShaderRead);
				}
			}
			else
			{
				// Idle / no module: just clear so the texture leaves the
				// pass in a defined state and reads as a flat background.
				ColorAttachment[1] colorAttachments = .(.()
				{
					View = vp.ColorTargetView,
					LoadOp = .Clear,
					StoreOp = .Store,
					ClearValue = .(0.05f, 0.05f, 0.07f, 1)
				});
				RenderPassDesc passDesc = .() { ColorAttachments = .(colorAttachments) };
				let renderPass = encoder.BeginRenderPass(passDesc);
				renderPass?.End();
				encoder.TransitionTexture(vp.ColorTexture, .RenderTarget, .ShaderRead);
			}
		});

		return container;
	}
}
