using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Geometry;

namespace Sedulous.Geometry.Pipeline;

/// Keeping a mesh's tiny envelope and its binary geometry sidecar in step.
///
/// The sidecar is stamped and checked exactly like an envelope, under the SOURCE type's own
/// version scope, so a sidecar written under a different layout is REFUSED rather than read as
/// nonsense.
static class MeshAssetStorage
{
	/// The stream the geometry travels in, beside the envelope.
	public const String cGeometryStreamName = "geometry";

	/// Writes the envelope and the sidecar together. The one writer every save path uses.
	public static Result<void, ErrorCode> WriteStatic(Instance instance, StaticMeshAsset asset)
	{
		if (instance.WriteObject(asset) case .Err(let envelopeError))
			return .Err(envelopeError);

		let bytes = scope List<uint8>();
		SourceToBytes(asset.Source, StaticMeshSource.TypeId, StaticMeshSource.DataVersion, bytes);
		return instance.WriteData(cGeometryStreamName, bytes);
	}

	public static Result<void, ErrorCode> WriteSkinned(Instance instance, SkinnedMeshAsset asset)
	{
		if (instance.WriteObject(asset) case .Err(let envelopeError))
			return .Err(envelopeError);

		let bytes = scope List<uint8>();
		SourceToBytes(asset.Source, SkinnedMeshSource.TypeId, SkinnedMeshSource.DataVersion, bytes);
		return instance.WriteData(cGeometryStreamName, bytes);
	}

	/// The sidecar's bytes on their own, for a caller that has to write the two halves
	/// SEPARATELY: an import defers both to a worker, and the envelope and the stream travel
	/// as two writes rather than one call.
	public static void StaticGeometryBytes(StaticMeshAsset asset, List<uint8> outBytes)
		=> SourceToBytes(asset.Source, StaticMeshSource.TypeId, StaticMeshSource.DataVersion,
			outBytes);

	public static void SkinnedGeometryBytes(SkinnedMeshAsset asset, List<uint8> outBytes)
		=> SourceToBytes(asset.Source, SkinnedMeshSource.TypeId, SkinnedMeshSource.DataVersion,
			outBytes);

	/// After reading the envelope: pulls the sidecar into the asset's source.
	///
	/// A MISSING sidecar is a broken asset rather than an empty one, and says so: the envelope
	/// never carries geometry, so there is nothing to fall back to.
	public static Result<void, ErrorCode> EnsureStaticLoaded(Instance instance,
		StaticMeshAsset asset)
		=> SourceFromStream(instance, asset.Source, StaticMeshSource.TypeId,
			StaticMeshSource.DataVersion);

	public static Result<void, ErrorCode> EnsureSkinnedLoaded(Instance instance,
		SkinnedMeshAsset asset)
		=> SourceFromStream(instance, asset.Source, SkinnedMeshSource.TypeId,
			SkinnedMeshSource.DataVersion);

	private static void SourceToBytes(ISerializable source, uint64 typeId, uint32 version,
		List<uint8> outBytes)
	{
		let buffer = scope MemoryStream();
		let serializer = scope BinarySerializer(buffer, .Write);
		BeginVersionedPayload(serializer, typeId, version);
		source.Serialize(serializer);
		EndVersionedPayload(serializer);

		let written = buffer.Bytes;
		outBytes.Clear();
		if (!written.IsEmpty)
			outBytes.AddRange(written);
	}

	private static Result<void, ErrorCode> SourceFromStream(Instance instance,
		ISerializable source, uint64 typeId, uint32 version)
	{
		let stream = instance.ReadData(cGeometryStreamName);
		if (stream == null)
			return .Err(.NotFound);
		defer delete stream;

		let serializer = scope BinarySerializer(stream, .Read);
		BeginVersionedPayload(serializer, typeId, version);
		source.Serialize(serializer);
		EndVersionedPayload(serializer);
		return serializer.IsPayloadOk ? .Ok : .Err(.InvalidArgument);
	}
}
