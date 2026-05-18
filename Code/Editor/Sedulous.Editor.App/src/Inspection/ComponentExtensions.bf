
using System;

/// Comptime extensions that generate IInspectable implementations
/// for engine components. Each extension fires [OnCompile(.TypeInit)]
/// to scan [Property] fields and emit DescribeProperties.
///
/// Render components are in this namespace; other engine modules
/// have their extensions below in separate namespace blocks.

namespace Sedulous.Engine.Render
{
	extension LightComponent
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension CameraComponent
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension MeshComponent
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension SkinnedMeshComponent
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension SpriteComponent
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension DecalComponent
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension ParticleComponent
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}
	extension RenderSceneModule
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}
}
// ==================== Animation Components ====================

namespace Sedulous.Engine.Animation
{
	extension SkeletalAnimationComponent
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension AnimationGraphComponent
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension PropertyAnimationComponent
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}
}

// ==================== Audio Components ====================

namespace Sedulous.Engine.Audio
{
	extension AudioSourceComponent
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension AudioListenerComponent
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}
}
// ==================== Physics Components ====================

namespace Sedulous.Engine.Physics
{
	extension RigidBodyComponent
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}
}
// ==================== Navigation Components ====================

namespace Sedulous.Engine.Navigation
{
	extension NavAgentComponent
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension NavObstacleComponent
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.App.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}
}
