namespace Sedulous.Editor.Core;

using System;

/// Manages play/pause/stop mode transitions.
/// Serializes the scene before play, restores on stop.
/// Undo history is preserved across play/stop.
class EditorSceneManager
{
	public enum PlayState
	{
		Editing,
		Playing,
		Paused
	}

	private PlayState mState = .Editing;
	private uint8[] mSceneSnapshot ~ delete _; // Serialized scene buffer for restore

	public PlayState State => mState;
	public bool IsPlaying => mState == .Playing;
	public bool IsPaused => mState == .Paused;
	public bool IsEditing => mState == .Editing;

	/// Enter play mode. Serializes the scene, starts full engine ticking.
	public void Play(SceneEditorPage page)
	{
		if (mState != .Editing) return;

		// TODO: Serialize scene to mSceneSnapshot
		// TODO: Start runtime full tick (physics, audio, animation)

		mState = .Playing;
	}

	/// Pause play mode.
	public void Pause()
	{
		if (mState != .Playing) return;
		mState = .Paused;
	}

	/// Resume from pause.
	public void Resume()
	{
		if (mState != .Paused) return;
		mState = .Playing;
	}

	/// Stop play mode. Restore scene from snapshot.
	public void Stop(SceneEditorPage page)
	{
		if (mState == .Editing) return;

		// TODO: Stop runtime ticking
		// TODO: Deserialize scene from mSceneSnapshot

		delete mSceneSnapshot;
		mSceneSnapshot = null;
		mState = .Editing;
	}
}
