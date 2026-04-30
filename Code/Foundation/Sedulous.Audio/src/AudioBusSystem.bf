namespace Sedulous.Audio;

using System;
using System.Collections;
using Sedulous.Audio.Graph;

/// Manages the bus hierarchy. Buses own their own graph nodes.
/// The graph only owns the OutputNode. Connections between bus nodes
/// and the OutputNode form the graph structure.
class AudioBusSystem : IAudioBusSystem
{
	private AudioGraph mGraph;
	private Dictionary<String, AudioBus> mBuses = new .() ~ delete _;
	private AudioBus mMaster;

	public IAudioBus Master => mMaster;
	public AudioGraph Graph => mGraph;

	/// Creates the bus system with a Master bus connected to the graph's output.
	/// Also creates default SFX and Music child buses.
	public this(AudioGraph graph)
	{
		mGraph = graph;

		// Create Master bus and connect to graph output
		mMaster = new AudioBus("Master");
		graph.Output.AddInput(mMaster.OutputNode);
		mBuses[new String("Master")] = mMaster;

		// Create default child buses
		CreateBus("SFX");
		CreateBus("Music");
	}

	public ~this()
	{
		// First pass: disconnect all buses from their parents
		for (let kv in mBuses)
			kv.value.SetParent(null);

		// Disconnect master from graph output
		if (mMaster != null)
			mGraph.Output.RemoveInput(mMaster.OutputNode);

		// Second pass: delete everything
		for (let kv in mBuses)
		{
			delete kv.key;
			delete kv.value;
		}
		mBuses.Clear();
		mMaster = null;
	}

	public IAudioBus GetBus(StringView name)
	{
		for (let kv in mBuses)
		{
			if (StringView(kv.key) == name)
				return kv.value;
		}
		return null;
	}

	public IAudioBus CreateBus(StringView name, IAudioBus parent = null)
	{
		for (let kv in mBuses)
		{
			if (StringView(kv.key) == name)
				return kv.value;
		}

		let bus = new AudioBus(name);

		let parentBus = (parent != null) ? (AudioBus)parent : mMaster;
		bus.SetParent(parentBus);

		mBuses[new String(name)] = bus;
		return bus;
	}

	public void DestroyBus(IAudioBus busInterface)
	{
		if (busInterface == null || busInterface == mMaster)
			return;

		let bus = busInterface as AudioBus;
		if (bus == null)
			return;

		let parent = bus.Parent as AudioBus;
		bus.ReparentChildrenTo(parent ?? mMaster);
		bus.SetParent(null);

		String keyToDelete = null;
		for (let kv in mBuses)
		{
			if (kv.value == bus)
			{
				keyToDelete = kv.key;
				break;
			}
		}

		if (keyToDelete != null)
		{
			mBuses.Remove(keyToDelete);
			delete keyToDelete;
		}

		delete bus;
	}

	public void GetBusNames(List<StringView> outNames)
	{
		for (let kv in mBuses)
			outNames.Add(kv.key);
	}

	/// Gets a bus as AudioBus (internal typed access).
	public AudioBus GetBusInternal(StringView name)
	{
		for (let kv in mBuses)
		{
			if (StringView(kv.key) == name)
				return kv.value;
		}
		return null;
	}
}
