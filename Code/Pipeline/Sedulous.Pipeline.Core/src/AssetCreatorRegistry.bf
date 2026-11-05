using System;
using System.Collections;

namespace Sedulous.Pipeline.Core;

/// Every asset creator a host offers, in registration order: each pipeline domain
/// contributes its own (PipelineRegistration.RegisterAllCreators composes them), and the
/// editor's New menus and the MCP creation tools read the one list.
class AssetCreatorRegistry
{
	private List<AssetCreator> mCreators = new .() ~ DeleteContainerAndItems!(_);
	/// Beside mCreators: each one's key.
	private List<uint64> mKeys = new .() ~ delete _;
	private uint64 mNextKey = 1;

	/// TAKES OWNERSHIP; its key for Unregister (0, nothing added, for null).
	public uint64 Register(AssetCreator creator)
	{
		if (creator == null)
			return 0;
		mCreators.Add(creator);
		mKeys.Add(mNextKey);
		return mNextKey++;
	}

	/// Removes (and deletes) the creator Register gave `key` for; false when there is none. A
	/// plugin's creators leave with it this way.
	public bool Unregister(uint64 key)
	{
		let index = mKeys.IndexOf(key);
		if (index < 0)
			return false;
		delete mCreators[index];
		mCreators.RemoveAt(index);
		mKeys.RemoveAt(index);
		return true;
	}

	public int Count => mCreators.Count;
	public AssetCreator this[int index] => mCreators[index];
	public List<AssetCreator>.Enumerator GetEnumerator() => mCreators.GetEnumerator();

	/// The creator labelled `label` (case-insensitive), or null.
	public AssetCreator FindByLabel(StringView label)
	{
		for (let creator in mCreators)
		{
			if (StringView.Compare(creator.Label, label, true) == 0)
				return creator;
		}
		return null;
	}

	/// The ONE creator of `typeName`, or null when there is none or several (materials come
	/// as PBR and Unlit, so the type alone does not say which).
	public AssetCreator FindByType(StringView typeName)
	{
		AssetCreator found = null;
		for (let creator in mCreators)
		{
			if (creator.TypeName != typeName)
				continue;
			if (found != null)
				return null;
			found = creator;
		}
		return found;
	}
}
