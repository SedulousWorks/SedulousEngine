using System;
using System.Collections;
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

/// Lists of values, which is how a cooked mesh stores its blobs and its parallel submesh
/// tables. A List is a reference type, so the generated body has to reach for the counted
/// array path rather than the object one.
[Serializable]
class ListSample
{
	public int32 Head;
	public List<uint8> Blob = new .() ~ delete _;
	public List<int32> Counts = new .() ~ delete _;
	public List<float> Weights = new .() ~ delete _;
	public List<Float3> Points = new .() ~ delete _;
	public String Tail = new .() ~ delete _;
}
