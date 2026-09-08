using System;
using System.Collections;

namespace Sedulous.Scene;

/// What an instance did to one of its components, kept verbatim while the manager that
/// would apply it is absent.
class PendingPrefabComponentOp
{
	public enum Kind : uint8 { Modify = 0, Add = 1, Remove = 2 }

	public Guid SourceEntity = .();
	public String TypeId = new .() ~ delete _;
	public Kind Op = .Modify;
	/// The payload for a modify or an add; empty for a remove.
	public List<uint8> Blob = new .() ~ delete _;
}
