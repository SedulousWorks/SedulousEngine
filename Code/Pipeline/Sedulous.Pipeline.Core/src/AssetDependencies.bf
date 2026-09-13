using System;
using System.Collections;
using Sedulous.VFS;

namespace Sedulous.Pipeline.Core;

/// What one build consumes BEYOND the asset's own file name, which is implicit.
///
/// The driver hashes the files and chains the reads, so editing either re-cooks this product.
/// References only ORDER the cook: a product that merely points at another at runtime must not
/// re-cook every time that other one changes.
class AssetDependencies
{
	/// Extra source files read, mount relative.
	public List<SourcePath> Files = new .() ~ DeleteContainerAndItems!(_);

	/// Data streams of the SOURCE instance this build reads.
	///
	/// Declaring one chains its bytes, which matters because an embedded payload lives in a
	/// sidecar file that the envelope's own hash does not cover.
	public List<String> SourceStreams = new .() ~ DeleteContainerAndItems!(_);

	/// Instances whose CONTENT this build consumes, hash chained.
	public List<Guid> Reads = new .() ~ delete _;

	/// Instances the product refers to at runtime. Existence only.
	public List<Guid> References = new .() ~ delete _;

	/// Adds a file, taking a copy so the caller keeps its own.
	public void AddFile(StringView path) => Files.Add(new SourcePath(path));

	/// Adds a source stream name, taking a copy.
	public void AddSourceStream(StringView name) => SourceStreams.Add(new String(name));
}
