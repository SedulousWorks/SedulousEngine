using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Audio;

namespace Sedulous.Audio.Tests;

/// A re-openable source over bytes already in memory, which is what a pak facing adapter
/// does over a mounted archive.
///
/// Each open answers an INDEPENDENT stream, because two voices of one clip must not share
/// a cursor.
class MemoryStreamSource : IAudioStreamSource
{
	private List<uint8> mBytes = new .() ~ delete _;

	public this(Span<uint8> bytes)
	{
		mBytes.AddRange(bytes);
	}

	public IStream OpenStream()
	{
		let stream = new MemoryStream();
		if (stream.Write(mBytes) != mBytes.Count)
		{
			delete stream;
			return null;
		}
		stream.Seek(0, .Begin);
		return stream;
	}
}
