namespace Bulkan;

enum InstanceFunctionFlags
{
	Agnostic = 1,
	Xlib = 2,
	Xcb = _*2,
	Wayland = _*2,
	Android = _*2,
	Win32 = _*2,
	GGP = _*2,
	NN = _*2,
	Metal = _*2,
	MVK = _*2,
	FUCHSIA = _*2,
	QNX = _*2,
	DirectFB = _*2,
	Headless = _*2,
	OHOS = _*2,
}