using System;

namespace System;

/// The nil test, by name: an id field left unset reads as nil.
extension Guid
{
	public bool IsNil => !IsSet;
}
