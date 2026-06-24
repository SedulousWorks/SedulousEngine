
using System;

/// Comptime extensions that generate IInspectable implementations
/// for animation graph authoring types: ClipStateNode, BlendTree1DEntry,
/// BlendTree2DEntry. Enables the animation graph editor's property grid
/// to show resource ref pickers via the standard inspection pipeline.

namespace Sedulous.Animation
{
	extension ClipStateNode
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension BlendTree1DEntry
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}

	extension BlendTree2DEntry
	{
		[OnCompile(.TypeInit), Comptime]
		static void GenerateInspector()
		{
			Sedulous.Editor.InspectorCodegen.GenerateDescribeProperties(typeof(Self));
		}
	}
}
