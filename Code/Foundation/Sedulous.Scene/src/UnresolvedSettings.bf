using System;
using System.Collections;

namespace Sedulous.Scene;

/// A scene SYSTEM's settings block, preserved while the system that owns it is absent and
/// replayed into it when its plugin arrives. The same bargain UnresolvedComponent makes,
/// one level up.
class UnresolvedSettings
{
	/// The system's settings id.
	public String SystemId = new .() ~ delete _;
	public List<uint8> Payload = new .() ~ delete _;
	public bool Text = false;
}
