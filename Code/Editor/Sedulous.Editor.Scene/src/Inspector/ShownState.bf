using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Scene;

/// What an inspector source showed at its last look, as the bytes its data serializes to. A source
/// the inspector looks at every frame (its data may change under it: an undo, a simulation) tells
/// the grid only when Take finds the bytes moved, so a frame where nothing moved costs the grid no
/// layout.
class ShownState
{
	private List<uint8> mSeen = new .() ~ delete _;
	private bool mLooked = false;

	/// Whether what `write` serializes differs from the last look, remembering it. The first look
	/// returns true.
	public bool Take(delegate void(ISerializer ar) write)
	{
		let buffer = scope MemoryStream();
		{
			let ar = scope BinarySerializer(buffer, .Write);
			write(ar);
		}
		let now = buffer.Bytes;
		var same = mLooked && (now.Length == mSeen.Count);
		for (int i = 0; same && (i < now.Length); i++)
			same = now[i] == mSeen[i];
		if (same)
			return false;
		mSeen.Clear();
		mSeen.AddRange(now);
		mLooked = true;
		return true;
	}
}
