using System;
using System.Collections;

namespace Sedulous.Scene;

/// One component's state AS OF SPAWN, captured so an override can be derived rather than
/// tracked.
class PrefabComponentBaseline
{
	public Guid SourceEntity = .();
	/// The owning manager's serialization id.
	public String TypeId = new .() ~ delete _;
	/// The binary capture taken at spawn.
	public List<uint8> Blob = new .() ~ delete _;
}
