using System;

namespace Sedulous.Scene;

/// One domain's declarative account of how to build a scene.
///
/// `DependsOn` states cross domain CONSTRUCTION order as data. Not tick order, which is a
/// system's UpdateOrder and a different question entirely.
struct SceneModule
{
	public typealias InstallFunction = function void(Scene scene);
	public typealias RegisterReflectionFunction = function void();

	private StringView mId;
	private InstallFunction mInstall;
	private RegisterReflectionFunction mRegisterReflection;
	/// BUILD TIME data only, consulted by SceneComposition.Build and never retained past it.
	private Span<SceneModule*> mDependsOn;

	public this()
	{
		mId = default;
		mInstall = null;
		mRegisterReflection = null;
		mDependsOn = default;
	}

	public this(StringView id, InstallFunction install,
		RegisterReflectionFunction registerReflection, Span<SceneModule*> dependsOn = default)
	{
		mId = id;
		mInstall = install;
		mRegisterReflection = registerReflection;
		mDependsOn = dependsOn;
	}

	public StringView Id => mId;
	public Span<SceneModule*> DependsOn => mDependsOn;
	public bool HasInstall => mInstall != null;

	/// The raw functions, for the by value copy a composition keeps.
	public InstallFunction InstallFn => mInstall;
	public RegisterReflectionFunction RegisterReflectionFn => mRegisterReflection;

	public void Install(Scene scene)
	{
		if (mInstall != null)
			mInstall(scene);
	}

	public void RegisterReflection()
	{
		if (mRegisterReflection != null)
			mRegisterReflection();
	}
}
