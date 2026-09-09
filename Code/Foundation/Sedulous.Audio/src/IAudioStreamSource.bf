using Sedulous.Core.IO;

namespace Sedulous.Audio;

/// A RE-OPENABLE byte source for a streamed clip.
///
/// Each open answers an INDEPENDENT seekable stream over the same encoded bytes: the engine
/// opens one per playing voice and pages through it on its own threads, so two voices of the
/// same clip must not share a cursor.
///
/// THE CALLER OWNS what comes back.
interface IAudioStreamSource
{
	IStream OpenStream();
}
