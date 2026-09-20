using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Editor.Scene;

/// One state in the edit model with its node: a clip, or a blend tree whose entries are
/// kept as parallel lists so a 1D and a 2D tree share the shape.
class GraphState
{
	public String Name = new .() ~ delete _;
	public float Speed = 1.0f;
	public bool Loop = true;
	/// 0 clip, 1 one dimensional blend tree, 2 two dimensional.
	public uint8 NodeKind = 0;
	public Guid ClipRef = .();
	public int32 ParamIndex = -1;
	public int32 ParamIndexX = -1;
	public int32 ParamIndexY = -1;
	public List<Guid> EntryClips = new .() ~ delete _;
	public List<float> EntryThresholds = new .() ~ delete _;
	public List<Float2> EntryPositions = new .() ~ delete _;

	/// Pads the threshold and position lists to the clip list, so a row exists for each.
	public void NormalizeEntries()
	{
		while (EntryThresholds.Count < EntryClips.Count)
			EntryThresholds.Add(0.0f);
		while (EntryPositions.Count < EntryClips.Count)
			EntryPositions.Add(.(0.0f, 0.0f));
	}

	public void AddEntry()
	{
		NormalizeEntries();
		EntryClips.Add(.());
		EntryThresholds.Add(0.0f);
		EntryPositions.Add(.(0.0f, 0.0f));
	}

	public bool RemoveEntry(int index)
	{
		NormalizeEntries();
		if ((index < 0) || (index >= EntryClips.Count))
			return false;
		EntryClips.RemoveAt(index);
		EntryThresholds.RemoveAt(index);
		EntryPositions.RemoveAt(index);
		return true;
	}
}
