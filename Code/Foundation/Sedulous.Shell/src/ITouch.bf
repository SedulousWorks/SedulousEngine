namespace Sedulous.Shell;

interface ITouch
{
	int32 TouchCount { get; }
	bool GetTouchPoint(int32 index, out TouchPoint point);
	bool HasTouch { get; }
}
