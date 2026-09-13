using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Render;
using Sedulous.Scene;

namespace Sedulous.Engine.Navigation;

/// Drawing what a scene's navigation actually holds.
///
/// It reads the LIVE navmesh rather than anything the bake recorded, transformed by each zone
/// entity's frame, so the overlay shows exactly the surface agents path on at its current
/// placement.
static class NavigationDebugDraw
{
	private static Color cMeshColor = .(0.20f, 0.85f, 1.0f, 1.0f);
	private static Color cPathColor = .(1.0f, 0.85f, 0.20f, 1.0f);
	/// Orange outlines, for a bake's region contours.
	private static Color cContourColor = .(1.0f, 0.55f, 0.15f, 1.0f);
	private static Color cSpanColor = .(0.35f, 0.9f, 0.35f, 1.0f);

	private static String[?] cStates = .("invalid", "walking", "offmesh");
	private static String[?] cTargets = .("none", "requesting", "valid", "velocity", "failed");

	public static void Draw(Scene scene, NavigationSceneSettings settings, DebugDraw draw)
	{
		DrawMesh(scene, draw);

		if (settings.DebugDrawBakeStages)
			DrawBakeStages(scene, draw);

		if (settings.DebugDrawPaths)
			DrawPaths(scene, draw);
	}

	private static void DrawMesh(Scene scene, DebugDraw draw)
	{
		let zones = scene.GetSystem<NavMeshZoneComponentManager>();
		if (zones == null)
			return;

		let triangles = scope List<Float3>();
		zones.ForEach(scope [&] (zone, entity) =>
			{
				let product = zone.Zone.Get;
				if ((product == null) || !product.IsValid)
					return;

				// RIGID, matching the bake and the crowd's placement, so the overlay sits
				// where agents actually walk.
				let world = RigidPart(scene.GetWorldMatrix(entity));

				triangles.Clear();
				product.Mesh.DebugTriangles(triangles);

				for (int t = 0; (t + 2) < triangles.Count; t += 3)
				{
					let a = TransformPoint(triangles[t + 0], world);
					let b = TransformPoint(triangles[t + 1], world);
					let c = TransformPoint(triangles[t + 2], world);
					draw.DrawLine(a, b, cMeshColor);
					draw.DrawLine(b, c, cMeshColor);
					draw.DrawLine(c, a, cMeshColor);
				}
			});
	}

	private static void DrawBakeStages(Scene scene, DebugDraw draw)
	{
		let system = scene.GetSystem<NavigationSceneSystem>();
		if (system == null)
			return;

		let stages = system.BakeStages;
		if (stages.IsEmpty)
			return;

		// Placed by the zone entity's RIGID frame, which is the frame the bake captured in, so
		// the stages overlay the mesh exactly.
		let world = scene.IsValid(stages.ZoneEntity)
			? RigidPart(scene.GetWorldMatrix(stages.ZoneEntity))
			: Float4x4.Identity();

		for (int i = 0; (i + 1) < stages.ContourLines.Count; i += 2)
		{
			draw.DrawLine(TransformPoint(stages.ContourLines[i], world),
				TransformPoint(stages.ContourLines[i + 1], world), cContourColor);
		}

		// Span top ticks, strided down to a sane budget rather than one per sample.
		let stride = 1 + stages.WalkableSamples.Count / 20000;
		for (int i = 0; i < stages.WalkableSamples.Count; i += stride)
		{
			let point = TransformPoint(stages.WalkableSamples[i], world);
			draw.DrawLine(point, point + Float3(0, 0.15f, 0), cSpanColor);
		}
	}

	private static void DrawPaths(Scene scene, DebugDraw draw)
	{
		let agents = scene.GetSystem<NavAgentComponentManager>();
		if (agents == null)
			return;

		agents.ForEach(scope [&] (agent, entity) =>
			{
				let position = scene.GetWorldPosition(entity);
				if (agent.HasTarget)
					draw.DrawLine(position, agent.Target, cPathColor);

				if (agent.AgentId < 0)
					return;

				// The introspection overlay: the crowd's state, the request's stage and the
				// live speed intent, floating above the agent. That is the "why is it not
				// moving" answer at a glance.
				let stateIndex = (int)agent.CrowdState;
				let targetIndex = (int)agent.CrowdTargetState;
				let state = (stateIndex < cStates.Count) ? cStates[stateIndex] : cStates[0];
				let target = (targetIndex < cTargets.Count) ? cTargets[targetIndex] : cTargets[0];

				let label = scope String();
				label.AppendF("{} [{}] {:0.0}u/s", state, target, agent.CrowdDesiredSpeed);

				// A failed request reads red at a glance.
				let color = (agent.CrowdTargetState == .Failed)
					? Color(1.0f, 0.35f, 0.30f, 1.0f) : cPathColor;

				draw.DrawText3D(position + Float3(0, agent.Height + 0.3f, 0), label, color);
			});
	}
}
