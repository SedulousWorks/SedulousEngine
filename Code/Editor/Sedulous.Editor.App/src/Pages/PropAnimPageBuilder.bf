namespace Sedulous.Editor.App;

using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Core.Mathematics;
using Sedulous.Editor.Core;
using Sedulous.Engine.Core;
using Sedulous.Engine.Animation;

/// Phase 1 layout for `PropAnimEditorPage`. Three regions in a split:
///
///   - Left: preview source picker + entity hierarchy + (placeholder) track list.
///   - Center: viewport (the host's ViewportView) with the toolbar above it.
///   - Bottom: scrub slider (will be replaced by the real dopesheet in Phase 2).
static class PropAnimPageBuilder
{
	public static View Build(PropAnimEditorPage page)
	{
		// Hoisted: the timeline is referenced by both the bottom region
		// (where it's drawn) and the left panel's keyframe inspector
		// (which subscribes to its selection event).
		let timeline = new TimelineView();
		timeline.Clip = page.Clip;
		timeline.PlayheadTime = page.CurrentTime;

		// Vertical: toolbar + main split + bottom timeline region.
		let outer = new FlexLayout();
		outer.Direction = .Vertical;

		outer.AddView(BuildToolbar(page), new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Wrap
		});

		// Main split: left panel | viewport.
		let split = new SplitView(.Horizontal);
		split.SetPanes(BuildLeftPanel(page, timeline), BuildViewport(page));
		split.SplitRatio = 0.28f;

		outer.AddView(split, new FlexLayout.LayoutParams() {
			Width = .Match, Grow = 1
		});

		outer.AddView(BuildTimelineRegion(page, timeline), new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(220))
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
		timeLabel.TextColor.Value = .(200, 200, 210, 255);
		bar.AddItem(timeLabel);

		bar.AddSeparator();

		// Duration field. The clip's Duration is user-authored - editing
		// keyframes never shrinks it (see TimelineView.ExtendDurationIfNeeded).
		let durLabel = new Label();
		durLabel.SetText("Duration:");
		durLabel.TextColor.Value = .(200, 200, 210, 255);
		bar.AddItem(durLabel);

		let durField = new NumericField();
		durField.Min = 0;
		durField.Max = 600;
		durField.Step = 0.1;
		durField.DecimalPlaces = 2;
		durField.ShowSpinButtons.Value = false;
		durField.Value = (page.Clip != null) ? page.Clip.Duration : 0.0;
		durField.OnValueChanged.Add(new [=page] (nf, v) =>
		{
			if (page.Clip == null) return;
			let f = (float)v;
			if (page.Clip.Duration == f) return;
			page.Clip.Duration = f;
			page.MarkDirty();
		});
		// Toolbar extends FlexLayout - add the field with explicit
		// LayoutParams since NumericField's intrinsic measure won't
		// give us a useful width.
		bar.AddView(durField, new FlexLayout.LayoutParams() {
			Width = .Fixed(.Px(70)), Height = .Match
		});

		bar.AddSeparator();

		// Looping flag. Serialized on PropertyAnimationClip.IsLooping
		// and consumed by PropertyAnimationPlayer at runtime - without
		// this toggle the editor had no way to author the field.
		let loopCheck = new CheckBox("Loop", (page.Clip != null) ? page.Clip.IsLooping : false);
		loopCheck.OnCheckedChanged.Add(new [=page] (cb, isChecked) =>
		{
			if (page.Clip == null) return;
			if (page.Clip.IsLooping == isChecked) return;
			page.Clip.IsLooping = isChecked;
			page.MarkDirty();
		});
		bar.AddItem(loopCheck);

