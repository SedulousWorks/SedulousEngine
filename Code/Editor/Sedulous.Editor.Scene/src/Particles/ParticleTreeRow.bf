using System;
using Sedulous.UI;

namespace Sedulous.Editor.Scene;

/// A particle tree row: an editable label, renamable only for a system.
class ParticleTreeRow : EditableLabel
{
	private ParticleNodeKind mKind = .Effect;
	private int32 mSystemIndex = -1;

	public ParticleNodeKind Kind => mKind;
	public int32 SystemIndex => mSystemIndex;

	public void Bind(StringView label, float textInset, ParticleNodeKind kind, int32 systemIndex)
	{
		mKind = kind;
		mSystemIndex = systemIndex;
		SetText(label);
		TextOffsetX.Value = textInset;
		let renamable = kind == .System;
		DoubleClickToEdit.Value = renamable;
		SlowClickToEdit.Value = renamable;
	}
}
