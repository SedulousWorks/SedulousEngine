using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Content;

/// Two databases seen as one: a PRIMARY that answers first, and a FALLBACK consulted only for
/// a record whose stored type the fall-through predicate accepts.
///
/// What an editor reads resources through: its cooked products first, and beneath them its
/// sources, for the authored records the cook never builds (a prefab document) and so only the
/// sources hold. Which stored types fall through is not decided here: the view names no type,
/// and the predicate comes from whoever reads through it (a resource manager answers from its
/// registered factories, ResourceManager.ReadsAuthoredRecord). Without a predicate nothing
/// falls through, so a source record (a texture's envelope) never reaches a reader that
/// expects the cooked form of it.
///
/// Records are answered from whichever database holds them, so an instance's object and data
/// streams read from that database's files. The tree (RootGroup) is the primary's.
///
/// Both databases are BORROWED and must outlive the view.
class LayeredContentDatabase : IContentDatabase
{
	private IContentDatabase mPrimary;
	private IContentDatabase mFallback;
	private delegate bool(StringView storedTypeName) mFallsThrough ~ delete _;

	public this(IContentDatabase primary, IContentDatabase fallback)
	{
		mPrimary = primary;
		mFallback = fallback;
	}

	public IContentDatabase Primary => mPrimary;
	public IContentDatabase Fallback => mFallback;

	/// Which stored types the fallback may answer for. TAKES OWNERSHIP; null lets nothing fall
	/// through. A predicate that asks something else (a resource manager) must be cleared, or the
	/// view destroyed, before that goes.
	public void SetFallthrough(delegate bool(StringView storedTypeName) fallsThrough)
	{
		delete mFallsThrough;
		mFallsThrough = fallsThrough;
	}

	public Group RootGroup => mPrimary.RootGroup;

	public Instance GetInstance(Guid id)
	{
		if (let found = mPrimary.GetInstance(id))
			return found;
		return Fallen((mFallback != null) ? mFallback.GetInstance(id) : null);
	}

	public Instance GetInstanceByPath(StringView path)
	{
		if (let found = mPrimary.GetInstanceByPath(path))
			return found;
		return Fallen((mFallback != null) ? mFallback.GetInstanceByPath(path) : null);
	}

	public ISerializable ReadObject(Guid id)
	{
		let instance = GetInstance(id);
		return (instance != null) ? instance.ReadObject() : null;
	}

	/// The fallback's record when its stored type falls through, else null.
	private Instance Fallen(Instance instance)
	{
		if ((instance == null) || (mFallsThrough == null))
			return null;
		return mFallsThrough(instance.TypeName) ? instance : null;
	}
}
