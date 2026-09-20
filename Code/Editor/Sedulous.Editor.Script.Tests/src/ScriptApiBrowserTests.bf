using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Script;

namespace Sedulous.Editor.Script.Tests;

/// The API browser's tree: order, labels, insert text, the filter and the editor mark.
class ScriptApiBrowserTests
{
	private static ScriptApiMember Member(StringView name, StringView signature, bool isStatic, ScriptApiMemberKind kind)
	{
		let member = new ScriptApiMember();
		member.Name.Set(name);
		member.Signature.Set(signature);
		member.IsStatic = isStatic;
		member.Kind = kind;
		return member;
	}

	private static void MakeSurface(List<ScriptApiType> outTypes)
	{
		let zeta = new ScriptApiType();
		zeta.ScriptName.Set("Zeta");
		zeta.Members.Add(Member("beta", "beta(_)", false, .Method));
		zeta.Members.Add(Member("alpha", "", false, .Property));
		outTypes.Add(zeta);
		let math = new ScriptApiType();
		math.ScriptName.Set("Math");
		math.IsNamespace = true;
		math.Members.Add(Member("Dot", "Dot(_,_)", true, .Method));
		math.Members.Add(Member("Cross", "Cross(_,_)", true, .Method));
		outTypes.Add(math);
	}

	[Test]
	public static void OrderLabelsAndInsertText()
	{
		let surface = scope List<ScriptApiType>();
		defer { ClearAndDeleteItems!(surface); }
		MakeSurface(surface);
		let tree = scope ScriptApiTree();
		tree.Build(surface, "");
		Test.Assert(tree.Roots.Count == 2);
		let math = tree.Nodes[tree.Roots[0]];
		let zeta = tree.Nodes[tree.Roots[1]];
		Test.Assert((math.Label == "Math") && (zeta.Label == "Zeta"));
		Test.Assert((math.Depth == 0) && (math.InsertText == "Math"));
		Test.Assert(math.Children.Count == 2);
		Test.Assert(tree.Nodes[math.Children[0]].Label == "Cross(_,_)");
		Test.Assert(tree.Nodes[math.Children[1]].Label == "Dot(_,_)");
		Test.Assert(zeta.Children.Count == 2);
		Test.Assert(tree.Nodes[zeta.Children[0]].Label == "alpha"); // no signature
		Test.Assert(tree.Nodes[zeta.Children[1]].Label == "beta(_)");
		let dot = tree.Nodes[math.Children[1]];
		Test.Assert((dot.InsertText == "Dot") && (dot.Depth == 1));
	}

	[Test]
	public static void TheFilterIsCaseInsensitive()
	{
		let surface = scope List<ScriptApiType>();
		defer { ClearAndDeleteItems!(surface); }
		MakeSurface(surface);
		let tree = scope ScriptApiTree();
		tree.Build(surface, "dot");
		Test.Assert(tree.Roots.Count == 1);
		let math = tree.Nodes[tree.Roots[0]];
		Test.Assert((math.Label == "Math") && (math.Children.Count == 1));
		Test.Assert(tree.Nodes[math.Children[0]].Label == "Dot(_,_)");

		tree.Build(surface, "zeta");
		Test.Assert((tree.Roots.Count == 1) && (tree.Nodes[tree.Roots[0]].Children.Count == 2));

		tree.Build(surface, "nothing");
		Test.Assert(tree.Roots.IsEmpty && tree.Nodes.IsEmpty);
	}

	[Test]
	public static void EditorOnlyBindingsAreMarked()
	{
		// A surface with a type in the Editor domain and one in the Runtime domain.
		let scriptSurface = scope ScriptSurface();
		scriptSurface.AddType("Test.EditorOnlyThing", .Class, "Editor");
		scriptSurface.AddType("Test.RuntimeThing", .Class, ScriptDomains.Runtime);
		let api = scope ScriptApiSurface();
		api.SetSurface(scriptSurface);

		let surface = scope List<ScriptApiType>();
		defer { ClearAndDeleteItems!(surface); }
		let marked = new ScriptApiType();
		marked.ScriptName.Set("EditorOnlyThing");
		marked.TypeFullName.Set("Test.EditorOnlyThing");
		surface.Add(marked);
		let plain = new ScriptApiType();
		plain.ScriptName.Set("RuntimeThing");
		plain.TypeFullName.Set("Test.RuntimeThing");
		surface.Add(plain);
		let unknown = new ScriptApiType();
		unknown.ScriptName.Set("Bare"); // no surface identity: no marker
		surface.Add(unknown);

		let tree = scope ScriptApiTree();
		tree.Build(surface, "", scope (type) => api.IsEditorOnly(type));
		Test.Assert(tree.Roots.Count == 3);
		Test.Assert(tree.Nodes[tree.Roots[1]].Label == "EditorOnlyThing [editor]");
		Test.Assert(tree.Nodes[tree.Roots[1]].InsertText == "EditorOnlyThing");
		Test.Assert(tree.Nodes[tree.Roots[2]].Label == "RuntimeThing");
		Test.Assert(tree.Nodes[tree.Roots[0]].Label == "Bare");
		Test.Assert(api.IsEditorOnly(marked) && !api.IsEditorOnly(plain) && !api.IsEditorOnly(unknown));
	}
}
