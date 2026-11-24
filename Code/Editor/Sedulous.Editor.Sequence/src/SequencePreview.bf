using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Resource;
using Sedulous.Scene;
using Sedulous.Sequence;

namespace Sedulous.Editor.Sequence;

/// Poses the scene with a sequence at a time, through the same play the game runs
/// (SequencePlay.Pose: no events, no sounds), so what the panel shows is what plays. Its play
/// finishes by restoring, so stopping the preview puts back every value it wrote and lets go of
/// what it holds (the fade, a camera cut, a clip's overlay). None of it becomes a step in the
/// scene's history or touches its unsaved mark. The cast is the preview's own (a name and an entity
/// of the scene for each binding), since a sequence names its cast and the game fills it.
///
/// It plays a copy of the sequence of its own, taken when a play begins: the document deletes its
/// tracks on every change, and a play's runners hold the tracks they began on until it stops.
class SequencePreview
{
	private class CastEntry
	{
		public String Name = new .() ~ delete _;
		public Guid Entity;
	}

	/// BORROWED, both.
	private Scene mScene;
	private ResourceManager mResources;
	private List<CastEntry> mCast = new .() ~ DeleteContainerAndItems!(_);
	/// Declared before the copy it plays, so it goes first.
	private SequencePlay mPlay = null;
	/// What mPlay plays: the preview's own copy.
	private Sedulous.Sequence.Sequence mPlayed = null;
	/// The sequence and version the copy was taken from; compared, never read.
	private Sedulous.Sequence.Sequence mSource = null;
	private uint64 mVersion = 0;

	/// `resources`, when given, binds what the copy's tracks refer to (a clip, a sound).
	public this(Scene scene, ResourceManager resources = null)
	{
		mScene = scene;
		mResources = resources;
	}

	public ~this()
	{
		Stop();
	}

	public bool IsPosing => mPlay != null;

	/// Fills the binding `name` with the scene's entity `entity` (nil empties it). A preview posing
	/// begins again with it.
	public void Bind(StringView name, Guid entity)
	{
		for (int i < mCast.Count)
		{
			if (mCast[i].Name != name)
				continue;
			if (mCast[i].Entity == entity)
				return;
			// What the old entity showed goes back first.
			Stop();
			if (entity == .Empty)
			{
				delete mCast[i];
				mCast.RemoveAt(i);
			}
			else
				mCast[i].Entity = entity;
			return;
		}
		if (entity == .Empty)
			return;
		Stop();
		let entry = new CastEntry();
		entry.Name.Set(name);
		entry.Entity = entity;
		mCast.Add(entry);
	}

	/// The entity filling `name`; nil when none.
	public Guid BoundEntity(StringView name)
	{
		for (let entry in mCast)
		{
			if (entry.Name == name)
				return entry.Entity;
		}
		return .Empty;
	}

	/// Empties every binding.
	public void ClearCast()
	{
		Stop();
		ClearAndDeleteItems!(mCast);
	}

	/// Poses the scene with `sequence` at `time`. A different sequence, or another `version` of it
	/// (its tracks rebuilt), begins the play again, after restoring what the last one wrote.
	public void Pose(Sedulous.Sequence.Sequence sequence, uint64 version, float time)
	{
		if ((mPlay != null) && ((mSource !== sequence) || (mVersion != version)))
			Stop();
		if (mPlay == null)
		{
			mPlayed = SequenceBytes.Copy(sequence, mResources);
			mPlay = new .(mScene, mPlayed);
			mPlay.Finish = .Restore;
			for (let entry in mCast)
			{
				let entity = mScene.FindEntity(entry.Entity);
				if (entity.IsAssigned)
					mPlay.Bind(entry.Name, entity);
			}
			mSource = sequence;
			mVersion = version;
		}
		mPlay.Pose(time);
	}

	/// Restores what the preview wrote and ends it.
	public void Stop()
	{
		if (mPlay == null)
			return;
		// The Restore finish puts every written value back, then the play goes before its copy.
		mPlay.Stop();
		DeleteAndNullify!(mPlay);
		DeleteAndNullify!(mPlayed);
		mSource = null;
	}
}
