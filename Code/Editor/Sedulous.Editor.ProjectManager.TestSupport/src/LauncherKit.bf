using System;
using System.Collections;
using Sedulous.Core.IO;
using Sedulous.Shell;
using Sedulous.GUI;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;

namespace Sedulous.Editor.ProjectManager.TestSupport;

/// The shell's dialogs as a test drives them: what Show in Folder was asked to show, and the one
/// path a file or folder dialog answers (none: cancelled), at once as the null shell does.
public class LauncherDialogs : IDialogService
{
	public List<String> Shown = new .() ~ DeleteContainerAndItems!(_);
	/// What the next file or folder dialog answers; empty cancels.
	public String Answer = new .() ~ delete _;
	public int Asked = 0;

	public void ShowOpenFile(delegate void(Span<String>) callback, Span<FileFilter> filters, StringView defaultPath, bool allowMultiple,
		uint32 parentWindowId) => Reply(callback);

	public void ShowSaveFile(delegate void(Span<String>) callback, Span<FileFilter> filters, StringView defaultPath,
		uint32 parentWindowId) => Reply(callback);

	public void ShowOpenFolder(delegate void(Span<String>) callback, StringView defaultPath, bool allowMultiple,
		uint32 parentWindowId) => Reply(callback);

	public void OpenPath(StringView path)
	{
		Shown.Add(new String(path));
	}

	/// CONSUMES the callback, as the services do.
	private void Reply(delegate void(Span<String>) callback)
	{
		Asked++;
		defer delete callback;
		if (Answer.IsEmpty)
		{
			callback(.());
			return;
		}
		var answer = Answer;
		callback(.(&answer, 1));
	}
}

/// A clipboard of a string.
public class LauncherClipboard : IClipboard
{
	public String Held = new .() ~ delete _;

	public bool HasText => !Held.IsEmpty;

	public void GetText(String outText)
	{
		outText.Append(Held);
	}

	public void SetText(StringView text)
	{
		Held.Set(text);
	}
}

/// What the project manager's tests and the editor's tests both reach for.
public static class LauncherKit
{
	/// The first button in `node`'s subtree showing `text`; null when none does.
	public static Sedulous.GUI.Button ButtonText(Node node, StringView text)
	{
		if (let button = node as Sedulous.GUI.Button)
		{
			if (button.Text == text)
				return button;
		}
		for (int i < node.ChildCount)
		{
			if (let found = ButtonText(node.GetChildAt(i), text))
				return found;
		}
		return null;
	}

	/// The project manifest in `directory` stamped as saved by engine `version`: by a raw text
	/// edit, since a save stamps this engine.
	public static void Stamp(StringView directory, StringView version)
	{
		let probed = scope ProjectSettings();
		Test.Assert(ProjectRegistry.ProbeProject(directory, probed) case .Ok);
		Test.Assert(!probed.EngineVersion.IsEmpty);
		let manifest = PathJoin(directory, ProjectLayout.ManifestFile, .. scope .());
		let bytes = scope List<uint8>();
		Test.Assert(ReadFile(manifest, bytes) case .Ok);
		let text = scope String(StringView((char8*)bytes.Ptr, bytes.Count));
		text.Replace(probed.EngineVersion, version);
		Test.Assert(WriteFile(manifest, .((uint8*)text.Ptr, text.Length)) case .Ok);
	}
}
