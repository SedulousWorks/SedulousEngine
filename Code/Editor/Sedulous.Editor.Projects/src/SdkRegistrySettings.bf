using System;
using System.Collections;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Projects;

/// The SDKs this user has and which one each project uses: the one section of sdks.xml
/// (SdkRegistry). Several managers and editors of different versions read and write it, so none
/// of its types bumps its version: each grows only by [Appended] fields, which an older reader
/// passes by.
[Serializable(1)]
class SdkRegistrySettings
{
	/// Installed SDKs and registered folders, in the order they were added.
	public List<RegisteredSdk> Sdks = new .() ~ DeleteContainerAndItems!(_);
	/// Per project, the SDK the user picked for it.
	public List<SdkPin> Pins = new .() ~ DeleteContainerAndItems!(_);

	/// The SDK registered at `root`, compared verbatim; null when there is none.
	public RegisteredSdk Find(StringView root)
	{
		for (let sdk in Sdks)
			if (sdk.Root == root)
				return sdk;
		return null;
	}

	/// The pin of the project at `project`, compared verbatim; null when it has none.
	public SdkPin FindPin(StringView project)
	{
		for (let pin in Pins)
			if (pin.Project == project)
				return pin;
		return null;
	}
}

/// One SDK the registry lists: its root (absolute), and whether the manager installed it into its
/// own folder (which it may delete) or the user registered a folder (a checkout or an unpacked
/// SDK, which it only unlists).
[Serializable(1)]
class RegisteredSdk
{
	public String Root = new .() ~ delete _;
	public bool Managed = false;
}

/// A project's chosen SDK: the project's folder and the SDK's root, both absolute.
[Serializable(1)]
class SdkPin
{
	public String Project = new .() ~ delete _;
	public String Sdk = new .() ~ delete _;
}
