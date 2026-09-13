using System;
using Sedulous.Content;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Particles;
using Sedulous.Particles.Resource;
using Sedulous.Resource;
using Sedulous.VFS;

namespace Sedulous.Engine.Particles.Tests;

/// A scratch mount, a database and the effect factory: the real cook and resolve stack, so a
/// component's reference is measured against the product the runtime would load.
class ParticleResourceFixture
{
	private const String cEffectTypeName = "Sedulous.Particles.Resource.ParticleEffectResource";

	public NativeFileSystem Mount ~ delete _;
	public SerializerFactory Serializers ~ delete _;
	public SerializableRegistry Serializables = new .() ~ delete _;
	public ContentDatabase Database ~ delete _;
	public ResourceManager Manager ~ delete _;
	public ParticleEffectFactory Effects = new .() ~ delete _;

	private String mRoot = new .() ~ delete _;

	public this(StringView root)
	{
		mRoot.Set(root);
		RemoveDirectoryRecursive(mRoot);
		CreateDirectory(mRoot);

		ParticleResources.RegisterAll(Serializables);

		Mount = new NativeFileSystem(mRoot);
		Serializers = new (stream, mode) => new BinarySerializerContext(stream, mode);
		Database = new ContentDatabase(Mount, Serializers, "asset", Serializables);
		Manager = new ResourceManager(Database, null);

		Manager.AddFactory(Effects);
	}

	public ~this()
	{
		RemoveDirectoryRecursive(mRoot);
	}

	/// Cooks an effect carrying one system of the given size.
	public Guid CookEffect(StringView name, int32 maxParticles, bool emitting = true)
	{
		let record = scope ParticleEffectResource();
		let system = record.Effect.AddSystem(maxParticles);
		system.Emitter.IsEmitting = emitting;

		let instance = Database.RootGroup.CreateInstance(name, cEffectTypeName);
		instance.WriteObject(record).IgnoreError();
		return instance.Id;
	}
}
