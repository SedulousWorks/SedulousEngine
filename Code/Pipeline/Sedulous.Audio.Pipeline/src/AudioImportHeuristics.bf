using System;

namespace Sedulous.Audio.Pipeline;

/// The pure decisions an import makes, testable without a project behind them.
static class AudioImportHeuristics
{
	/// Whether a source should STREAM by default: something long or large does, and a short
	/// effect stays in memory.
	///
	/// Computed at import; the asset's own field stays editable afterwards, so this is a
	/// starting point rather than a rule.
	public static bool ShouldStreamByDefault(float durationSeconds, int sizeBytes)
		=> (durationSeconds > 10.0f) || (sizeBytes > 2 * 1024 * 1024);

	/// Scans a RIFF container for its first sampler loop.
	///
	/// A pure byte walk with no decoder in it: the loop points an author set in their editor
	/// are metadata, and reading them costs nothing.
	public static bool ParseWavSampleLoop(Span<uint8> wavBytes, out uint64 outLoopStartFrame,
		out uint64 outLoopEndFrame)
	{
		outLoopStartFrame = 0;
		outLoopEndFrame = 0;

		uint32 ReadU32(int offset)
			=> (uint32)wavBytes[offset] | ((uint32)wavBytes[offset + 1] << 8)
				| ((uint32)wavBytes[offset + 2] << 16) | ((uint32)wavBytes[offset + 3] << 24);

		bool TagIs(int offset, StringView tag)
			=> (wavBytes[offset] == (uint8)tag[0]) && (wavBytes[offset + 1] == (uint8)tag[1])
				&& (wavBytes[offset + 2] == (uint8)tag[2]) && (wavBytes[offset + 3] == (uint8)tag[3]);

		if ((wavBytes.Length < 12) || !TagIs(0, "RIFF") || !TagIs(8, "WAVE"))
			return false;

		var cursor = 12;
		while ((cursor + 8) <= wavBytes.Length)
		{
			let chunkSize = (int)ReadU32(cursor + 4);
			if (TagIs(cursor, "smpl"))
			{
				// The sampler chunk is thirty six bytes of fields, the loop count at
				// twenty eight, then twenty four byte loop records whose start and end sit at
				// eight and twelve within each.
				let body = cursor + 8;
				if ((chunkSize >= 36 + 24) && ((body + 36 + 24) <= wavBytes.Length)
					&& (ReadU32(body + 28) >= 1))
				{
					outLoopStartFrame = ReadU32(body + 36 + 8);
					outLoopEndFrame = ReadU32(body + 36 + 12);
					return outLoopEndFrame > outLoopStartFrame;
				}
				return false;
			}
			cursor += 8 + chunkSize + (chunkSize & 1); // chunks are word aligned
		}
		return false;
	}
}
