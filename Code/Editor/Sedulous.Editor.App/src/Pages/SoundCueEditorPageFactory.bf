using Sedulous.UI;
using System;
using Sedulous.Resources;
using Sedulous.Editor.Core;
using System.Collections;
using Sedulous.Audio.Resources;
using Sedulous.Audio;
using Sedulous.Engine.Audio;
namespace Sedulous.Editor.App.Pages;

/// Creates editor pages for .soundcue files: editable cue params + a
/// bespoke per-entry list (clip ResourceRef + weight + volume/pitch
/// ranges), with Play preview and Save through the mount.
class SoundCueEditorPageFactory : IEditorPageFactory
{
	public void GetSupportedExtensions(List<String> outExtensions)
	{
		outExtensions.Add(new .(".soundcue"));
	}

	public bool CanOpen(StringView path) =>
		path.EndsWith(".soundcue", .OrdinalIgnoreCase);

	public IEditorPage CreatePage(StringView path, EditorContext context)
	{
		let uri = scope String();
		if (!MountResolver.TryResolveAbsoluteToUri(context.MountEntries, path, uri))
			return MeshEditorPageFactory.BuildErrorPage(path, "Sound Cue", "Path is not inside any mounted scheme.", context);

		SoundCueResource cueRes = null;
		if (context.ResourceSystem.LoadResource<SoundCueResource>(uri) case .Ok(let handle))
			cueRes = handle.Resource;
		if (cueRes == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Sound Cue", "Failed to load sound cue resource.", context);

		// Get audio system from the editor's own context
		IAudioSystem audioSystem = null;
		if (let audioSub = context.RuntimeContext?.GetSubsystem<AudioSubsystem>())
			audioSystem = audioSub.AudioSystem;

		let page = new SoundCueEditorPage(path, cueRes, audioSystem, context);
		// Initial resolve so the cue's Entry.Clip pointers are populated for
		// preview playback - the manager only deserializes; resolution is the
		// consumer's job (see AudioSourceComponentManager for the in-game path).
		page.ResolveClips();
		page.SetContentView(BuildSoundCueView(cueRes, page));
		return page;
	}

	// --- Small labeled-row helper (label left, control right) ---
	private static void AddFieldRow(FlexLayout container, StringView label, View control)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;
		row.Spacing = 8;

		let lbl = new Label();
		lbl.SetText(label);
		lbl.TextColor.Value = .(170, 175, 190, 255);
		lbl.VAlign.Value = .Middle;
		row.AddView(lbl, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(120)), Height = .Match });
		row.AddView(control, new FlexLayout.LayoutParams() { Grow = 1, Height = .Fixed(.Px(26)) });

		container.AddView(row, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(28)) });
	}

	private static View BuildSoundCueView(SoundCueResource cueRes, SoundCueEditorPage page)
	{
		let cue = cueRes.Cue;

		let root = new FlexLayout();
		root.Direction = .Vertical;
		root.Padding = .(16);
		root.Spacing = 8;

		// Title
		let name = scope String();
		System.IO.Path.GetFileNameWithoutExtension(page.FilePath, name);
		let titleLabel = new Label();
		titleLabel.SetText(scope $"Sound Cue: {name}");
		titleLabel.FontSize.Value = 16;
		titleLabel.TextColor.Value = .(220, 225, 235, 255);
		root.AddView(titleLabel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(28)) });

		AddSeparator(root);

		// --- Cue params ---
		let modeBox = new ComboBox();
		modeBox.AddItem("Random");
		modeBox.AddItem("Sequential");
		modeBox.AddItem("Shuffle");
		modeBox.SelectedIndex = (int)cue.SelectionMode;
		modeBox.OnSelectionChanged.Add(new [=cue, =page] (cb, idx) => {
			cue.SelectionMode = (CueSelectionMode)idx;
			page.MarkDirty();
		});
		AddFieldRow(root, "Selection Mode", modeBox);

		let maxInst = new NumericField();
		maxInst.DecimalPlaces = 0; maxInst.Step = 1; maxInst.Min = 0; maxInst.Max = 1024;
		maxInst.Value = cue.MaxInstances;
		maxInst.OnValueChanged.Add(new [=cue, =page] (f, v) => { cue.MaxInstances = (int32)v; page.MarkDirty(); });
		AddFieldRow(root, "Max Instances", maxInst);

		let prio = new NumericField();
		prio.DecimalPlaces = 0; prio.Step = 1; prio.Min = -1000; prio.Max = 1000;
		prio.Value = cue.Priority;
		prio.OnValueChanged.Add(new [=cue, =page] (f, v) => { cue.Priority = (int32)v; page.MarkDirty(); });
		AddFieldRow(root, "Priority", prio);

		let cooldown = new NumericField();
		cooldown.DecimalPlaces = 2; cooldown.Step = 0.1; cooldown.Min = 0; cooldown.Max = 600;
		cooldown.Value = cue.Cooldown;
		cooldown.OnValueChanged.Add(new [=cue, =page] (f, v) => { cue.Cooldown = (float)v; page.MarkDirty(); });
		AddFieldRow(root, "Cooldown (s)", cooldown);

		let bus = new EditText();
		if (cue.BusName == null) cue.BusName = new String();
		bus.SetText(cue.BusName);
		bus.OnTextChanged.Add(new [=cue, =page] (t) => { cue.BusName.Set(t.Text); page.MarkDirty(); });
		AddFieldRow(root, "Bus", bus);

		AddSeparator(root);

		// --- Entries (bespoke list) ---
		let header = new FlexLayout();
		header.Direction = .Horizontal;
		header.Spacing = 8;
		let entriesLabel = new Label();
		entriesLabel.SetText("Entries");
		entriesLabel.FontSize.Value = 13;
		entriesLabel.TextColor.Value = .(180, 180, 195, 255);
		entriesLabel.VAlign.Value = .Middle;
		header.AddView(entriesLabel, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });
		let addBtn = new Button("+ Add Entry");
		addBtn.OnClick.Add(new [=cue, =cueRes, =page] (btn) => {
			cue.Entries.Add(SoundCueEntry());
			cueRes.ClipRefs.Add(ResourceRef());
			page.ResolveClips();
			page.MarkDirty();
			page.RequestRebuildEntries();
		});
		header.AddView(addBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(100)), Height = .Fixed(.Px(26)) });
		root.AddView(header, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(28)) });

		let entriesHost = new FlexLayout();
		entriesHost.Direction = .Vertical;
		entriesHost.Spacing = 6;
		root.AddView(entriesHost, new FlexLayout.LayoutParams() { Width = .Match, Grow = 1 });

		// Rebuilds the entry rows from the current cue/clipref lists.
		void RebuildEntries()
		{
			entriesHost.RemoveAllViews(true);
			for (int i = 0; i < cue.Entries.Count; i++)
			{
				int idx = i;

				let rowPanel = new Panel();
				rowPanel.Background = new ColorDrawable(.(30, 32, 38, 255));
				let rowCol = new FlexLayout();
				rowCol.Direction = .Vertical;
				rowCol.Padding = .(8);
				rowCol.Spacing = 4;
				rowPanel.AddView(rowCol);

				// Clip picker row.
				let clipRow = new FlexLayout();
				clipRow.Direction = .Horizontal;
				clipRow.Spacing = 8;

				let clipRef = (idx < cueRes.ClipRefs.Count) ? cueRes.ClipRefs[idx] : ResourceRef();
				let clipText = scope String();
				clipText.AppendF("[{}] ", idx);
				if (clipRef.Path != null && clipRef.Path.Length > 0)
					clipText.Append(clipRef.Path);
				else
					clipText.Append("(no clip - click to assign)");

				let clipBtn = new Button(clipText);
				clipBtn.OnClick.Add(new (btn) => {
					let ctx = btn.Context;
					if (ctx == null) return;
					let dlg = new AssetPickerDialog(page.EditorContext, ".audioclip",
						new (protocolPath, id) => {
							if (idx < cueRes.ClipRefs.Count)
							{
								var old = cueRes.ClipRefs[idx];
								old.Dispose();
								cueRes.ClipRefs[idx] = ResourceRef(id, protocolPath);
								page.ResolveClips();
								page.MarkDirty();
								page.RequestRebuildEntries();
							}
						});
					dlg.Show(ctx);
				});
				clipRow.AddView(clipBtn, new FlexLayout.LayoutParams() { Grow = 1, Height = .Fixed(.Px(24)) });

				let removeBtn = new Button("Remove");
				removeBtn.OnClick.Add(new (btn) => {
					if (idx < cue.Entries.Count)
					{
						if (idx < cueRes.ClipRefs.Count)
						{
							var r = cueRes.ClipRefs[idx];
							r.Dispose();
							cueRes.ClipRefs.RemoveAt(idx);
						}
						cue.Entries.RemoveAt(idx);
						page.ResolveClips();
						page.MarkDirty();
						page.RequestRebuildEntries();
					}
				});
				clipRow.AddView(removeBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(80)), Height = .Fixed(.Px(24)) });
				rowCol.AddView(clipRow, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(26)) });

				// Params row: Weight / Vol min-max / Pitch min-max.
				// onChanged is handed straight to the event, which owns it and
				// deletes it with the NumericField - do not wrap it in another
				// closure, or the wrapped delegate orphans and leaks on rebuild.
				void AddNum(FlexLayout into, StringView lbl, float val, delegate void(NumericField, double) onChanged)
				{
					let cell = new FlexLayout();
					cell.Direction = .Vertical;
					let cl = new Label();
					cl.SetText(lbl);
					cl.FontSize.Value = 10;
					cl.TextColor.Value = .(140, 145, 160, 255);
					cell.AddView(cl, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(12)) });
					let nf = new NumericField();
					nf.DecimalPlaces = 2; nf.Step = 0.05; nf.Min = 0; nf.Max = 4;
					nf.Value = val;
					nf.OnValueChanged.Add(onChanged);
					cell.AddView(nf, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(24)) });
					into.AddView(cell, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });
				}

				let paramRow = new FlexLayout();
				paramRow.Direction = .Horizontal;
				paramRow.Spacing = 6;
				let e = cue.Entries[idx];
				AddNum(paramRow, "Weight", e.Weight, new (f, v) => {
					var ent = cue.Entries[idx]; ent.Weight = (float)v; cue.Entries[idx] = ent; page.MarkDirty();
				});
				AddNum(paramRow, "Vol Min", e.VolumeMin, new (f, v) => {
					var ent = cue.Entries[idx]; ent.VolumeMin = (float)v; cue.Entries[idx] = ent; page.MarkDirty();
				});
				AddNum(paramRow, "Vol Max", e.VolumeMax, new (f, v) => {
					var ent = cue.Entries[idx]; ent.VolumeMax = (float)v; cue.Entries[idx] = ent; page.MarkDirty();
				});
				AddNum(paramRow, "Pitch Min", e.PitchMin, new (f, v) => {
					var ent = cue.Entries[idx]; ent.PitchMin = (float)v; cue.Entries[idx] = ent; page.MarkDirty();
				});
				AddNum(paramRow, "Pitch Max", e.PitchMax, new (f, v) => {
					var ent = cue.Entries[idx]; ent.PitchMax = (float)v; cue.Entries[idx] = ent; page.MarkDirty();
				});
				rowCol.AddView(paramRow, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(40)) });

				entriesHost.AddView(rowPanel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(78)) });
			}
		}

		RebuildEntries();
		page.SetRebuildEntries(new () => RebuildEntries());

		AddSeparator(root);

		if (page.AudioSystem != null)
		{
			let playBtn = new Button("Play Cue");
			playBtn.OnClick.Add(new [=page] (btn) => { page.Play(); });
			root.AddView(playBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(100)), Height = .Fixed(.Px(28)) });

			let stopBtn = new Button("Stop");
			stopBtn.OnClick.Add(new [=page] (btn) => { page.Stop(); });
			root.AddView(stopBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(80)), Height = .Fixed(.Px(28)) });
		}

		return root;
	}

	private static void AddSeparator(FlexLayout container)
	{
		let sep = new Panel();
		sep.Background = new ColorDrawable(.(60, 65, 80, 255));
		container.AddView(sep, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(1)) });
	}
}
