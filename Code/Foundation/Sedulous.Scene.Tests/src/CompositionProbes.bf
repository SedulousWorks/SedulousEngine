using System;
using System.Collections;

namespace Sedulous.Scene.Tests;

/// Shared state the composition probes write into.
///
/// A module's install and reflection hooks are FUNCTION POINTERS, which carry no capture,
/// so a file local counter and an order string are the only way to observe them. That is
/// the same constraint Raptor's tests work under, for the same reason.
static class CompositionProbes
{
	public static String InstallOrder = new .() ~ delete _;
	public static String ObserverOrder = new .() ~ delete _;
	public static int Reflections = 0;

	public static void Reset()
	{
		InstallOrder.Clear();
		ObserverOrder.Clear();
		Reflections = 0;
	}

	public static void InstallA(Scene scene) => InstallOrder.Append("a");
	public static void InstallB(Scene scene) => InstallOrder.Append("b");
	public static void ReflectA() { Reflections++; }
	public static void ReflectB() { Reflections++; }

	public static void InstallContribution(Scene scene) => scene.AddSystem<ContributedSystem>();
}
