using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Engine.GameInstance;

/// A run's quality levels to its game, reached as `GameInstance.Quality`: what an options menu's
/// graphics setting lists, the level the game plays at, and a switch.
///
///     for (int32 i < quality.Count()) list(quality.Label(i));
///     quality.Set("Low");
///
/// The host fills it and decides what choosing does (the player plays at the level and keeps the
/// choice in the user's settings; a Game tab plays at it for the session). It holds each level's
/// id and label, in the project's order; the host resolves the values. A run that offers none
/// counts none, reads an empty label and refuses a set.
class RenderQualityFacade
{
	private struct Offered
	{
		public Guid Id;
		public String Label;
	}

	private List<Offered> mLevels = new .() ~ { for (let level in _) delete level.Label; delete _; };
	/// The level played at; nil: the engine's own.
	private Guid mCurrent;
	/// OWNED: plays at the level chosen and keeps the choice; Current is the level's when it runs.
	private delegate void(Guid id) mOnChoose ~ delete _;

	// === The host's ===

	/// Offers no levels.
	public void Clear()
	{
		for (let level in mLevels)
			delete level.Label;
		mLevels.Clear();
		mCurrent = .();
	}

	/// Offers a level, after those offered already.
	public void Add(Guid id, StringView label)
	{
		mLevels.Add(.() { Id = id, Label = new String(label) });
	}

	/// The level the game plays at; nil: the engine's own.
	public Guid CurrentId
	{
		get => mCurrent;
		set => mCurrent = value;
	}

	/// The id of the level labelled `label`; nil when none is.
	public Guid Find(StringView label)
	{
		for (let level in mLevels)
		{
			if (level.Label == label)
				return level.Id;
		}
		return .();
	}

	/// Whether `id` is one of the levels offered.
	public bool Offers(Guid id)
	{
		for (let level in mLevels)
		{
			if (level.Id == id)
				return true;
		}
		return false;
	}

	/// What choosing a level does. TAKES OWNERSHIP of `onChoose`, which replaces any earlier one.
	public void SetOnChoose(delegate void(Guid id) onChoose)
	{
		delete mOnChoose;
		mOnChoose = onChoose;
	}

	// === The game's ===

	/// How many levels the game offers.
	public int32 Count() => (int32)mLevels.Count;

	/// The label of the level at `index`, in the project's order; empty past the end.
	public StringView Label(int32 index) => ((index >= 0) && (index < mLevels.Count)) ? mLevels[index].Label : "";

	/// The label of the level the game plays at (empty: the engine's own).
	public StringView Current()
	{
		for (let level in mLevels)
		{
			if (level.Id == mCurrent)
				return level.Label;
		}
		return "";
	}

	/// Plays at the level labelled `label` now and keeps the choice; false, and nothing changes,
	/// for a label the game does not offer.
	public bool Set(StringView label)
	{
		for (let level in mLevels)
		{
			if (level.Label != label)
				continue;
			mCurrent = level.Id;
			if (mOnChoose != null)
				mOnChoose(level.Id);
			return true;
		}
		return false;
	}
}
