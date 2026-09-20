using System;
using System.Collections;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Terrain;

/// One undo step of the terrain page: the asset's binary snapshot before and after,
/// coalesced per key so a scrub is one step.
class EditTerrainCommand : EditorCommand
{
	/// Borrowed.
	private TerrainEditorPage mPage;
	private String mMergeKey = new .() ~ delete _;
	private List<uint8> mBefore = new .() ~ delete _;
	private List<uint8> mAfter = new .() ~ delete _;

	public this(TerrainEditorPage page, StringView mergeKey, Span<uint8> before, Span<uint8> after)
	{
		mPage = page;
		mMergeKey.Set(mergeKey);
		mBefore.AddRange(before);
		mAfter.AddRange(after);
	}

	public override bool Execute()
	{
		mPage.ApplyBlob(mAfter);
		return true;
	}

	public override void Undo() => mPage.ApplyBlob(mBefore);
	public override StringView TypeId => "edit_terrain";

	public override bool MergeInto(EditorCommand previous)
	{
		let prev = previous as EditTerrainCommand;
		if ((prev == null) || (prev.mPage !== mPage) || (prev.mMergeKey != mMergeKey))
			return false;
		prev.mAfter.Clear();
		prev.mAfter.AddRange(mAfter);
		return true;
	}
}
