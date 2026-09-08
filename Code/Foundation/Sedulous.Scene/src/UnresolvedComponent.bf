using System;
using System.Collections;

namespace Sedulous.Scene;

/// A component record whose manager was not there when the scene loaded, because its
/// plugin did not load, or has not loaded YET.
///
/// Kept VERBATIM so a save writes it back untouched rather than dropping it, and turned
/// into a real component the moment its manager arrives. `Text` says which serializer
/// captured the payload, and it is written back through that same encoding only.
class UnresolvedComponent
{
	public Guid Owner = .();
	/// The manager's serialization id.
	public String TypeId = new .() ~ delete _;
	public List<uint8> Payload = new .() ~ delete _;
	public bool Text = false;
}
