using System;
using Sedulous.Core;

namespace System;

/// Guid on the script surface.
///
/// Corlib owns the type, so the attribute goes on an EXTENSION; reflection reports it on Guid
/// all the same, which is what [[ExtensionAttributeTests]] pins. Raptor exposes the same
/// thing: the value, Nil, and the nil test.
///
/// MarkedOnly rather than AllPublic, because this is not our type to characterise: corlib
/// decides what is public on it and that can change under us.
[Scriptable]
extension Guid
{
}
