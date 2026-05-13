using Sedulous.UI;
using System;
using Sedulous.Resources;
using Sedulous.Editor.Core;
using System.Collections;
using Sedulous.Audio.Resources;
using Sedulous.Audio;
using Sedulous.Engine.Audio;
namespace Sedulous.Editor.App.Pages;

/// Creates editor pages for .soundcue files with preview playback.
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
			return MeshEditorPageFactory.BuildErrorPage(path, "Sound Cue", "Path is not inside any mounted scheme.");

		SoundCueResource cueRes = null;
		if (context.ResourceSystem.LoadResource<SoundCueResource>(uri) case .Ok(let handle))
			cueRes = handle.Resource;
		if (cueRes == null)
			return MeshEditorPageFactory.BuildErrorPage(path, "Sound Cue", "Failed to load sound cue resource.");

		// Get audio system from the editor's own context
		IAudioSystem audioSystem = null;
		if (let audioSub = context.RuntimeContext?.GetSubsystem<AudioSubsystem>())
			audioSystem = audioSub.AudioSystem;

		let page = new SoundCueEditorPage(path, cueRes, audioSystem);
		page.SetContentView(BuildSoundCueView(cueRes, page));
		return page;
	}

	private static View BuildSoundCueView(SoundCueResource cueRes, SoundCueEditorPage page)
	{
		let root = new FlexLayout();
		root.Direction = .Vertical;
		root.Padding = .(16);
		root.Spacing = 12;

		// Title
		let name = scope String();
		System.IO.Path.GetFileNameWithoutExtension(page.FilePath, name);
		let titleLabel = new Label();
		titleLabel.SetText(scope $"Sound Cue: {name}");
		titleLabel.FontSize = 16;
		titleLabel.TextColor = .(220, 225, 235, 255);
		root.AddView(titleLabel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(28)) });

		let sep = new Panel();
		sep.Background = new ColorDrawable(.(60, 65, 80, 255));
		root.AddView(sep, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(1)) });

		let cue = cueRes.Cue;

		// Cue properties
		AudioClipEditorPageFactory.AddInfoRow(root, "Selection Mode", scope $"{cue.SelectionMode}");
		AudioClipEditorPageFactory.AddInfoRow(root, "Entries", scope $"{cue.Entries.Count}");
		AudioClipEditorPageFactory.AddInfoRow(root, "Max Instances", scope $"{cue.MaxInstances}");
		AudioClipEditorPageFactory.AddInfoRow(root, "Priority", scope $"{cue.Priority}");
		AudioClipEditorPageFactory.AddInfoRow(root, "Cooldown", scope $"{cue.Cooldown:F2}s");
		AudioClipEditorPageFactory.AddInfoRow(root, "Bus", cue.BusName);

		// Entry list
		if (cue.Entries.Count > 0)
		{
			let sep2 = new Panel();
			sep2.Background = new ColorDrawable(.(60, 65, 80, 255));
			root.AddView(sep2, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(1)) });

			let entriesLabel = new Label();
			entriesLabel.SetText("Entries");
			entriesLabel.FontSize = 13;
			entriesLabel.TextColor = .(180, 180, 195, 255);
			root.AddView(entriesLabel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(22)) });

			for (int i = 0; i < cue.Entries.Count; i++)
			{
				let entry = cue.Entries[i];
				let clipRef = (i < cueRes.ClipRefs.Count) ? cueRes.ClipRefs[i] : ResourceRef();

				let entryLabel = scope String();
				entryLabel.AppendF("  [{0}] W:{1:F1} Vol:{2:F2}-{3:F2} Pitch:{4:F2}-{5:F2}",
					i, entry.Weight, entry.VolumeMin, entry.VolumeMax, entry.PitchMin, entry.PitchMax);

				if (clipRef.Path != null && clipRef.Path.Length > 0)
					entryLabel.AppendF(" -> {}", clipRef.Path);

				AudioClipEditorPageFactory.AddInfoRow(root, scope $"Entry {i}", entryLabel);
			}
		}

		// Play button (routes through the page so the cue stays alive via mCueResource)
		let sep3 = new Panel();
		sep3.Background = new ColorDrawable(.(60, 65, 80, 255));
		root.AddView(sep3, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(1)) });

		if (page.AudioSystem != null)
		{
			let playBtn = new Button("Play Cue");
			playBtn.OnClick.Add(new [=page] (btn) => { page.Play(); });
			root.AddView(playBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(100)), Height = .Fixed(.Px(28)) });
		}

		return root;
	}
}
