using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;

namespace Sedulous.Navigation.Pipeline;

/// Keeping a zone's envelope and its baked navmesh in step.
///
/// The blob lives in a SIDECAR stream rather than inline: it is bulk, and the envelope can be
/// text. Every save path goes through here so the two never drift apart.
static class NavigationZoneStorage
{
	/// The stream the baked navmesh travels in, beside the envelope.
	public const String cNavMeshStreamName = "navmesh";

	/// Writes the envelope and the sidecar together.
	public static Result<void, ErrorCode> Write(Instance instance, NavigationZoneAsset asset)
	{
		if (instance.WriteObject(asset) case .Err(let error))
			return .Err(error);
		return instance.WriteData(cNavMeshStreamName, asset.NavMeshBlob);
	}

	/// Pulls the sidecar into the asset's blob, which is what has to follow a read of the
	/// envelope.
	///
	/// A MISSING stream is an UNBAKED zone rather than an error: the blob is left empty and the
	/// cook produces an invalid navmesh the subsystem skips.
	public static Result<void, ErrorCode> EnsureNavMeshLoaded(Instance instance,
		NavigationZoneAsset asset)
	{
		asset.NavMeshBlob.Clear();

		let stream = instance.ReadData(cNavMeshStreamName);
		if (stream == null)
			return .Ok; // unbaked, with no sidecar yet
		defer delete stream;

		let size = stream.Size();
		if (size <= 0)
			return .Ok;

		asset.NavMeshBlob.Count = (int)size;
		if (stream.Read(.(&asset.NavMeshBlob[0], (int)size)) != (int)size)
		{
			asset.NavMeshBlob.Clear();
			return .Err(.Internal); // a truncated sidecar
		}
		return .Ok;
	}
}
