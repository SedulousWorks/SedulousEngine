using System;
using Sedulous.GUI;
using Sedulous.Engine.Project;

namespace Sedulous.Editor.App;

/// Help > About: the engine's name and this build's identity (the version with its label, its
/// build number or "local build", the executable's stamp), and a Copy Version button beside OK
/// that hands the same line to the caller to put on the clipboard, so a report names the exact
/// build.
static class AboutBox
{
	/// The About box's text and what Copy Version copies, appended: the engine's name and
	/// `identity`.
	public static void Line(StringView identity, String outLine)
	{
		outLine.AppendF("{} {}", EngineVersion.ProductName, identity);
	}

	/// The About box over `identity` (EngineVersion.BuildIdentity): OK, and Copy Version, which
	/// calls `copy` with the line before the box closes. TAKES OWNERSHIP of `copy` (null copies
	/// nothing); the box's one reference is the caller's.
	public static Sedulous.GUI.MessageBox Make(StringView identity, delegate void(StringView line) copy)
	{
		let about = new Sedulous.GUI.MessageBox();
		about.Configure(scope $"About {EngineVersion.ProductName}", Line(identity, .. scope .()), .Ok);
		about.AddButton("Copy Version", "copy");
		// The box's own listener: the line is its message.
		about.AddEventListener(.Changed, new [=about, =copy] (e) =>
			{
				if ((copy != null) && (about.ResultName == "copy"))
					copy(about.Message);
			} ~ delete copy);
		return about;
	}
}
