using System;
using System.Collections;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// One undo step of the particle page: the effect's binary snapshot before and after,
/// coalesced per key so a scrub is one step.
class EditParticleCommand : EditorCommand
{
	/// Borrowed.
	private ParticleEffectEditorPage mPage;
	private String mMergeKey = new .() ~ delete _;
	private List<uint8> mBefore = new .() ~ delete _;
	private List<uint8> mAfter = new .() ~ delete _;

	public this(ParticleEffectEditorPage page, StringView mergeKey, Span<uint8> before, Span<uint8> after)
	{
		mPage = page;
		mMergeKey.Set(mergeKey);
		mBefore.AddRange(before);
		mAfter.AddRange(after);
	}

	public override bool Execute()
	{
		mPage.ApplyEffectBlob(mAfter);
		return true;
	}

	public override void Undo() => mPage.ApplyEffectBlob(mBefore);
	public override StringView TypeId => "edit_particle";

	public override bool MergeInto(EditorCommand previous)
	{
		let prev = previous as EditParticleCommand;
		if ((prev == null) || (prev.mPage !== mPage) || (prev.mMergeKey != mMergeKey))
			return false;
		prev.mAfter.Clear();
		prev.mAfter.AddRange(mAfter);
		return true;
	}
}
