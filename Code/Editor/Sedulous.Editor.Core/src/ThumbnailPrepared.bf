using System;
using System.Collections;
using Sedulous.Core.IO;

namespace Sedulous.Editor.Core;

/// What a thumbnail generator's MAIN thread half hands to its worker half.
///
/// The point of the split is that reading is the expensive part. Prepare opens what it needs
/// and composes a small header; the worker reads the stream and the generator sees the header
/// followed by the bytes. Reading the source whole on the main thread, which is what a payload
/// of bytes forced, froze the asset browser for as long as the file took: a large image, a
/// wave, a font, up to a burst of them per frame.
///
/// Either half may be empty. A generator whose whole input is small enough to compose on the
/// main thread, or which reads from the instance's own streams, can fill only the header.
class ThumbnailPrepared
{
	/// Composed on the MAIN thread, and handed to Generate first.
	public List<uint8> Header = new .() ~ delete _;

	/// OWNED, and read on the LIGHT worker: its bytes follow the header.
	///
	/// Opening a stream is cheap and touches the content database, which is why it happens on
	/// the main thread; draining it is what moves.
	public IStream Stream = null ~ delete _;

	public this() {}

	/// Takes the stream, which the caller must not keep.
	public void TakeStream(IStream stream)
	{
		delete Stream;
		Stream = stream;
	}
}
