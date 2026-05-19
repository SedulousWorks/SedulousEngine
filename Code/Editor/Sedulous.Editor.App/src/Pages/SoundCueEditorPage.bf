namespace Sedulous.Editor.App;

using System;
using System.IO;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Audio;
using Sedulous.Audio.Resources;
using Sedulous.Editor.Core;
using Sedulous.Resources;
using Sedulous.VFS;

/// Editor page for authoring sound cues: cue-level params (selection mode,
/// limits, bus) plus a bespoke per-entry list (clip ResourceRef + weight +
/// volume/pitch ranges). Edits mark the page dirty; Save writes the
/// SoundCueResource back through the mount. Clip refs are resolved on
/// reload (resolve-on-save), so editing only mutates the ResourceRef list.
class SoundCueEditorPage : IEditorPage
{
	private String mPageId = new .() ~ delete _;
	private String mTitle = new .() ~ delete _;
	private String mFilePath = new .() ~ delete _;
	private EditorCommandStack mCommandStack = new .() ~ delete _;
	private View mContentView;

	private SoundCueResource mCueResource;
	private IAudioSystem mAudioSystem;
	private EditorContext mEditorContext;
	private bool mDirty;

	/// Rebuilds the entries list region. Set by the factory; invoked
	/// (deferred via the UI mutation queue) after a structural change so
	/// we never tear down the list from inside a row's own button event.
	private delegate void() mRebuildEntries ~ delete _;

	public this(StringView filePath, SoundCueResource cueResource,
		IAudioSystem audioSystem, EditorContext editorContext)
	{
		mFilePath.Set(filePath);
		mPageId.Set(filePath);
		mCueResource = cueResource;
		mAudioSystem = audioSystem;
		mEditorContext = editorContext;
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
	public bool IsDirty => mDirty;
	public EditorCommandStack CommandStack => mCommandStack;
	public StringView SaveFileExtension => ".soundcue";

	public SoundCueResource CueResource => mCueResource;
	public IAudioSystem AudioSystem => mAudioSystem;
	public EditorContext EditorContext => mEditorContext;

	public void SetContentView(View view) { mContentView = view; }

	/// Factory hands us a closure that rebuilds the entries list region.
	public void SetRebuildEntries(delegate void() rebuild)
	{
		delete mRebuildEntries;
		mRebuildEntries = rebuild;
	}

	/// Defer the entries rebuild to the next safe sync point - it runs
	/// from a row button's own event, and rebuilding the list there would
	/// delete the control mid-dispatch (use-after-free).
	public void RequestRebuildEntries()
	{
		if (mRebuildEntries == null) return;
		let ctx = mContentView?.Context;
		if (ctx != null)
		{
			ctx.MutationQueue.QueueAction(new () => { mRebuildEntries(); });
		}
		else
		{
			mRebuildEntries();
		}
	}

	public void MarkDirty()
	{
		if (!mDirty)
		{
			mDirty = true;
			UpdateTitle();
		}
	}

	public void Play()
	{
		let cue = mCueResource?.Cue;
		if (mAudioSystem != null && cue != null)
			mAudioSystem.PlayCue(cue);
	}

	/// Re-resolves ClipRefs -> Entries[i].Clip via the resource system.
	/// Without this Play Cue stays silent: SDL3AudioSystem.PlayCue returns
	/// early when entry.Clip is null. Called once after construction and
	/// after every picker/add/remove mutation by the factory.
	public void ResolveClips()
	{
		if (mCueResource == null || mEditorContext == null) return;
		mCueResource.ResolveClips(mEditorContext.ResourceSystem);
	}

	public void Save()
	{
		if (mFilePath.Length == 0 || mCueResource == null || mEditorContext == null) return;

		IWritableMount mount = null;
		let locator = scope String();
		if (!MountResolver.TryResolveAbsoluteWritable(mEditorContext.MountEntries, mFilePath, out mount, locator))
		{
			Console.WriteLine("ERROR: Save target is not inside any writable mount: {}", mFilePath);
			return;
		}

		let provider = mEditorContext.ResourceSystem?.SerializerProvider;
		if (provider == null)
		{
			Console.WriteLine("ERROR: No serializer provider available for sound cue save");
			return;
		}

		let memStream = scope MemoryStream();
		if (mCueResource.WriteToStream(memStream, provider) case .Err)
		{
			Console.WriteLine("ERROR: Sound cue serialization failed: {}", mFilePath);
			return;
		}
		memStream.Position = 0;

		if (mount.Save(locator, memStream) case .Err(let err))
		{
			Console.WriteLine("ERROR: Mount save failed for {}: {}", mFilePath, err);
			return;
		}

		mDirty = false;
		UpdateTitle();
		Console.WriteLine("Sound cue saved: {}", mFilePath);
	}

	public void SaveAs(StringView path)
	{
		mFilePath.Set(path);
		mPageId.Set(path);
		Save();
	}

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
		if (mDirty)
			mTitle.Append("*");
	}
}
