namespace Sedulous.Editor.App;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;
using Sedulous.Editor.Core;
using Sedulous.Engine.Core;

/// Phase 1 layout for `PropAnimEditorPage`. Three regions in a split:
///
///   - Left: preview source picker + entity hierarchy + (placeholder) track list.
///   - Center: viewport (the host's ViewportView) with the toolbar above it.
///   - Bottom: scrub slider (will be replaced by the real dopesheet in Phase 2).
static class PropAnimPageBuilder
{
	public static View Build(PropAnimEditorPage page)
	{
		// Vertical: toolbar + main split + bottom scrub region.
		let outer = new FlexLayout();
		outer.Direction = .Vertical;

		outer.AddView(BuildToolbar(page), new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Wrap
		});

		// Main split: left panel | viewport.
		let split = new SplitView(.Horizontal);
		split.SetPanes(BuildLeftPanel(page), BuildViewport(page));
		split.SplitRatio = 0.28f;

		outer.AddView(split, new FlexLayout.LayoutParams() {
			Width = .Match, Grow = 1
		});

		outer.AddView(BuildScrubRegion(page), new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(80))
		});

		return outer;
	}

	// === Toolbar ===

	private static View BuildToolbar(PropAnimEditorPage page)
	{
		let bar = new Toolbar();

		let playBtn = bar.AddButton("Play");
		playBtn.OnClick.Add(new [=page] (btn) => { page.Play(); });

		let stopBtn = bar.AddButton("Stop");
		stopBtn.OnClick.Add(new [=page] (btn) => { page.Stop(); });

		bar.AddSeparator();

		let timeLabel = new Label();
		UpdateTimeLabel(timeLabel, page);
		timeLabel.TextColor = .(200, 200, 210, 255);
		bar.AddItem(timeLabel);

		// Refresh time readout when the user scrubs or when playback advances.
		// Phase 1 doesn't watch playback; refreshing on target change is good
		// enough until the slider's OnValueChanged plumbs through to here.
		page.OnTargetChanged.Add(new [=timeLabel] (p) => UpdateTimeLabel(timeLabel, p));

		return bar;
	}

	private static void UpdateTimeLabel(Label label, PropAnimEditorPage page)
	{
		let clip = page.Clip;
		let dur = (clip != null) ? clip.Duration : 0.0f;
		label.SetText(scope $"{page.CurrentTime:0.00}s / {dur:0.00}s");
	}

	// === Left panel: preview source + hierarchy + track list ===

	private static View BuildLeftPanel(PropAnimEditorPage page)
	{
		let container = new FlexLayout();
		container.Direction = .Vertical;
		container.Padding = .(8);
		container.Spacing = 6;

		BuildPreviewSourceSection(container, page);
		BuildHierarchySection(container, page);
		BuildTrackListSection(container, page);

		return container;
	}

	private static void BuildPreviewSourceSection(FlexLayout parent, PropAnimEditorPage page)
	{
		AddSectionHeader(parent, "Preview Source");

		let pathLabel = new Label();
		RefreshPreviewSourceLabel(pathLabel, page);
		pathLabel.TextColor = .(180, 180, 195, 255);
		pathLabel.FontSize = 11;
		parent.AddView(pathLabel, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(18))
		});

		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 4;

		let sceneBtn = new Button("Pick Scene");
		sceneBtn.OnClick.Add(new [=page] (btn) =>
		{
			PickPreviewAsset(page, ".scene");
		});
		row.AddView(sceneBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(90)), Height = .Fixed(.Px(24)) });

		let prefabBtn = new Button("Pick Prefab");
		prefabBtn.OnClick.Add(new [=page] (btn) =>
		{
			PickPreviewAsset(page, ".prefab");
		});
		row.AddView(prefabBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(100)), Height = .Fixed(.Px(24)) });

		let clearBtn = new Button("Clear");
		clearBtn.OnClick.Add(new [=page] (btn) => { page.UnloadPreviewSource(); });
		row.AddView(clearBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(60)), Height = .Fixed(.Px(24)) });

		parent.AddView(row, new FlexLayout.LayoutParams() { Width = .Match, Height = .Wrap });

		page.OnPreviewSourceChanged.Add(new [=pathLabel] (p) => RefreshPreviewSourceLabel(pathLabel, p));
	}

	private static void RefreshPreviewSourceLabel(Label label, PropAnimEditorPage page)
	{
		let path = page.PreviewSourcePath;
		if (path.Length == 0)
		{
			label.SetText("(none)");
			return;
		}
		// Show just the filename - the full path is too long for a side panel.
		let name = scope String();
		System.IO.Path.GetFileName(path, name);
		label.SetText(name);
	}

	private static void PickPreviewAsset(PropAnimEditorPage page, StringView @extension)
	{
		let ctx = page.ContentView?.Context;
		if (ctx == null || page.EditorContext == null) return;

		let dlg = new AssetPickerDialog(page.EditorContext, @extension,
			new [=page] (path, id) =>
			{
				if (page.LoadPreviewSource(path) case .Err)
				{
					page.EditorContext.Logger?.LogWarning("[PropAnim] failed to load preview source: {}", path);
				}
			});
		dlg.Show(ctx);
	}

	private static void BuildHierarchySection(FlexLayout parent, PropAnimEditorPage page)
	{
		AddSectionHeader(parent, "Hierarchy");

		// Flat entity list for Phase 1 - tree comes later when the scene
		// editor's hierarchy widget is extracted into something reusable.
		let listContainer = new ScrollView();
		let list = new FlexLayout();
		list.Direction = .Vertical;
		list.Spacing = 2;
		listContainer.AddView(list, new LayoutParams() { Width = .Match, Height = .Wrap });

		parent.AddView(listContainer, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(220))
		});

		// Built initially empty - PopulateHierarchy fires off OnPreviewSourceChanged.
		PopulateHierarchy(list, page);
		page.OnPreviewSourceChanged.Add(new [=list] (p) => PopulateHierarchy(list, p));
	}

	private static void PopulateHierarchy(FlexLayout list, PropAnimEditorPage page)
	{
		// deleteChildren = true: views are cascade-deleted; without
		// this, every preview reload leaks the previous row buttons.
		list.RemoveAllViews(true);

		let scene = page.Host?.PreviewScene;
		if (scene == null) return;

		// Recursively walk every loaded root.
		for (let root in page.PreviewRoots)
		{
			if (!root.IsAssigned || !scene.IsValid(root)) continue;
			AppendEntity(list, page, scene, root, 0);
		}

		if (list.ChildCount == 0)
		{
			let empty = new Label();
			empty.SetText("(no preview loaded)");
			empty.TextColor = .(140, 140, 155, 255);
			empty.FontSize = 11;
			list.AddView(empty, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(16)) });
		}
	}

	private static void AppendEntity(FlexLayout list, PropAnimEditorPage page, Scene scene, EntityHandle entity, int depth)
	{
		let name = scene.GetEntityName(entity);
		let label = scope String();
		for (int i = 0; i < depth; i++) label.Append("  ");
		label.Append(name.IsEmpty ? "(unnamed)" : name);

		let row = new Button(label);
		row.OnClick.Add(new [=page, =entity] (btn) => { page.SetTarget(entity); });
		list.AddView(row, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(20))
		});

		// Recurse children.
		var child = scene.GetFirstChild(entity);
		while (child.IsAssigned)
		{
			AppendEntity(list, page, scene, child, depth + 1);
			child = scene.GetNextSibling(child);
		}
	}

	private static void BuildTrackListSection(FlexLayout parent, PropAnimEditorPage page)
	{
		AddSectionHeader(parent, "Tracks");

		// Phase 1 placeholder - real dopesheet replaces the bottom region
		// in Phase 2; this side panel will become an editable list view.
		let placeholder = new Label();
		placeholder.SetText(BuildTrackSummary(page, .. scope .()));
		placeholder.TextColor = .(180, 180, 195, 255);
		placeholder.FontSize = 11;
		parent.AddView(placeholder, new FlexLayout.LayoutParams() {
			Width = .Match, Grow = 1
		});

		page.OnTargetChanged.Add(new [=placeholder] (p) =>
		{
			placeholder.SetText(BuildTrackSummary(p, .. scope .()));
		});
	}

	private static void BuildTrackSummary(PropAnimEditorPage page, String outText)
	{
		let clip = page.Clip;
		if (clip == null)
		{
			outText.Set("(no clip)");
			return;
		}

		outText.AppendF("Duration: {:0.00}s\n", clip.Duration);
		outText.AppendF("Float tracks: {}\n", clip.FloatTracks.Count);
		outText.AppendF("Vector2 tracks: {}\n", clip.Vector2Tracks.Count);
		outText.AppendF("Vector3 tracks: {}\n", clip.Vector3Tracks.Count);
		outText.AppendF("Vector4 tracks: {}\n", clip.Vector4Tracks.Count);
		outText.AppendF("Quaternion tracks: {}\n", clip.QuaternionTracks.Count);

		if (page.TargetAutoAddedComponent)
			outText.Append("\n[Component auto-added on target]\n(shipping scene needs it too)");
	}

	// === Center viewport ===

	private static View BuildViewport(PropAnimEditorPage page)
	{
		// Wrap in a panel so the viewport gets a visible background even
		// when nothing has been loaded.
		let panel = new Panel();
		panel.Background = new ColorDrawable(.(25, 25, 30, 255));
		panel.AddView(page.Host.Viewport);
		return panel;
	}

	// === Bottom scrub region ===

	private static View BuildScrubRegion(PropAnimEditorPage page)
	{
		let container = new FlexLayout();
		container.Direction = .Vertical;
		container.Padding = .(8);
		container.Spacing = 4;

		let header = new Label();
		header.SetText("Time (Phase 1 stub - dopesheet lands in Phase 2)");
		header.TextColor = .(140, 140, 155, 255);
		header.FontSize = 11;
		container.AddView(header, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(16)) });

		let slider = new Slider();
		slider.Min = 0;
		slider.Max = (page.Clip != null) ? Math.Max(0.001f, page.Clip.Duration) : 1.0f;
		slider.Value = 0;
		slider.OnValueChanged.Add(new [=page] (s, v) =>
		{
			page.CurrentTime = v;
		});
		container.AddView(slider, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(28))
		});

		// Keep the slider's max in sync with the clip duration if the
		// clip's mutated (Phase 2's keyframe ops will adjust duration).
		page.OnTargetChanged.Add(new [=slider] (p) =>
		{
			let dur = (p.Clip != null) ? Math.Max(0.001f, p.Clip.Duration) : 1.0f;
			slider.Max = dur;
			if (slider.Value > dur) slider.Value = dur;
		});

		return container;
	}

	// === Common UI helpers ===

	private static void AddSectionHeader(FlexLayout parent, StringView text)
	{
		let label = new Label();
		label.SetText(text);
		label.TextColor = .(220, 220, 230, 255);
		label.FontSize = 12;
		parent.AddView(label, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(20)) });
	}
}
