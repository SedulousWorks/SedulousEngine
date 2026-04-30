namespace Sedulous.Audio;

using System;
using System.Collections;
using Sedulous.Audio.Graph;

/// Manages the bus hierarchy. Accessed via IAudioSystem.BusSystem.
interface IAudioBusSystem
{
	/// The master bus (root of the hierarchy). Always exists.
	IAudioBus Master { get; }

	/// Gets a bus by name. Returns null if not found.
	IAudioBus GetBus(StringView name);

	/// Creates a child bus under the specified parent.
	/// If parent is null, routes to Master.
	IAudioBus CreateBus(StringView name, IAudioBus parent = null);

	/// Destroys a bus. Sources routed to it are re-routed to its parent.
	/// Cannot destroy the Master bus.
	void DestroyBus(IAudioBus bus);

	/// Gets all bus names for enumeration/debugging.
	void GetBusNames(List<StringView> outNames);

	/// The underlying audio graph (advanced access).
	AudioGraph Graph { get; }
}
