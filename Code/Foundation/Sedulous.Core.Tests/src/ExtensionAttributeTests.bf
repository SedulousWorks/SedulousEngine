using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// An attribute on an EXTENSION reaches the extended type.
///
/// Which is what makes a type we do not own markable. Guid is corlib's, so there is nowhere
/// to write [Scriptable] on its declaration, and without this a generator would need a list
/// of externally bound types kept by hand beside the attributes. It does not: the extension
/// carries the attribute and reflection reports it on Guid itself.
///
/// Pinned because the whole approach rests on it. If a Beef release stopped reporting an
/// extension's attributes, every corlib type would drop off the script surface silently.
static class ExtensionAttributeTests
{
	[Test]
	public static void AnExtensionsAttributeReachesTheExtendedType()
	{
		Test.Assert(typeof(System.Guid).HasCustomAttribute<ScriptableAttribute>(),
			"an extension's attribute did not reach the extended type");
	}
}
