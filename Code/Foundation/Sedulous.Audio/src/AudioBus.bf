using Sedulous.Core;

namespace Sedulous.Audio;

/// The FIXED bus layout: everything feeds Master, through one of three.
///
/// This enum IS the topology, and it is the addressing model components and saved data use.
/// Named buses are additive on top of it rather than a replacement for it.
[Scriptable(.AllPublic)]
enum AudioBus : uint8
{
	case Master = 0;
	/// One shots and world sounds.
	case Effects = 1;
	/// Streamed music, routed through the graph like everything else rather than around it.
	case Music = 2;
	case UI = 3;

	public const int Count = 4;
}
