using System;
using Sedulous.Core;

namespace System;

/// Guid on the script surface.
///
/// Corlib owns the type, so the attribute goes on an EXTENSION; reflection reports it on Guid
/// all the same, which is what [[ExtensionAttributeTests]] pins. The surface is the value,
/// Nil, and the nil test.
///
/// MarkedOnly rather than AllPublic, because this is not our type to characterise: corlib
/// decides what is public on it and that can change under us. An extension cannot mark a
/// member corlib declares either, so the script facing members are declared here.
[Scriptable]
extension Guid
{
	[Scriptable]
	public static Guid Nil => Empty;

	[Scriptable]
	public bool IsNil => !IsSet;

	/// The parse a script can use: Nil rather than an error for text that is not a guid.
	[Scriptable]
	public static Guid FromString(StringView text)
	{
		if (Parse(text) case .Ok(let guid))
			return guid;
		return Empty;
	}
}
