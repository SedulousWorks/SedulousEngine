using System;
using Sedulous.Content;
using Sedulous.Core.IO;

namespace Sedulous.Audio.Resource;

/// A re-openable source over a cooked instance's own "data" stream.
///
/// Each play opens an INDEPENDENT seekable stream through the mount, whether that is a
/// directory or an archive, so two voices of one clip never share a cursor.
///
/// The content database owns the instance and outlives every product built from it, which
/// is what makes holding the instance here safe.
class ContentInstanceStreamSource : IAudioStreamSource
{
	private Instance mInstance;

	public this(Instance instance)
	{
		mInstance = instance;
	}

	public IStream OpenStream() => mInstance.ReadData("data");
}
