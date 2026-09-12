using Sedulous.Scene;
using Sedulous.Spline;

namespace Sedulous.Engine.Spline;

/// The pool of authored curves.
///
/// It creates and frees the curve each component points at: a component is a struct in a
/// packed pool, so it cannot own one itself. Raptor holds the curve BY VALUE and lets the
/// vector's destructor deal with it.
class SplineComponentManager : SerializableComponentManager<SplineComponent>
{
	protected override void OnComponentCreated(SplineComponent* component, EntityHandle entity)
	{
		component.Curve = new SplineCurve();
	}

	protected override void OnComponentDestroyed(SplineComponent* component, EntityHandle entity)
	{
		delete component.Curve;
		component.Curve = null;
	}
}
