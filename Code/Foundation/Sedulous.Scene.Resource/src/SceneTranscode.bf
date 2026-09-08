using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Scene;

namespace Sedulous.Scene.Resource;

/// Turning a source scene into the wire the player reads.
///
/// A source is text because people diff it; a shipped product is binary because nothing
/// reads it but the engine. Export is where one becomes the other, and it goes through the
/// SAME serialization path in both directions, so a transcode cannot invent a difference.
static class SceneTranscode
{
	/// Reads `input` in whichever encoding it is and writes the binary form.
	///
	/// `scratch` must be an EMPTY scene carrying the application's FULL manager and system
	/// set. Assemble it from the whole composition: a hand listed set SILENTLY DROPS the
	/// components it does not cover.
	///
	/// Why it cannot be otherwise. A record whose manager is absent is preserved in the
	/// encoding it was captured in, and a TEXT capture is markup rather than bytes: turning
	/// it into the binary wire means understanding it, and understanding it means having
	/// the manager. So a text source needs the managers and a binary one does not, which is
	/// exactly backwards from what a caller would guess. Hence the rule above rather than a
	/// best effort.
	///
	/// Parked prefab descriptors re-emit verbatim, so no resolver or spawn is needed.
	public static Result<void, ErrorCode> ToBinary(IStream input, Scene scratch,
		List<uint8> outBytes, bool includeSettings = true)
	{
		// Already binary: copy it through rather than round tripping, which would rewrite
		// bytes that were fine and could only lose something.
		if (SceneStreamFormat.DetectEncoding(input) == .Binary)
		{
			let remaining = (int)(input.Size() - input.Tell());
			outBytes.Resize(remaining);
			if ((remaining > 0) && (input.Read(outBytes) != remaining))
				return .Err(.Unknown);
			return .Ok;
		}

		let reader = scope SceneStreamReader();
		if (!(reader.Open(input) case .Ok(let ar)))
			return .Err(.InvalidArgument);

		SceneSerializer.SerializeScene(ar, scratch, .Referenced, includeSettings, reader.Encoding);
		if (!ar.IsOk)
			return ar.Status;

		let buffer = scope MemoryStream();
		{
			let writer = scope BinarySerializer(buffer, .Write);
			SceneSerializer.SerializeScene(writer, scratch, .Referenced, includeSettings, .Binary);
			if (!writer.IsOk)
				return writer.Status;
		}

		outBytes.Clear();
		outBytes.AddRange(buffer.Bytes);
		return .Ok;
	}
}
