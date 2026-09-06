using System;
using System.Collections;

namespace Sedulous.Settings;

/// A section kept verbatim because no type of that name was registered when it loaded.
///
/// Re-emitted by the next Save inside its frame, so a NEWER settings file survives an
/// OLDER build reading and writing it. Without this, running an older build once silently
/// deletes every setting it did not recognise.
class UnknownSection
{
	public String TypeName = new .() ~ delete _;
	/// The framed payload bytes exactly as they were read.
	public List<uint8> Payload = new .() ~ delete _;
}