		// Refresh time readout on every scrub (timeline drives the page's
		// CurrentTime, which fires OnCurrentTimeChanged) and whenever the
		// target swaps (resets time to whatever the player reports).
		page.OnTargetChanged.Add(new [=timeLabel, =durField, =loopCheck] (p) => {
			UpdateTimeLabel(timeLabel, p);
			if (p.Clip != null)
			{
				durField.Value = p.Clip.Duration;
				loopCheck.IsChecked.Value = p.Clip.IsLooping;
			}
		});
		page.OnCurrentTimeChanged.Add(new [=timeLabel] (p) => UpdateTimeLabel(timeLabel, p));

		// Hot-reload of the .propanim file: clip is the same pointer but
		// duration / looping / track counts may differ. Refresh the
		// toolbar readouts.
		page.OnClipReloaded.Add(new [=timeLabel, =durField, =loopCheck] (p) => {
			UpdateTimeLabel(timeLabel, p);
			if (p.Clip != null)
			{
				durField.Value = p.Clip.Duration;
				loopCheck.IsChecked.Value = p.Clip.IsLooping;
			}
		});

		return bar;
	}

	private static void UpdateTimeLabel(Label label, PropAnimEditorPage page)
	{
		let clip = page.Clip;
		let dur = (clip != null) ? clip.Duration : 0.0f;
		label.SetText(scope $"{page.CurrentTime:0.00}s / {dur:0.00}s");
	}

	// === Left panel: preview source + hierarchy + track list ===

	private static View BuildLeftPanel(PropAnimEditorPage page, TimelineView timeline)
	{
		let container = new FlexLayout();
		container.Direction = .Vertical;
		container.Padding = .(8);
		container.Spacing = 6;

		BuildPreviewSourceSection(container, page);
		BuildHierarchySection(container, page);
		BuildKeyframeInspectorSection(container, page, timeline);

		return container;
	}

	private static void BuildPreviewSourceSection(FlexLayout parent, PropAnimEditorPage page)
	{
		AddSectionHeader(parent, "Preview Source");

		let pathLabel = new Label();
		RefreshPreviewSourceLabel(pathLabel, page);
		pathLabel.TextColor.Value = .(180, 180, 195, 255);
		pathLabel.FontSize.Value = 11;
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
			empty.TextColor.Value = .(140, 140, 155, 255);
			empty.FontSize.Value = 11;
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

	private static void BuildKeyframeInspectorSection(FlexLayout parent, PropAnimEditorPage page, TimelineView timeline)
	{
		AddSectionHeader(parent, "Keyframe");

		// Content host (KeyframeInspectorHost owns the IsEditing flag so
		// it survives across rebuilds). Editors are rebuilt on every
		// selection change since they're type-specific; cheap, and
		// avoids the cell-recycling complexity of a property grid.
		let host = new KeyframeInspectorHost();
		host.Direction = .Vertical;
		host.Spacing = 4;
		parent.AddView(host, new FlexLayout.LayoutParams() {
			Width = .Match, Grow = 1
		});

		RefreshKeyframeInspector(host, page, timeline);

		// Rebuild on selection change and clip mutation - but defer
		// while the user is typing in one of the inspector's fields,
		// otherwise per-keystroke OnValueChanged -> SetSelectedX ->
		// OnClipMutated would tear down the very NumericField whose
		// callback we're still inside, taking focus with it.
		timeline.OnSelectionChanged.Add(new [=host, =page, =timeline] (tl) =>
		{
			RequestRefresh(host, page, timeline);
		});
		timeline.OnClipMutated.Add(new [=host, =page, =timeline] (tl) =>
		{
			RequestRefresh(host, page, timeline);
		});
	}

	private static void RequestRefresh(KeyframeInspectorHost host, PropAnimEditorPage page, TimelineView timeline)
	{
		if (host.IsEditing)
		{
			// Inspector field is focused - rebuild would steal focus.
			// Defer until the user leaves the field (OnEditEnded path
			// in RefreshKeyframeInspector reruns RequestRefresh).
			host.PendingRefresh = true;
			return;
		}
		QueueRefreshKeyframeInspector(host, page, timeline);
	}

	private static void QueueRefreshKeyframeInspector(KeyframeInspectorHost host, PropAnimEditorPage page, TimelineView timeline)
	{
		host.PendingRefresh = false;
		let ctx = host.Context;
		if (ctx == null)
		{
			RefreshKeyframeInspector(host, page, timeline);
			return;
		}
		ctx.MutationQueue.QueueAction(new () =>
		{
			RefreshKeyframeInspector(host, page, timeline);
		});
	}

	private static void RefreshKeyframeInspector(KeyframeInspectorHost host, PropAnimEditorPage page, TimelineView timeline)
	{
		host.RemoveAllViews(true);

		if (page.Clip == null)
		{
			AddInspectorPlaceholder(host, "(no clip)");
			return;
		}

		let kf = timeline.SelectedKeyframe;
		if (!kf.IsValid)
		{
			AddInspectorPlaceholder(host, "(click a keyframe to edit its value)");
			return;
		}

		// Track path readout.
		let pathLabel = new Label();
		let path = scope String();
		AppendTrackPathFor(page, kf.Track, path);
		pathLabel.SetText(path);
		pathLabel.TextColor.Value = .(180, 180, 195, 255);
		pathLabel.FontSize.Value = 11;
		host.AddView(pathLabel, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(18))
		});

		// Time field.
		let timeNf = new NumericField();
		timeNf.Min = 0; timeNf.Max = 600; timeNf.Step = 0.1; timeNf.DecimalPlaces = 3;
		timeNf.ShowSpinButtons.Value = false;
		timeNf.Value = timeline.GetSelectedKeyframeTime();
		timeNf.OnValueChanged.Add(new [=timeline] (_, v) =>
		{
			timeline.SetSelectedKeyframeTime((float)v);
		});
		WireNumericFieldEditTracking(host, page, timeline, timeNf);
		AppendInspectorRow(host, "Time", timeNf);

		// Value field(s) - one per component based on kind. Vector2/3/4
		// and Quaternion use the toolkit's standalone VectorN fields so
		// the look matches the property-grid inspector.
		switch (kf.Track.Kind)
		{
		case .Float:
			float fv = 0;
			timeline.TryGetSelectedFloat(out fv);
			let nf = new NumericField();
			nf.Min = -1e6; nf.Max = 1e6; nf.Step = 0.1; nf.DecimalPlaces = 3;
			nf.ShowSpinButtons.Value = false;
			nf.Value = fv;
			nf.OnValueChanged.Add(new [=timeline] (_, v) =>
			{
				timeline.SetSelectedFloat((float)v);
			});
			WireNumericFieldEditTracking(host, page, timeline, nf);
			AppendInspectorRow(host, "Value", nf);

		case .Vector2:
			Vector2 v2 = .Zero;
			timeline.TryGetSelectedVector2(out v2);
			let field = new Vector2Field();
			field.Value = v2;
			field.OnValueChanged.Add(new [=timeline] (val) =>
			{
				timeline.SetSelectedVector2(val);
			});
			WireVectorFieldEditTracking(host, page, timeline, field);
			AppendInspectorRow(host, "Value", field);

		case .Vector3:
			Vector3 v3 = .Zero;
			timeline.TryGetSelectedVector3(out v3);
			let field = new Vector3Field();
			field.Value = v3;
			field.OnValueChanged.Add(new [=timeline] (val) =>
			{
				timeline.SetSelectedVector3(val);
			});
			WireVectorFieldEditTracking(host, page, timeline, field);
			AppendInspectorRow(host, "Value", field);

		case .Vector4:
			Vector4 v4 = .Zero;
			timeline.TryGetSelectedVector4(out v4);
			let field = new Vector4Field();
			field.Value = v4;
			field.OnValueChanged.Add(new [=timeline] (val) =>
			{
				timeline.SetSelectedVector4(val);
			});
			WireVectorFieldEditTracking(host, page, timeline, field);
			AppendInspectorRow(host, "Value", field);

		case .Quaternion:
			Quaternion q = .Identity;
			timeline.TryGetSelectedQuaternion(out q);
			let field = new QuaternionField();
			field.Value = q;
			field.OnValueChanged.Add(new [=timeline] (val) =>
			{
				timeline.SetSelectedQuaternion(val);
			});
			WireVectorFieldEditTracking(host, page, timeline, field);
			AppendInspectorRow(host, "Rotation (Euler)", field);
		}
	}

	private static void WireNumericFieldEditTracking(KeyframeInspectorHost host,
		PropAnimEditorPage page, TimelineView timeline, NumericField nf)
	{
		nf.OnEditBegan.Add(new [=host] (_) => { host.IsEditing = true; });
		nf.OnEditEnded.Add(new [=host, =page, =timeline] (_) =>
		{
			host.IsEditing = false;
			if (host.PendingRefresh)
				QueueRefreshKeyframeInspector(host, page, timeline);
		});
	}

	private static void WireVectorFieldEditTracking(KeyframeInspectorHost host,
		PropAnimEditorPage page, TimelineView timeline, AggregatingVectorField field)
	{
		field.OnEditBegan.Add(new [=host] (_) => { host.IsEditing = true; });
		field.OnEditEnded.Add(new [=host, =page, =timeline] (_) =>
		{
			host.IsEditing = false;
			if (host.PendingRefresh)
				QueueRefreshKeyframeInspector(host, page, timeline);
		});
	}

	private static void AppendInspectorRow(FlexLayout host, StringView name, View field)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 4;

		let label = new Label();
		label.SetText(name);
		label.TextColor.Value = .(200, 200, 210, 255);
		label.FontSize.Value = 11;
		row.AddView(label, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(54)), Height = .Match });

		row.AddView(field, new FlexLayout.LayoutParams() { Grow = 1, Height = .Fixed(.Px(22)) });

		host.AddView(row, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(24))
		});
	}

	private static void AddInspectorPlaceholder(FlexLayout host, StringView text)
	{
		let label = new Label();
		label.SetText(text);
		label.TextColor.Value = .(140, 140, 155, 255);
		label.FontSize.Value = 11;
		host.AddView(label, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Fixed(.Px(18))
		});
	}

	private static void AppendTrackPathFor(PropAnimEditorPage page, PropTrackRef tr, String outText)
	{
		let clip = page.Clip;
		if (clip == null) { outText.Set("(no track)"); return; }
		switch (tr.Kind)
		{
		case .Float:      outText.Set(clip.FloatTracks[tr.Index].PropertyPath);
		case .Vector2:    outText.Set(clip.Vector2Tracks[tr.Index].PropertyPath);
		case .Vector3:    outText.Set(clip.Vector3Tracks[tr.Index].PropertyPath);
		case .Vector4:    outText.Set(clip.Vector4Tracks[tr.Index].PropertyPath);
		case .Quaternion: outText.Set(clip.QuaternionTracks[tr.Index].PropertyPath);
		}
	}

	// === Center viewport ===

	private static View BuildViewport(PropAnimEditorPage page)
	{
		// Wrap in a panel so the viewport gets a visible background even
		// when nothing has been loaded.
		let panel = new Panel();
		panel.SetStyle(.Background, new ColorDrawable(.(25, 25, 30, 255)));
		panel.AddView(page.Host.Viewport);
		return panel;
	}

	// === Bottom timeline region (Phase 2) ===

	private static View BuildTimelineRegion(PropAnimEditorPage page, TimelineView timeline)
	{
		let container = new FlexLayout();
		container.Direction = .Vertical;

		// Mini-toolbar above the timeline for track/keyframe ops.
		let toolbar = new FlexLayout();
		toolbar.Direction = .Horizontal;
		toolbar.Padding = .(6, 4, 6, 4);
		toolbar.Spacing = 4;

		let addTrackBtn = new Button("Add Track...");
		let addKfBtn = new Button("Add Keyframe");
		let delKfBtn = new Button("Delete Keyframe");
		toolbar.AddView(addTrackBtn, new FlexLayout.LayoutParams() {
			Width = .Fixed(.Px(100)), Height = .Fixed(.Px(24))
		});
		toolbar.AddView(addKfBtn, new FlexLayout.LayoutParams() {
			Width = .Fixed(.Px(110)), Height = .Fixed(.Px(24))
		});
		toolbar.AddView(delKfBtn, new FlexLayout.LayoutParams() {
			Width = .Fixed(.Px(120)), Height = .Fixed(.Px(24))
		});

		container.AddView(toolbar, new FlexLayout.LayoutParams() {
			Width = .Match, Height = .Wrap
		});

		container.AddView(timeline, new FlexLayout.LayoutParams() {
			Width = .Match, Grow = 1
		});

		// Two-way sync between the timeline's playhead and the page's
		// CurrentTime. Both setters are idempotent (skip when the value
		// hasn't changed) so the timeline -> page -> timeline ricochet
		// terminates after one step; no re-entry guard needed.
		timeline.OnPlayheadChanged.Add(new [=page] (tl) =>
		{
			page.CurrentTime = tl.PlayheadTime;
		});

		timeline.OnClipMutated.Add(new [=page] (tl) =>
		{
			page.MarkDirty();
		});

		page.OnTargetChanged.Add(new [=timeline] (p) =>
		{
			timeline.Clip = p.Clip;
			timeline.PlayheadTime = p.CurrentTime;
		});

		// Hot-reload: the clip object is the same but its tracks have
		// been replaced. Rebuild the timeline's flat-track cache and
		// drop stale selection.
		page.OnClipReloaded.Add(new [=timeline] (p) =>
		{
			timeline.RefreshFromClip();
		});

		addKfBtn.OnClick.Add(new [=timeline] (btn) =>
		{
			timeline.AddKeyframeAtPlayheadOnSelectedTrack();
		});
		delKfBtn.OnClick.Add(new [=timeline] (btn) =>
		{
			timeline.DeleteSelectedKeyframe();
		});

		addTrackBtn.OnClick.Add(new [=page, =timeline] (btn) =>
		{
			OpenPropertyPicker(page, timeline);
		});

		return container;
	}

	private static void OpenPropertyPicker(PropAnimEditorPage page, TimelineView timeline)
	{
		let ctx = page.ContentView?.Context;
		let runtime = page.EditorContext?.RuntimeContext;
		if (ctx == null || runtime == null) return;

		let animSub = runtime.GetSubsystem<AnimationSubsystem>();
		if (animSub == null || animSub.PropertyBinderRegistry == null) return;

		let dlg = new PropertyPickerDialog(animSub.PropertyBinderRegistry,
			new [=page, =timeline] (path, kind) =>
			{
				let clip = page.Clip;
				if (clip == null) return;
				switch (kind)
				{
				case .Float:      clip.AddFloatTrack(path);
				case .Vector2:    clip.AddVector2Track(path);
				case .Vector3:    clip.AddVector3Track(path);
				case .Vector4:    clip.AddVector4Track(path);
				case .Quaternion: clip.AddQuaternionTrack(path);
				}
				clip.ComputeDuration();
				page.MarkDirty();
				timeline.RefreshFromClip();
			});
		dlg.Show(ctx);
	}

	// === Common UI helpers ===

	private static void AddSectionHeader(FlexLayout parent, StringView text)
	{
		let label = new Label();
		label.SetText(text);
		label.TextColor.Value = .(220, 220, 230, 255);
		label.FontSize.Value = 12;
		parent.AddView(label, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(20)) });
	}
}

/// Keyframe-inspector content host. Holds IsEditing/PendingRefresh
/// across rebuilds so per-keystroke OnClipMutated / OnSelectionChanged
/// events don't tear down the field the user is currently typing in.
class KeyframeInspectorHost : FlexLayout
{
	public bool IsEditing;
	public bool PendingRefresh;
}

