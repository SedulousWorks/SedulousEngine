using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Navigation;
using static Sedulous.Navigation.Tests.NavigationFixture;

namespace Sedulous.Navigation.Tests;

/// The crowd: agents that steer to their targets and avoid one another.
class NavigationCrowdTests
{
	/// Two agents crossing HEAD ON both arrive, and neither passes through the other. That is
	/// the whole point of a crowd rather than two independent path followers.
	[Test]
	public static void TwoAgentsCrossHeadOnAndBothArrive()
	{
		let blob = scope List<uint8>();
		Test.Assert(BakeGround(blob, 10.0f) case .Ok, "an open field, nothing in the way");

		let mesh = scope NavigationMesh();
		Test.Assert(mesh.Load(blob) case .Ok);

		let crowd = scope NavigationCrowd(mesh, 4, 0.6f);
		Test.Assert(crowd.IsValid);

		let parameters = NavigationAgentParams();
		let a = crowd.AddAgent(.(-5, 0, 0), parameters);
		let b = crowd.AddAgent(.(5, 0, 0), parameters);
		Test.Assert(a >= 0);
		Test.Assert(b >= 0);
		Test.Assert(crowd.IsAgentValid(a));
		Test.Assert(crowd.IsAgentValid(b));

		let targetA = Float3(5, 0, 0);
		let targetB = Float3(-5, 0, 0);
		Test.Assert(crowd.SetTarget(a, targetA));
		Test.Assert(crowd.SetTarget(b, targetB));

		// Twelve seconds at thirty hertz, tracking how close they ever came.
		var minSeparation = float.MaxValue;
		for (int step < 360)
		{
			crowd.Update(1.0f / 30.0f);
			let pa = crowd.AgentPosition(a);
			let pb = crowd.AgentPosition(b);
			Test.Assert(Finite(pa));
			Test.Assert(Finite(pb));
			minSeparation = Min(minSeparation, DistXZ(pa, pb));
		}

		Test.Assert(DistXZ(crowd.AgentPosition(a), targetA) < 1.5f);
		Test.Assert(DistXZ(crowd.AgentPosition(b), targetB) < 1.5f);
		// Their radii sum to a little over one; this allows for steering slack.
		Test.Assert(minSeparation > 0.5f, "they went round each other, not through");
	}

	/// The agent's own state is the debugging window into why it is or is not moving.
	[Test]
	public static void AnAgentReportsItsState()
	{
		let blob = scope List<uint8>();
		Test.Assert(BakeGround(blob, 10.0f) case .Ok);

		let mesh = scope NavigationMesh();
		Test.Assert(mesh.Load(blob) case .Ok);
		let crowd = scope NavigationCrowd(mesh, 4, 0.6f);

		let agent = crowd.AddAgent(.(-5, 0, 0), .());
		Test.Assert(agent >= 0);

		let idle = crowd.AgentState(agent);
		Test.Assert(idle.Valid);
		Test.Assert(idle.State == .Walking, "on the mesh, with nowhere to be");
		Test.Assert(idle.TargetState == .None);

		Test.Assert(crowd.SetTarget(agent, .(5, 0, 0)));
		for (int step < 30)
			crowd.Update(1.0f / 30.0f);

		let moving = crowd.AgentState(agent);
		Test.Assert(moving.Valid);
		Test.Assert(moving.TargetState == .Valid, "the corridor resolved");
		Test.Assert(moving.DesiredSpeed > 0.0f, "it intends to move");
		Test.Assert(moving.CornerCount > 0, "there is path left ahead of it");

		// Cleared, it stops wanting to be anywhere.
		crowd.ClearTarget(agent);
		crowd.Update(1.0f / 30.0f);
		Test.Assert(crowd.AgentState(agent).TargetState == .None);

		// Removed, it reports nothing rather than stale values.
		crowd.RemoveAgent(agent);
		Test.Assert(!crowd.IsAgentValid(agent));
		let gone = crowd.AgentState(agent);
		Test.Assert(!gone.Valid);
		Test.Assert(gone.State == .Invalid);
		Test.Assert(crowd.AgentPosition(agent) == Float3(0, 0, 0));
	}

	/// A live agent's profile changes WITHOUT removing and re-adding it, which is how a speed
	/// changes mid stride.
	[Test]
	public static void ALiveAgentsProfileChangesInPlace()
	{
		let blob = scope List<uint8>();
		Test.Assert(BakeGround(blob, 10.0f) case .Ok);

		let mesh = scope NavigationMesh();
		Test.Assert(mesh.Load(blob) case .Ok);
		let crowd = scope NavigationCrowd(mesh, 4, 0.6f);

		var parameters = NavigationAgentParams();
		let agent = crowd.AddAgent(.(-8, 0, 0), parameters);
		Test.Assert(agent >= 0);
		Test.Assert(crowd.SetTarget(agent, .(8, 0, 0)));

		for (int step < 60)
			crowd.Update(1.0f / 30.0f);
		let fastPosition = crowd.AgentPosition(agent).X;

		// A tenth of the speed: the next two seconds cover far less ground than the last.
		parameters.MaxSpeed = 0.35f;
		crowd.SetAgentParams(agent, parameters);
		for (int step < 60)
			crowd.Update(1.0f / 30.0f);
		let slowAdvance = crowd.AgentPosition(agent).X - fastPosition;

		Test.Assert(slowAdvance < (fastPosition - (-8.0f)) * 0.5f, "it slowed down");

		// A stale id is a no-op rather than a crash.
		crowd.SetAgentParams(999, parameters);
		crowd.ClearTarget(999);
		crowd.RemoveAgent(999);
	}
}
