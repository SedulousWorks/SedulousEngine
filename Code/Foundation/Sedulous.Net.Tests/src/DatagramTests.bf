using System;
using System.Collections;
using Sedulous.Net;

namespace Sedulous.Net.Tests;

/// The in memory unreliable datagram sim.
class DatagramTests
{
	[Test]
	public static void ADatagramArrivesAfterItsLatencyCarryingTheSender()
	{
		var sim = SimConditions();
		sim.LatencyMs = 25.0f;
		let network = scope SimDatagramNetwork(sim);
		let a = network.CreateSocket();
		let b = network.CreateSocket();

		let message = scope uint8[](0x11, 0x22, 0x33);
		a.Send(b.LocalEndpoint, message);

		let got = scope List<uint8>();
		network.Advance(10.0f);
		Test.Assert(!b.Receive(let tooEarly, got));

		network.Advance(20.0f);
		Test.Assert(b.Receive(let from, got));
		Test.Assert(from == a.LocalEndpoint);
		Test.Assert(got.Count == 3);
		Test.Assert(got[0] == 0x11);
	}

	[Test]
	public static void LossDropsDatagramsAndIsReproducible()
	{
		var sim = SimConditions();
		sim.LossPct = 0.5f;
		sim.Seed = 999;

		let first = CountDelivered(sim);
		Test.Assert(first > 0);
		Test.Assert(first < 100);

		// The same seed gives the same outcome, which is the whole point of the sim.
		Test.Assert(CountDelivered(sim) == first);
	}

	private static int CountDelivered(SimConditions sim)
	{
		let network = scope SimDatagramNetwork(sim);
		let a = network.CreateSocket();
		let b = network.CreateSocket();

		for (int i = 0; i < 100; i++)
		{
			let message = scope uint8[]((uint8)i);
			a.Send(b.LocalEndpoint, message);
		}
		network.Advance(1.0f);

		var received = 0;
		let got = scope List<uint8>();
		while (b.Receive(let from, got))
			received++;
		return received;
	}

	[Test]
	public static void SocketsGetDistinctEndpoints()
	{
		let network = scope SimDatagramNetwork();
		let a = network.CreateSocket();
		let b = network.CreateSocket();
		let c = network.CreateSocket();

		Test.Assert(a.LocalEndpoint != b.LocalEndpoint);
		Test.Assert(b.LocalEndpoint != c.LocalEndpoint);
		Test.Assert(a.LocalEndpoint.IsValid);
	}
}
