using System;
using Sedulous.Core;
using Sedulous.Core.Serialization;

namespace Sedulous.Core.Tests;

/// A three level chain, so the walk is tested against something deeper than one base.
///
/// Inheritance is how Raptor describes a family of stored types: a skinned mesh source IS
/// a static mesh source with a skin stream on the end. The generated body has to carry the
/// whole chain or the base half of the object silently disappears.
[Serializable]
class InheritedRoot
{
	public int32 RootId;
	public String RootName = new .() ~ delete _;
}

[Serializable]
class InheritedMiddle : InheritedRoot
{
	public float MiddleWeight;
}

[Serializable]
class InheritedLeaf : InheritedMiddle
{
	public Float3 LeafPosition;
	public bool LeafEnabled;
}
