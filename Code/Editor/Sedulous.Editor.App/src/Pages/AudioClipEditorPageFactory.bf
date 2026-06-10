using System;
using System.Collections;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Resources;
using Sedulous.Audio;
using Sedulous.Audio.Resources;
using Sedulous.Engine.Audio;
namespace Sedulous.Editor.App.Pages;

/// Creates editor pages for .audioclip files with playback preview.
class AudioClipEditorPageFactory : IEditorPageFactory
{
	public void GetSupportedExtensions(List<String> outExtensions)
	{
		outExtensions.Add(new .(".audioclip"));
	}

	public bool CanOpen(StringView path) =>
		path.EndsWith(".audioclip", .OrdinalIgnoreCase);

	public IEditorPage CreatePage(StringView path, EditorContext context)
	{
		let uri = scope String();
		if (!MountResolver.TryResolveAbsoluteToUri(context.MountEntries, path, uri))
			return MeshEditorPageFactory.BuildErrorPage(path, "Audio Clip", "Path is not inside any mounted scheme.", context);

		AudioClipResource clipRes = null;
		if (context.ResourceSystem.LoadResource<AudioClipResource>(uri) case .Ok(let handle))
			clipRes = handle.Resource;

		// Get audio system from the editor's own context (not RuntimeContext)
		IAudioSystem audioSystem = null;
		if (let audioSub = context.RuntimeContext?.GetSubsystem<AudioSubsystem>())
			audioSystem = audioSub.AudioSystem;

		let page = new AudioClipEditorPage(path, clipRes, audioSystem, context.Logger);
		page.SetContentView(BuildAudioClipView(clipRes, page));
		return page;
	}

	private static View BuildAudioClipView(AudioClipResource clipRes, AudioClipEditorPage page)
	{
		let root = new FlexLayout();
		root.Direction = .Vertical;
		root.Padding = .(16);
		root.Spacing = 12;

		// Title
		let name = scope String();
		System.IO.Path.GetFileNameWithoutExtension(page.FilePath, name);
		let titleLabel = new Label();
		titleLabel.SetText(scope $"Audio Clip: {name}");
		titleLabel.FontSize.Value = 16;
		titleLabel.TextColor.Value = .(220, 225, 235, 255);
		root.AddView(titleLabel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(28)) });

		// Separator
		let sep = new Panel();
		sep.SetStyle(.Background, new ColorDrawable(.(60, 65, 80, 255)));
		root.AddView(sep, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(1)) });

		// Metadata
		if (clipRes?.Clip != null)
		{
			let clip = clipRes.Clip;

			AddInfoRow(root, "Sample Rate", scope $"{clip.SampleRate} Hz");
			AddInfoRow(root, "Channels", scope $"{clip.Channels} ({(clip.Channels == 1) ? "Mono" : "Stereo"})");
			AddInfoRow(root, "Format", scope $"{clip.Format}");
			AddInfoRow(root, "Duration", FormatDuration(clip.Duration, .. scope .()));
			AddInfoRow(root, "Frames", scope $"{clip.FrameCount}");

			let dataSize = clip.DataLength;
			if (dataSize > 1024 * 1024)
				AddInfoRow(root, "Data Size", scope $"{dataSize / (1024 * 1024)} MB");
			else
				AddInfoRow(root, "Data Size", scope $"{dataSize / 1024} KB");
		}
		else
		{
			let errorLabel = new Label();
			errorLabel.SetText("Failed to load audio clip");
			errorLabel.TextColor.Value = .(220, 100, 100, 255);
			root.AddView(errorLabel, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(20)) });
		}

		// Separator
		let sep2 = new Panel();
		sep2.SetStyle(.Background, new ColorDrawable(.(60, 65, 80, 255)));
		root.AddView(sep2, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(1)) });

		// Playback controls
		let controls = new FlexLayout();
		controls.Direction = .Horizontal;
		controls.Spacing = 8;

		let playBtn = new Button("Play");
		playBtn.OnClick.Add(new [=page] (btn) => { page.Play(); });
		controls.AddView(playBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(80)), Height = .Fixed(.Px(28)) });

		let pauseBtn = new Button("Pause");
		pauseBtn.OnClick.Add(new [=page] (btn) => { page.Pause(); });
		controls.AddView(pauseBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(80)), Height = .Fixed(.Px(28)) });

		let stopBtn = new Button("Stop");
		stopBtn.OnClick.Add(new [=page] (btn) => { page.Stop(); });
		controls.AddView(stopBtn, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(80)), Height = .Fixed(.Px(28)) });

		root.AddView(controls, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(32)) });

		// Volume slider
		let volumeRow = new FlexLayout();
		volumeRow.Direction = .Horizontal;
		volumeRow.Spacing = 8;

		let volumeLabel = new Label();
		volumeLabel.SetText("Volume:");
		volumeLabel.TextColor.Value = .(140, 140, 155, 255);
		volumeRow.AddView(volumeLabel, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(60)), Height = .Match });

		let volumeSlider = new Slider(0, 1, 1);
		volumeSlider.OnValueChanged.Add(new [=page] (s, val) => {
			if (page.Source != null)
				page.Source.Volume = val;
		});
		volumeRow.AddView(volumeSlider, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });

		root.AddView(volumeRow, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(24)) });

		// Loop checkbox
		let loopCheck = new CheckBox("Loop", false);
		loopCheck.OnCheckedChanged.Add(new [=page] (cb, val) => {
			if (page.Source != null)
				page.Source.Loop = val;
		});
		root.AddView(loopCheck, new FlexLayout.LayoutParams() { Width = .Wrap, Height = .Fixed(.Px(24)) });

		return root;
	}

	public static void AddInfoRow(FlexLayout container, StringView name, StringView value)
	{
		let row = new FlexLayout();
		row.Direction = .Horizontal;

		let nameLabel = new Label();
		nameLabel.SetText(scope $"{name}:");
		nameLabel.TextColor.Value = .(140, 140, 155, 255);
		row.AddView(nameLabel, new FlexLayout.LayoutParams() { Width = .Fixed(.Px(100)), Height = .Match });

		let valueLabel = new Label();
		valueLabel.SetText(value);
		valueLabel.TextColor.Value = .(220, 220, 230, 255);
		row.AddView(valueLabel, new FlexLayout.LayoutParams() { Grow = 1, Height = .Match });

		container.AddView(row, new FlexLayout.LayoutParams() { Width = .Match, Height = .Fixed(.Px(20)) });
	}

	public static void FormatDuration(float seconds, String outStr)
	{
		if (seconds >= 60)
			outStr.AppendF("{0}:{1:00.1}", (int)(seconds / 60), seconds % 60);
		else
			outStr.AppendF("{0:F2}s", seconds);
	}
}
