namespace Sedulous.Engine.Render;

using System;

/// Comptime extensions that generate IInspectable implementations
/// for engine render components. Each extension fires [OnCompile(.TypeInit)]
/// to scan [Property] fields and emit DescribeProperties.

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
