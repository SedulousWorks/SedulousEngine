using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Navigation;

/// The serialized navmesh blob: a self describing header, the tile grid it was baked on, and
/// one record per non empty tile.
///
/// There is ONE format, the tiled one. The retired single tile version is refused rather than
/// read, because a blob that loads into the wrong shape is worse than one that does not load.
static class NavigationBlob
{
	/// 'DANV' the way a little endian machine reads it.
	public const uint32 Magic = 0x564E4144;
	public const uint32 VersionTiled = 2;

	[CRepr, Packed]
	public struct Header
	{
		public uint32 Magic;
		public uint32 Version;
		public float AgentRadius;
		public float AgentHeight;
		/// Covers the info block and every tile record after it.
		public uint32 NavDataSize;
	}

	[CRepr, Packed]
	public struct TiledInfo
	{
		public float[3] Origin;
		public float TileWorldSize;
		public int32 TileCountX;
		public int32 TileCountY;
		/// The records that follow. An empty tile is simply absent.
		public uint32 TileCount;
	}

	[CRepr, Packed]
	public struct TileRecord
	{
		public int32 TileX;
		public int32 TileY;
		public uint32 DataSize;
	}

	public const int HeaderSize = sizeof(Header);
	public const int TiledInfoSize = sizeof(TiledInfo);
	public const int TileRecordSize = sizeof(TileRecord);

	/// Reads a value out of a blob at an offset, or false when the blob is too short.
	public static bool Read<T>(Span<uint8> blob, int offset, out T value) where T : struct
	{
		value = default;
		if ((offset < 0) || ((offset + sizeof(T)) > blob.Length))
			return false;
		Internal.MemCpy(&value, &blob[offset], sizeof(T));
		return true;
	}

	public static void Append<T>(List<uint8> blob, T value) where T : struct
	{
		var value;
		let from = blob.Count;
		blob.Count = from + sizeof(T);
		Internal.MemCpy(&blob[from], &value, sizeof(T));
	}

	public static void Append(List<uint8> blob, Span<uint8> bytes)
	{
		if (bytes.IsEmpty)
			return;
		let from = blob.Count;
		blob.Count = from + bytes.Length;
		Internal.MemCpy(&blob[from], bytes.Ptr, bytes.Length);
	}

	/// The grid a blob was baked on. False for anything that is not a tiled blob.
	public static bool ReadGrid(Span<uint8> blob, out NavigationTileGridDesc outGrid)
	{
		outGrid = .();

		if (!Read<Header>(blob, 0, let header))
			return false;
		if ((header.Magic != Magic) || (header.Version != VersionTiled))
			return false;
		if (!Read<TiledInfo>(blob, HeaderSize, let info))
			return false;

		outGrid.Origin = .(info.Origin[0], info.Origin[1], info.Origin[2]);
		outGrid.TileWorldSize = info.TileWorldSize;
		outGrid.CountX = info.TileCountX;
		outGrid.CountY = info.TileCountY;
		return (outGrid.TileWorldSize > 0.0f) && (outGrid.CountX > 0) && (outGrid.CountY > 0);
	}

	/// Replaces one tile's record in a blob, inserting it when absent and REMOVING it when the
	/// data is empty.
	///
	/// Every other tile's bytes are copied verbatim and the target goes into its ROW MAJOR
	/// position, so a patched blob is byte for byte what a full rebake of the same edited
	/// geometry would have produced.
	public static bool Patch(List<uint8> blob, int32 tileX, int32 tileY, Span<uint8> tileData)
	{
		if (!Read<Header>(blob, 0, var header))
			return false;
		if ((header.Magic != Magic) || (header.Version != VersionTiled))
			return false;
		if (!Read<TiledInfo>(blob, HeaderSize, var info))
			return false;

		let payload = scope List<uint8>();
		let targetOrder = (int64)tileY * (int64)info.TileCountX + tileX;

		var cursor = HeaderSize + TiledInfoSize;
		var written = (uint32)0;
		var placed = false;

		for (uint32 i = 0; i < info.TileCount; i++)
		{
			if (!Read<TileRecord>(blob, cursor, let record))
				return false;
			let recordBytes = TileRecordSize + (int)record.DataSize;
			if ((cursor + recordBytes) > blob.Count)
				return false;

			let order = (int64)record.TileY * (int64)info.TileCountX + record.TileX;
			if (!placed && (order >= targetOrder))
			{
				if (!tileData.IsEmpty)
				{
					AppendTarget(payload, tileX, tileY, tileData);
					written++;
				}
				placed = true;

				if (order == targetOrder)
				{
					// The original this replaces is skipped rather than copied.
					cursor += recordBytes;
					continue;
				}
			}

			Append(payload, Span<uint8>((uint8*)&blob[cursor], recordBytes));
			cursor += recordBytes;
			written++;
		}

		if (!placed && !tileData.IsEmpty)
		{
			AppendTarget(payload, tileX, tileY, tileData);
			written++;
		}

		// A blob with no tiles at all would not load, so it is refused rather than written.
		if (written == 0)
			return false;

		info.TileCount = written;
		header.NavDataSize = (uint32)(TiledInfoSize + payload.Count);

		blob.Clear();
		Append(blob, header);
		Append(blob, info);
		Append(blob, Span<uint8>(payload.Ptr, payload.Count));
		return true;
	}

	private static void AppendTarget(List<uint8> payload, int32 tileX, int32 tileY,
		Span<uint8> tileData)
	{
		let record = TileRecord()
			{
				TileX = tileX,
				TileY = tileY,
				DataSize = (uint32)tileData.Length
			};
		Append(payload, record);
		Append(payload, tileData);
	}
}
