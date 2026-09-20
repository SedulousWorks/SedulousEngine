using System;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Core.Tests;

/// Flips a flag, and back.
class FlipCommand : EditorCommand
{
	private bool* mFlag;
	public this(bool* flag) { mFlag = flag; }
	public override bool Execute() { *mFlag = !*mFlag; return true; }
	public override void Undo() { *mFlag = !*mFlag; }
	public override StringView TypeId => "flip";
}
