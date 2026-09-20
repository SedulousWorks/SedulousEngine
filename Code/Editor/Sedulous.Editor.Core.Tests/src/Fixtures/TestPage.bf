using System;
using Sedulous.Core;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Core.Tests;

class TestPage : EditorPage
{
	private String mTitle = new .() ~ delete _;

	public this(StringView title)
	{
		mTitle.Set(title);
	}

	public override StringView Title => mTitle;

	public override Result<void, ErrorCode> Save()
	{
		ClearDirty();
		return .Ok;
	}
}
