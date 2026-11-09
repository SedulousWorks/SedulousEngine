using System;
using System.Collections;
using Sedulous.Content;
using Sedulous.Core.IO;
using Sedulous.Core.Logging;
using Sedulous.Resource;

namespace Sedulous.Scene.Resource;

/// Loads a prefab: the PrefabDocument record's scene stream, read into a PrefabResource.
///
/// The record is AUTHORED, never cooked, so it declares it (ReadsAuthoredRecord): a host
/// layering its cooked database over its sources lets the sources answer for prefabs. A record of
/// any other type (a scene's) is refused, so a scene is never loaded through a reference.
///
/// A source prefab is text, which every spawn would parse again; given the host's SceneComposer
/// the factory turns it into the binary wire once, as it loads. Reading the stream runs on a
/// worker; the transcode, which builds a scene and its managers, on the main thread. A prefab
/// holding a component no installed manager reads (a plugin not loaded) stays text: binary is
/// written from what was understood, so the transcode would drop that component, where the text
/// keeps it for a scene that has the manager.
class PrefabFactory : IResourceFactory
{
	private SceneComposer mComposer;

	/// `composer` is BORROWED, from the host's services; null keeps every prefab as stored.
	public this(SceneComposer composer = null)
	{
		mComposer = composer;
	}

	/// The description the scene module declares: the composer when the host offers one, else
	/// none, so a headless host still loads prefabs.
	public static IResourceFactory FromServices(IResourceServices services)
	{
		return new PrefabFactory(services.Service(typeof(SceneComposer)) as SceneComposer);
	}

	public uint64 ProductTypeId => ResourceManager.ProductTypeIdOf<PrefabResource>();
	public Type CookedType => typeof(PrefabDocument);
	public bool ReadsAuthoredRecord => true;
	public bool SupportsAsync => true;

	public Object Create(ResourceManager manager, Instance instance) => ToBinary(Load(instance));

	public Object DecodeStage(Instance instance) => Load(instance);

	public Object FinalizeStage(ResourceManager manager, Object decoded) => ToBinary(decoded as PrefabResource);

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

	/// `prefab` in the binary wire, or as it is: already binary, no composer, a stream that does
	/// not read, or a component no manager understood. TAKES OWNERSHIP of `prefab`.
	private PrefabResource ToBinary(PrefabResource prefab)
	{
		if ((prefab == null) || (mComposer == null) || (prefab.Encoding == .Binary))
			return prefab;

		let scratch = scope Scene("__prefab_transcode");
		mComposer.Install(scratch);
		let bytes = new List<uint8>();
		let payload = prefab.OpenPayload();
		let read = SceneTranscode.ToBinary(payload, scratch, bytes, false);
		delete payload;
		if (read case .Err)
		{
			delete bytes;
			return prefab;
		}
		if (scratch.UnresolvedComponents.Length > 0)
		{
			GlobalLog(.Information, "PrefabFactory: prefab {} kept as text, {} of its components have no manager here",
				prefab.Id, scratch.UnresolvedComponents.Length);
			delete bytes;
			return prefab;
		}

		let binary = new PrefabResource(prefab.Id, prefab.Name, bytes);
		delete prefab;
		return binary;
	}
}
