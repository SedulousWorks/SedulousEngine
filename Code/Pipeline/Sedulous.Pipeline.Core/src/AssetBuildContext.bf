using System;
using Sedulous.Content;
using Sedulous.Core.Serialization;
using Sedulous.VFS;

namespace Sedulous.Pipeline.Core;

/// What a builder cooks against: where its source bytes come from, where its product goes, and
/// what it may read on the way.
///
/// Everything here is BORROWED and lives as long as the cook. The driver or the editor's cook
/// service owns all of it.
class AssetBuildContext
{
	/// The mount the asset's file name, and any extra file it declares, resolve against. FILE
	/// ACCESS GOES THROUGH HERE, never a raw path, so a cook running under a pak or a remote
	/// mount behaves the same as one running on a working tree.
	public IFileSystem Sources = null;

	/// The SOURCE instance being cooked, which is where an embedded data stream lives.
	public Instance Source = null;

	/// Where the cooked resource is written.
	public Instance Output = null;

	/// The COOKED products view, for resolving a reference another product already provides.
	public IContentDatabase Database = null;

	/// The SOURCE database, holding asset envelopes and their raw sidecars.
	///
	/// Distinct from Database on purpose: at cook time that one is the cooked view, so a
	/// builder needing another asset's SOURCE form, its envelope's file name or its embedded
	/// pixels, has to come through here. Casting a cooked product back to its authoring
	/// envelope does not work, which is the lesson the terrain palette cook paid for.
	public IContentDatabase SourceDatabase = null;

	/// How to make a serializer, for a builder that has to round trip data through one.
	///
	/// Not in Raptor's version, which deep copies with a copy constructor. Beef has none, so a
	/// faithful clone of a polymorphic graph goes out through a serializer and back, and the
	/// factory is the driver's to choose.
	public SerializerFactory Serializers = null;

	/// The target being produced for, which a variant builder reads its encoder profile from.
	public CookTarget Target = .Host;
}
