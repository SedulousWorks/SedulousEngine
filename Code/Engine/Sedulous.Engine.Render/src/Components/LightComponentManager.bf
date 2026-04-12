namespace Sedulous.Engine.Render;

using System;
using Sedulous.Scenes;
using Sedulous.Renderer;
using Sedulous.Renderer.Debug;
using Sedulous.Core.Mathematics;

/// Manages light components and extracts light data for the renderer.
/// Injected into scenes by RenderSubsystem via ISceneAware.
class LightComponentManager : ComponentManager<LightComponent>, IRenderDataProvider
{
	/// Shared renderer context (set by RenderSubsystem). Used for debug drawing.
	public RenderContext RenderContext { get; set; }

	/// Whether to draw wire-shape debug visuals for each light every frame.
	public bool DebugDrawEnabled = true;

	public override StringView SerializationTypeId => "Sedulous.LightComponent";

	protected override void OnRegisterUpdateFunctions()
	{
		RegisterUpdate(.PostUpdate, new => PostUpdate);
	}

	private void PostUpdate(float deltaTime)
	{
		if (DebugDrawEnabled)
			EmitDebugDraws();
	}

	/// Extracts LightRenderData for all active light components.
	public void ExtractRenderData(in RenderExtractionContext context)
	{
		let scene = Scene;
		if (scene == null)
			return;

		let frameAlloc = context.RenderContext.FrameAllocator;

		for (let light in ActiveComponents)
		{
			if (!light.IsActive)
				continue;

			if (context.LayerMask != 0xFFFFFFFF && (light.LayerMask & context.LayerMask) == 0)
				continue;

			let worldMatrix = scene.GetWorldMatrix(light.Owner);
			let position = worldMatrix.Translation;

			// Direction: forward vector is -Z in XNA convention.
			// M31/M32/M33 is the +Z axis (backward), negate for forward.
			let direction = -Vector3.Normalize(.(worldMatrix.M31, worldMatrix.M32, worldMatrix.M33));

			let data = new:frameAlloc LightRenderData();
			data.Position = position;
			data.Bounds = .(.Zero, .Zero); // TODO: compute from range
			data.Flags = .None;
			data.Type = light.Type;
			data.Color = light.Color;
			data.Intensity = light.Intensity;
			data.Direction = direction;
			data.Range = light.Range;
			data.InnerConeAngle = Math.DegreesToRadians(light.InnerConeAngle);
			data.OuterConeAngle = Math.DegreesToRadians(light.OuterConeAngle);
			data.CastsShadows = light.CastsShadows;
			data.ShadowBias = light.ShadowBias;
			data.ShadowNormalBias = light.ShadowNormalBias;
			context.RenderData.Add(RenderCategories.Light, data);
		}
	}

	// ==================== Debug Drawing ====================

	private void EmitDebugDraws()
	{
		let scene = Scene;
		if (scene == null) return;
		if (RenderContext == null) return;
		let dbg = RenderContext.DebugDraw;
		if (dbg == null) return;

		for (let light in ActiveComponents)
		{
			if (!light.IsActive) continue;

			let worldMatrix = scene.GetWorldMatrix(light.Owner);
			let position = worldMatrix.Translation;
			let forward = -Vector3.Normalize(.(worldMatrix.M31, worldMatrix.M32, worldMatrix.M33));

			// Build a visible color for the debug shape from the light's RGB
			// components (clamped to [0, 1]).
			let lineColor = Color(
				Math.Clamp(light.Color.X, 0.0f, 1.0f),
				Math.Clamp(light.Color.Y, 0.0f, 1.0f),
				Math.Clamp(light.Color.Z, 0.0f, 1.0f));

			switch (light.Type)
			{
			case .Directional:
				DrawDirectionalGizmo(dbg, position, forward, lineColor);
			case .Point:
				DrawPointGizmo(dbg, position, light.Range, lineColor);
			case .Spot:
				DrawSpotGizmo(dbg, position, forward, light.Range,
					Math.DegreesToRadians(light.OuterConeAngle), lineColor);
			}
		}
	}

	private static void DrawDirectionalGizmo(DebugDraw dbg, Vector3 position, Vector3 forward, Color color)
	{
		// Compact "sun" icon: short axis cross + direction arrow.
		let r = 0.3f;
		dbg.DrawLine(position - Vector3(r, 0, 0), position + Vector3(r, 0, 0), color);
		dbg.DrawLine(position - Vector3(0, r, 0), position + Vector3(0, r, 0), color);
		dbg.DrawLine(position - Vector3(0, 0, r), position + Vector3(0, 0, r), color);
		// Direction arrow.
		let tip = position + forward * 1.5f;
		dbg.DrawLine(position, tip, color);
		DrawArrowHead(dbg, tip, forward, 0.2f, color);
	}

	private static void DrawPointGizmo(DebugDraw dbg, Vector3 position, float range, Color color)
	{
		// Wire sphere showing the light's range.
		dbg.DrawWireSphere(position, range, color, 24);
		// Small cross at the center for visibility when the sphere is large.
		let r = 0.15f;
		dbg.DrawLine(position - Vector3(r, 0, 0), position + Vector3(r, 0, 0), color);
		dbg.DrawLine(position - Vector3(0, r, 0), position + Vector3(0, r, 0), color);
		dbg.DrawLine(position - Vector3(0, 0, r), position + Vector3(0, 0, r), color);
	}

	private static void DrawSpotGizmo(DebugDraw dbg, Vector3 position, Vector3 forward, float range, float outerCone, Color color)
	{
		// Cone: circle at the far end + 4 lines from origin to circle.
		let tipDist = Math.Max(range, 0.1f);
		let tipCenter = position + forward * tipDist;
		let tipRadius = tipDist * Math.Tan(outerCone);

		// Pick two orthogonal axes in the plane perpendicular to forward.
		let up = (Math.Abs(forward.Y) < 0.99f) ? Vector3.Up : Vector3.Forward;
		let right = Vector3.Normalize(Vector3.Cross(forward, up));
		let trueUp = Vector3.Cross(right, forward);

		// Circle at tip.
		dbg.DrawCircle(tipCenter, right, trueUp, tipRadius, color, 24);

		// Four rays from apex to circle.
		dbg.DrawLine(position, tipCenter + right * tipRadius, color);
		dbg.DrawLine(position, tipCenter - right * tipRadius, color);
		dbg.DrawLine(position, tipCenter + trueUp * tipRadius, color);
		dbg.DrawLine(position, tipCenter - trueUp * tipRadius, color);
	}

	/// Draws a simple 4-line pyramid arrowhead at the tip of a direction vector.
	private static void DrawArrowHead(DebugDraw dbg, Vector3 tip, Vector3 forward, float size, Color color)
	{
		let up = (Math.Abs(forward.Y) < 0.99f) ? Vector3.Up : Vector3.Forward;
		let right = Vector3.Normalize(Vector3.Cross(forward, up));
		let trueUp = Vector3.Cross(right, forward);
		let @base = tip - forward * size;
		dbg.DrawLine(tip, @base + right * size * 0.5f, color);
		dbg.DrawLine(tip, @base - right * size * 0.5f, color);
		dbg.DrawLine(tip, @base + trueUp * size * 0.5f, color);
		dbg.DrawLine(tip, @base - trueUp * size * 0.5f, color);
	}
}
