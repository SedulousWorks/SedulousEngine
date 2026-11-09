using System;
using Sedulous.Core.IO;

namespace Sedulous.Scene.Resource;

/// A read-only stream over a loaded prefab's payload, which it BORROWS: what
/// PrefabResource.OpenPayload hands out, so a spawn reads the prefab with no copy and no disk.
///
/// The bytes belong to the resource. A reload or an eviction parks the replaced resource for the
/// frames still in flight, so a stream opened and spent within a frame outlives nothing it reads.
class PrefabPayloadStream : IStream
{
	private Span<uint8> mBytes;
	private int64 mPosition;
	/// Set when PrefabPayloads opened this for a spawn: told when the stream goes, which is when
	/// that spawn has finished with the prefab.
	private PrefabPayloads mOpenIn;
	private Guid mPrefabId;

	public this(Span<uint8> bytes)
	{
		mBytes = bytes;
	}

	public ~this()
	{
		if (mOpenIn != null)
			mOpenIn.[Friend]Closed(mPrefabId);
	}

	public override bool IsValid => true;

	public override int Read(Span<uint8> destination)
	{
		let available = mBytes.Length - (int)mPosition;
		let count = Math.Min(destination.Length, available);
		if (count > 0)
		{
			Internal.MemCpy(destination.Ptr, mBytes.Ptr + mPosition, count);
			mPosition += count;
		}
		return count;
	}

	/// Read-only: nothing is written.
	public override int Write(Span<uint8> source) => 0;

	public override int64 Seek(int64 offset, SeekOrigin origin)
	{
		int64 start;
		switch (origin)
		{
		case .Begin: start = 0;
		case .Current: start = mPosition;
		case .End: start = mBytes.Length;
		}

		let target = start + offset;
		if ((target < 0) || (target > mBytes.Length))
			return -1;
		mPosition = target;
		return target;
	}

	public override int64 Tell() => mPosition;
	public override int64 Size() => mBytes.Length;

	private void OpenedIn(PrefabPayloads payloads, Guid prefabId)
	{
		mOpenIn = payloads;
		mPrefabId = prefabId;
	}
}
