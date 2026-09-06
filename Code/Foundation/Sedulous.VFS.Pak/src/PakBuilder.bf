using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;

namespace Sedulous.VFS.Pak;

/// The offline writer: add entries, then write the archive.
///
/// Nothing reads a .pak into existence at runtime, so this has no counterpart on the
/// PakFileSystem side. It is a build-time tool that happens to live beside the reader so
/// the two cannot disagree about the format.
class PakBuilder
{
	private struct PendingEntry : IDisposable
	{
		public String Locator;
		public List<uint8> Data;

		public void Dispose() mut
		{
			delete Locator;
			delete Data;
		}
	}

	private List<PendingEntry> mEntries = new .() ~ delete _;

	public ~this()
	{
		for (var entry in ref mEntries)
			entry.Dispose();
	}

	public int Count => mEntries.Count;

	/// Copies the data immediately, so the caller may free its buffer straight after.
	public void Add(StringView locator, Span<uint8> data)
	{
		let pending = PendingEntry()
			{
				Locator = new String(locator),
				Data = new List<uint8>()
			};
		if (data.Length > 0)
		{
			let raw = pending.Data.GrowUninitialized(data.Length);
			Internal.MemCpy(raw, data.Ptr, data.Length);
		}
		mEntries.Add(pending);
	}

	public Result<void, ErrorCode> Write(StringView path)
	{
		let output = scope MemoryStream();
		let writer = scope BinaryWriter(output);

		uint64 tocOffset = 0;
		uint64 tocSize = 0;

		// A placeholder, patched once the offsets are known.
		WriteHeader(writer, (uint64)mEntries.Count, tocOffset, tocSize);

		let offsets = scope List<uint64>();
		for (let entry in mEntries)
		{
			offsets.Add((uint64)output.Tell());
			if (!entry.Data.IsEmpty)
				writer.WriteBytes(.(entry.Data.Ptr, entry.Data.Count));
		}

		tocOffset = (uint64)output.Tell();
		for (int i < mEntries.Count)
		{
			let locator = mEntries[i].Locator;
			let locatorLength = (uint16)locator.Length;
			writer.Write(locatorLength);
			if (locatorLength > 0)
				writer.WriteBytes(.((uint8*)locator.Ptr, locator.Length));

			let size = (uint64)mEntries[i].Data.Count;
			writer.Write(offsets[i]);
			writer.Write(size); // stored
			writer.Write(size); // original, since nothing is compressed yet
			writer.Write(cCompressionNone);
		}
		tocSize = (uint64)output.Tell() - tocOffset;

		// Patch the header now that the table is placed.
		if (output.Seek(0, .Begin) != 0)
			return .Err(.Internal);
		WriteHeader(writer, (uint64)mEntries.Count, tocOffset, tocSize);

		if (!writer.IsOk)
			return .Err(.Internal);

		return WriteFile(path, output.Bytes);
	}

	private static void WriteHeader(BinaryWriter writer, uint64 entryCount, uint64 tocOffset, uint64 tocSize)
	{
		writer.Write(cPakMagic);
		writer.Write(cPakVersion);
		writer.Write(entryCount);
		writer.Write(tocOffset);
		writer.Write(tocSize);
	}
}
