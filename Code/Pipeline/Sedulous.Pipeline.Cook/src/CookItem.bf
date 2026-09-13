using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core.Serialization;
using Sedulous.Pipeline.Core;

namespace Sedulous.Pipeline.Cook;

/// One asset the plan says needs cooking.
class CookItem
{
	public Guid Source = .Empty;

	/// The source instance's path, for the progress line and for placing the product.
	public String Path = new .() ~ delete _;

	/// BORROWED from the registry.
	public IAssetBuilder Builder = null;

	/// OWNED: the deserialised source object, kept for the build and RELEASED as soon as it
	/// finishes. Holding every item's object until the whole cook ended runs a large scene out
	/// of memory, mesh blobs and texture tables and all.
	public ISerializable AssetObject = null ~ delete _;

	public uint64 RecipeHash = 0;
	public AssetDependencies Deps = new .() ~ delete _;

	/// The dependency depth. Items cook level by level, in parallel within a level.
	public int32 Level = 0;

	/// BORROWED, and pre-created SERIALLY before any worker runs.
	public Instance Product = null;
	/// BORROWED, snapshotted at the same time for the same reason.
	public Instance SourceInstance = null;

	/// True when an invariant product was carried over from the host database rather than
	/// cooked again.
	public bool CopiedForward = false;
}
