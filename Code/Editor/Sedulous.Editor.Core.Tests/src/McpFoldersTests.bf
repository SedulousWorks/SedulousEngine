using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Engine.Project;
using Sedulous.Editor.Project;
using Sedulous.Settings;
using Sedulous.VFS;

namespace Sedulous.Editor.Core.Tests;

/// A project's MCP folders: the folders outside it its tools work in, each reached only once the
/// user approved it for that project. The answers are the user's, in their data, never the project's.
class McpFoldersTests
{
	/// A project file could name any folder; opened, it widened what an agent might touch with no
	/// one asked. A listed folder is unanswered until the user answers, and only a yes approves it.
	[Test]
	public static void AListedFolderIsUnansweredUntilTheUserAnswersAndOnlyAYesApprovesIt()
	{
		let cwd = GetCurrentDirectory(.. scope .());
		let answersDir = PathJoin(cwd, "scratch_mcp_folders_answers", .. scope .());
		RemoveDirectoryRecursive(answersDir);
		defer RemoveDirectoryRecursive(answersDir);
		Test.Assert(CreateDirectory(answersDir));
		let project = PathJoin(cwd, "scratch_mcp_folders_project", .. scope .());
		let settings = scope ProjectSettings();
		settings.McpFolders.Add(new .("../Game"));
		settings.McpFolders.Add(new .("../Art"));

		// Each relative to the project, made absolute.
		let listed = scope List<String>();
		defer { ClearAndDeleteItems!(listed); }
		McpFolders.Resolve(project, settings, listed);
		Test.Assert(listed.Count == 2);
		Test.Assert(listed[0] == PathJoin(cwd, "Game", .. scope .()), listed[0]);
		Test.Assert(listed[1] == PathJoin(cwd, "Art", .. scope .()), listed[1]);

		// No answers yet: both unanswered, none approved.
		{
			let standing = scope McpFolderStanding();
			McpFolders.Stand(answersDir, project, settings, standing);
			Test.Assert(standing.Approved.IsEmpty && (standing.Unanswered.Count == 2));
		}

		// Yes to one, no to the other, kept in the user's file.
		{
			let store = scope Settings();
			let answers = store.Section<McpFolderAnswers>();
			let projectKey = McpFolders.ProjectKey(project, .. scope .());
			answers.Record(projectKey, listed[0], true);
			answers.Record(projectKey, listed[1], false);
			Test.Assert(McpFolders.Save(scope NativeFileSystem(answersDir), store) case .Ok);
		}
		{
			let standing = scope McpFolderStanding();
			McpFolders.Stand(answersDir, project, settings, standing);
			Test.Assert((standing.Approved.Count == 1) && (standing.Approved[0] == listed[0]));
			Test.Assert(standing.Unanswered.IsEmpty, "the refused one is asked no more, and not reached");
		}

		// The answers are this project's: another project listing the same folder is asked afresh.
		let other = PathJoin(cwd, "scratch_mcp_folders_other", .. scope .());
		let otherSettings = scope ProjectSettings();
		otherSettings.McpFolders.Add(new .(listed[0])); // absolute, the same folder
		{
			let standing = scope McpFolderStanding();
			McpFolders.Stand(answersDir, other, otherSettings, standing);
			Test.Assert(standing.Approved.IsEmpty && (standing.Unanswered.Count == 1));
		}
	}
}
