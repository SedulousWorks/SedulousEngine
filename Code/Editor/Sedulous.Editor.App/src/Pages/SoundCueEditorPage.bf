namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.Audio;
using Sedulous.Audio.Resources;
using Sedulous.Editor.Core;

/// Editor page for previewing sound cues.
/// Holds the SoundCueResource alive via ref counting and provides a Play
/// button that fires the cue through the audio system. PlayCue is
/// fire-and-forget, so unlike AudioClipEditorPage there's no IAudioSource
/// to manage.
class SoundCueEditorPage : IEditorPage
{
	private String mPageId = new .() ~ delete _;
	private String mTitle = new .() ~ delete _;
	private String mFilePath = new .() ~ delete _;
	private EditorCommandStack mCommandStack = new .() ~ delete _;
	private View mContentView;

	private SoundCueResource mCueResource;
	private IAudioSystem mAudioSystem;

	public this(StringView filePath, SoundCueResource cueResource, IAudioSystem audioSystem)
	{
		mFilePath.Set(filePath);
		mPageId.Set(filePath);
		mCueResource = cueResource;
		mAudioSystem = audioSystem;
		UpdateTitle();
	}

	public ~this()
	{
		if (mCueResource != null)
			mCueResource.ReleaseRef();
	}

	// === IEditorPage ===

	public StringView PageId => mPageId;
	public StringView Title => mTitle;
	public StringView FilePath => mFilePath;
	public View ContentView => mContentView;
	public bool IsDirty => false;
	public EditorCommandStack CommandStack => mCommandStack;

	public SoundCueResource CueResource => mCueResource;
	public IAudioSystem AudioSystem => mAudioSystem;

	public void SetContentView(View view) { mContentView = view; }

	public void Play()
	{
		let cue = mCueResource?.Cue;
		if (mAudioSystem != null && cue != null)
			mAudioSystem.PlayCue(cue);
	}

	public void Save() { }
	public void SaveAs(StringView path) { }
	public void OnActivated() { }
	public void OnDeactivated() { }
	public void Update(float deltaTime) { }

	public void Dispose()
	{
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
