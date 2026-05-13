namespace Sedulous.Editor.App;

using System;
using Sedulous.UI;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.Core;
using Sedulous.Animation;
using Sedulous.Animation.Resources;

/// Editor page for previewing .animation files.
///
/// Phase 5.5 scope: metadata + timeline scrubber only. Full skeletal preview
/// (binding the clip to a Skeleton + SkinnedMesh and animating it via debug
/// draw) is deferred to a follow-up - AnimationClip carries no skeleton link,
/// so the binding step needs UI we don't have yet.
class AnimationEditorPage : IEditorPage
{
	private String mPageId = new .() ~ delete _;
	private String mTitle = new .() ~ delete _;
	private String mFilePath = new .() ~ delete _;
	private EditorCommandStack mCommandStack = new .() ~ delete _;
	private View mContentView;

	private AnimationClipResource mClipRes;
	private PreviewSceneHost mHost ~ delete _;

	private float mScrubTime;
	private bool mIsPlaying;

	public this(StringView filePath, AnimationClipResource clipRes, PreviewSceneHost host)
	{
		mFilePath.Set(filePath);
		mPageId.Set(filePath);
		mClipRes = clipRes;
		mHost = host;
		UpdateTitle();

		// Frame an arbitrary unit volume so the viewport isn't undefined.
		mHost.FitToBounds(.(Sedulous.Core.Mathematics.Vector3(-1, -1, -1),
			Sedulous.Core.Mathematics.Vector3(1, 1, 1)));
	}

	public ~this()
	{
		if (mClipRes != null)
			mClipRes.ReleaseRef();
	}

	// === IEditorPage ===

	public StringView PageId => mPageId;
	public StringView Title => mTitle;
	public StringView FilePath => mFilePath;
	public View ContentView => mContentView;
	public bool IsDirty => false;
	public EditorCommandStack CommandStack => mCommandStack;

	public AnimationClipResource Clip => mClipRes;
	public PreviewSceneHost Host => mHost;
	public float ScrubTime
	{
		get => mScrubTime;
		set
		{
			let dur = mClipRes?.Clip?.Duration ?? 0;
			mScrubTime = (dur > 0) ? Math.Clamp(value, 0, dur) : 0;
		}
	}
	public bool IsPlaying => mIsPlaying;

	public void SetContentView(View view) { mContentView = view; }

	public void Play() { mIsPlaying = true; }
	public void Pause() { mIsPlaying = false; }
	public void Stop()
	{
		mIsPlaying = false;
		mScrubTime = 0;
	}

	public void Save() { }
	public void SaveAs(StringView path) { }
	public void OnActivated() { }
	public void OnDeactivated() { }

	public void Update(float deltaTime)
	{
		if (!mIsPlaying) return;
		let dur = mClipRes?.Clip?.Duration ?? 0;
		if (dur <= 0) return;

		mScrubTime += deltaTime;
		if (mClipRes.Clip.IsLooping)
			mScrubTime = mScrubTime - Math.Floor(mScrubTime / dur) * dur;
		else if (mScrubTime >= dur)
		{
			mScrubTime = dur;
			mIsPlaying = false;
		}
	}

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
