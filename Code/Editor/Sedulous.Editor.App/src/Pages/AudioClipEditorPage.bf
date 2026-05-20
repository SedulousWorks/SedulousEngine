namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.Audio;
using Sedulous.Audio.Resources;
using Sedulous.Editor.Core;
using Sedulous.Core.Logging.Abstractions;

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
	private ILogger mLogger;

	public this(StringView filePath, AudioClipResource clipResource, IAudioSystem audioSystem, ILogger logger = null)
	{
		mFilePath.Set(filePath);
		mPageId.Set(filePath);
		mClipResource = clipResource;
		mAudioSystem = audioSystem;
		mLogger = logger;

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

		if (mLogger != null)
		{
			if (clip != null)
				mLogger.LogDebug("AudioClipEditor.Play: clip {}Hz {}ch fmt={} loaded={} duration={:0.2}s frames={} bytes={}",
					clip.SampleRate, clip.Channels, clip.Format, clip.IsLoaded, clip.Duration, clip.FrameCount, clip.DataLength);
			else
				mLogger.LogDebug("AudioClipEditor.Play: no clip");

			if (mSource != null)
				mLogger.LogDebug("AudioClipEditor.Play: source state={} volume={} bus={}",
					mSource.State, mSource.Volume, mSource.BusName);
		}

		if (mSource != null && clip != null)
		{
			mSource.Play(clip);
			mLogger?.LogDebug("AudioClipEditor.Play: source state after Play = {}", mSource.State);
		}
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
