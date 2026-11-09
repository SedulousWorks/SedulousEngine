using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core.IO;
using Sedulous.Resource;

namespace Sedulous.Scene.Resource;

/// Loads a prefab: the PrefabDocument record's scene stream, read into a PrefabResource.
///
/// The record is AUTHORED, never cooked, so it declares it (ReadsAuthoredRecord): a host
/// layering its cooked database over its sources lets the sources answer for prefabs. A record of
/// any other type (a scene's) is refused, so a scene is never loaded through a reference.
///
/// The load is all reading, which touches nothing shared, so it runs on a worker whole.
class PrefabFactory : IResourceFactory
{
	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<PrefabResource>();
	public Type CookedType => typeof(PrefabDocument);
	public bool ReadsAuthoredRecord => true;
	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => Load(instance);

	public Object DecodeStage(Instance instance) => Load(instance);

	public Object FinalizeStage(ResourceManager manager, Object decoded) => decoded;

	/// Null when the record is not a prefab document or has no readable scene stream.
	private static PrefabResource Load(Instance instance)
	{
		if (instance.TypeName != typeof(PrefabDocument).GetFullName(.. scope String()))
			return null;

		let stream = instance.ReadData(SceneStorage.cStreamName);
		if (stream == null)
			return null;
		defer delete stream;

		let size = stream.Size();
		if (size <= 0)
			return null;
		let bytes = new List<uint8>();
		bytes.Resize((int)size);
		if (stream.Read(bytes) != (int)size)
		{
			delete bytes;
			return null;
		}
		return new PrefabResource(instance.Id, instance.Name, bytes);
	}
}
