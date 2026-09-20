using System;
using Sedulous.Content;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Core.Tests;

class TestPageFactory : IEditorPageFactory
{
	private Type mType;
	private String mTitle = new .() ~ delete _;

	public this(Type type, StringView title)
	{
		mType = type;
		mTitle.Set(title);
	}

	public Type PrimaryType => mType;

	public EditorPage CreatePage(EditorContext context, Instance instance) => new TestPage(mTitle);
}
