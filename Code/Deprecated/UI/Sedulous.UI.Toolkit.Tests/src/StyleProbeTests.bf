using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.UI.Toolkit;

namespace Sedulous.UI.Toolkit.Tests;

/// A REGRESSION GATE on the "property-field" style class reaching the numeric fields INSIDE
/// every toolkit editor and vector input.
///
/// The editor sizes an inspector's fields through that class. A field built without it silently
/// keeps the theme's default size, which is how the labels once shrank while the numbers beside
/// them did not.
class StyleProbeTests
{
	private static void WalkFields(View view, ref int32 count)
	{
		if (let field = view as NumericField)
		{
			count++;
			Test.Assert(field.HasClass("property-field"), "a field with no property-field class");
			Test.Assert(field.ResolveStyleFloat(.FontSize, 14.0f) == 10.0f,
				"the class did not override the type's font size");
		}

		if (let group = view as ViewGroup)
		{
			for (int i < group.ChildCount)
				WalkFields(group.GetChildAt(i), ref count);
		}
	}

	[Test]
	public static void ThePropertyFieldClassReachesEveryEditorsFields()
	{
		StyleSheetLoader.InitializeGlobals();

		let context = scope UIContext();
		let root = new RootView();
		defer root.ReleaseRef();
		root.ViewportSize = .(800, 600);
		context.AddRootView(root);

		let sheet = DarkTheme.Create();
		sheet.ForClass("property-field").Set(.FontSize, 10.0f);
		context.SetStyleSheet(sheet);

		let floatEditor = scope FloatEditor("f", 1.0);
		let intEditor = scope IntEditor("i", 1);
		let float2Editor = scope Float2Editor("v2", .Zero);
		let float3Editor = scope Float3Editor("v3", .Zero);
		let float4Editor = scope Float4Editor("v4", .Zero);

		// An editor's control is owned by the editor, so the tree takes a reference of its own.
		for (let editor in scope PropertyEditor[](floatEditor, intEditor, float2Editor,
			float3Editor, float4Editor))
		{
			editor.EditorView.AddRef();
			root.AddView(editor.EditorView);
		}

		let vector3 = new Vector3Field();
		root.AddView(vector3);

		int32 count = 0;
		WalkFields(root, ref count);

		// One each from the scalar editors, then two, three, four and three more.
		Test.Assert(count == 1 + 1 + 2 + 3 + 4 + 3, scope $"found {count} fields");
	}
}
