using System;
using System.Collections;
using Sedulous.Runtime;
using Sedulous.Pipeline.Core;

namespace Sedulous.Pipeline.Importer;

/// The host's pipeline registries a plugin's Pipeline part adds to; one a host lacks (the cook's
/// importers) is null. BORROWED, all three.
struct PipelineRegistries
{
	public BuilderRegistry Builders;
	public ImporterRegistry Importers;
	public AssetCreatorRegistry Creators;

	public this(BuilderRegistry builders, ImporterRegistry importers, AssetCreatorRegistry creators)
	{
		Builders = builders;
		Importers = importers;
		Creators = creators;
	}
}

/// What a Pipeline part adds, through the service its host provides
/// (PluginContext.Find<PipelinePluginServices>): asset builders, file importers and asset
/// creators, into the host's registries. The service records what each plugin added, so the
/// plugin host's unload takes it out again, in reverse. A part registers its asset and product
/// types itself, which the loader records on its own.
class PipelinePluginServices : IRegistrationRecorder
{
	private enum Kind : uint8
	{
		case Builder;
		case Importer;
		case Creator;
	}

	private struct Entry
	{
		/// This service's, what the recording keeps.
		public uint64 Token;
		public Kind Kind;
		/// The registry's.
		public uint64 Key;
	}

	private PipelineRegistries mRegistries;
	private List<Entry> mEntries = new .() ~ delete _;
	/// The armed part's sink. BORROWED, the loader's; null while none loads.
	private List<uint64> mSink = null;
	private uint64 mNextToken = 1;

	public this(PipelineRegistries registries)
	{
		mRegistries = registries;
	}

	/// Hands this service to `host`'s plugins and records what they add through it. Before the
	/// host enables any; this outlives the host.
	public bool Attach(PluginHost host)
	{
		if (!host.Provide(this))
			return false;
		host.Loader.AddRecorder(this);
		return true;
	}

	/// The registries this host has (null where it has none).
	public PipelineRegistries Registries => mRegistries;

	/// Adds a builder to the host's, which takes it; false (it is deleted, nothing added) where the
	/// host cooks nothing.
	public bool AddBuilder(IAssetBuilder builder)
	{
		if (mRegistries.Builders == null)
		{
			delete builder;
			return false;
		}
		return Record(.Builder, mRegistries.Builders.Register(builder));
	}

	/// Adds an importer to the host's, which takes it; false (it is deleted, nothing added) where
	/// the host imports nothing.
	public bool AddImporter(IFileImporter importer)
	{
		if (mRegistries.Importers == null)
		{
			delete importer;
			return false;
		}
		return Record(.Importer, mRegistries.Importers.Register(importer));
	}

	/// Adds a creator to the host's, which takes it; false (it is deleted, nothing added) where the
	/// host creates nothing.
	public bool AddCreator(AssetCreator creator)
	{
		if (mRegistries.Creators == null)
		{
			delete creator;
			return false;
		}
		return Record(.Creator, mRegistries.Creators.Register(creator));
	}

	/// Armed around each part's load, so what it added is recorded against it.
	public override void Arm(List<uint64> sink) => mSink = sink;
	public override void Disarm() => mSink = null;

	public override void Reverse(uint64 id)
	{
		for (int i < mEntries.Count)
		{
			if (mEntries[i].Token != id)
				continue;
			let entry = mEntries[i];
			mEntries.RemoveAt(i);
			switch (entry.Kind)
			{
			case .Builder: mRegistries.Builders.Unregister(entry.Key);
			case .Importer: mRegistries.Importers.Unregister(entry.Key);
			case .Creator: mRegistries.Creators.Unregister(entry.Key);
			}
			return;
		}
	}

	private bool Record(Kind kind, uint64 key)
	{
		if (key == 0)
			return false;
		var entry = Entry();
		entry.Token = mNextToken++;
		entry.Kind = kind;
		entry.Key = key;
		mEntries.Add(entry);
		if (mSink != null)
			mSink.Add(entry.Token);
		return true;
	}
}
