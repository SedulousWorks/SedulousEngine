namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.Audio;
using Sedulous.Audio.Resources;
using Sedulous.Editor.Core;

/// Editor page for previewing audio clips.
/// Holds the AudioClipResource alive via ref counting and provides
/// play/pause/stop controls with an IAudioSource for playback.
class AudioClipEditorPage : IEditorPage
{
	private String mPageId = new .() ~ delete _;
	private String mTitle = new .() ~ delete _;
	private String mFilePath = new .() ~ delete _;
	private EditorCommandStack mCommandStack = new .() ~ delete _;
	private View mContentView;

	// Resource (ref-counted)
	private AudioClipResource mClipResource;

	// Playback
	private IAudioSystem mAudioSystem;
	private IAudioSource mSource;

	public this(StringView filePath, AudioClipResource clipResource, IAudioSystem audioSystem)
	{
		mFilePath.Set(filePath);
		mPageId.Set(filePath);
		mClipResource = clipResource;
		mAudioSystem = audioSystem;

		if (mAudioSystem != null)
			mSource = mAudioSystem.CreateSource();

		UpdateTitle();
	}

	public ~this()
	{
		if (mSource != null)
		{
			mSource.Stop();
			mAudioSystem?.DestroySource(mSource);
		}

		if (mClipResource != null)
			mClipResource.ReleaseRef();
	}

	// === IEditorPage ===

	public StringView PageId => mPageId;
	public StringView Title => mTitle;
	public StringView FilePath => mFilePath;
	public View ContentView => mContentView;
	public bool IsDirty => false;
	public EditorCommandStack CommandStack => mCommandStack;
	public StringView SaveFileExtension => "";  // read-only preview

	public AudioClipResource ClipResource => mClipResource;
	public IAudioSource Source => mSource;

	public void SetContentView(View view) { mContentView = view; }

	public void Play()
	{
		let clip = mClipResource?.Clip;
		Console.WriteLine("[AudioClipEditor] Play called");
		Console.WriteLine("  source: {}", mSource != null ? "yes" : "null");
		Console.WriteLine("  clip: {}", clip != null ? "yes" : "null");
		if (clip != null)
		{
			Console.WriteLine("  clip.IsLoaded: {}", clip.IsLoaded);
			Console.WriteLine("  clip.SampleRate: {}", clip.SampleRate);
			Console.WriteLine("  clip.Channels: {}", clip.Channels);
			Console.WriteLine("  clip.Format: {}", clip.Format);
			Console.WriteLine("  clip.Duration: {:.2}s", clip.Duration);
			Console.WriteLine("  clip.DataLength: {} bytes", clip.DataLength);
			Console.WriteLine("  clip.FrameCount: {}", clip.FrameCount);
		}
		if (mSource != null)
		{
			Console.WriteLine("  source.State: {}", mSource.State);
			Console.WriteLine("  source.Volume: {}", mSource.Volume);
			Console.WriteLine("  source.BusName: {}", mSource.BusName);
		}
		Console.WriteLine("  audioSystem: {}", mAudioSystem != null ? "yes" : "null");

		if (mSource != null && clip != null)
			mSource.Play(clip);

		if (mSource != null)
			Console.WriteLine("  source.State after Play: {}", mSource.State);

	}

	public void Pause()
	{
		if (mSource != null)
			mSource.Pause();
	}

	public void Stop()
	{
		if (mSource != null)
			mSource.Stop();
	}

	public void Save() { }
	public void SaveAs(StringView path) { }
	public void OnActivated() { }

	public void OnDeactivated()
	{
		// Stop playback when switching away from this tab
		Stop();
	}

	public void Update(float deltaTime) { }

	public void Dispose()
	{
		Stop();
		delete mContentView;
		mContentView = null;
	}

	private void UpdateTitle()
	{
		mTitle.Clear();
		let name = scope String();
		System.IO.Path.GetFileNameWithoutExtension(mFilePath, name);
		mTitle.Set(name);
	}
}
