
using System;

/// Comptime extensions that generate IInspectable implementations
/// for particle authoring types: emitter, system, and every concrete
/// initializer / behavior shipped with Sedulous.Particles. Mirrors the
/// pattern used by ComponentExtensions for engine components.
///
/// Each extension fires [OnCompile(.TypeInit)] to scan [Property] fields
/// and emit DescribeProperties via InspectorCodegen.

namespace Sedulous.Particles
{
	// ==================== Authoring container types ====================

	extension ParticleEmitter
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension ParticleSystem
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	// ==================== Initializers ====================

	extension PositionInitializer
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension VelocityInitializer
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension LifetimeInitializer
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension ColorInitializer
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension SizeInitializer
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension RotationInitializer
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	// ==================== Behaviors ====================

	extension DragBehavior
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension GravityBehavior
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension WindBehavior
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension AttractorBehavior
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension RadialForceBehavior
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension TurbulenceBehavior
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension VortexBehavior
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension VelocityIntegrationBehavior
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension AlphaOverLifetimeBehavior
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension ColorOverLifetimeBehavior
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension SizeOverLifetimeBehavior
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension SpeedOverLifetimeBehavior
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension RotationOverLifetimeBehavior
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}
}
