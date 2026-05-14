namespace Sedulous.Inspection;

/// Interface for components that can describe their inspectable properties.
/// Implemented via comptime codegen in editor extensions - not manually.
interface IInspectable
{
	void DescribeProperties(IPropertyDescriptor desc);
}
