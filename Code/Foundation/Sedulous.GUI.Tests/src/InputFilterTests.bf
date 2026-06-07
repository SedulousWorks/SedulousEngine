namespace Sedulous.GUI.Tests;

using System;
using Sedulous.GUI;

class InputFilterTests
{
	[Test]
	public static void None_AcceptsAll()
	{
		let filter = scope InputFilter();
		Test.Assert(filter.Accept('a'));
		Test.Assert(filter.Accept('Z'));
		Test.Assert(filter.Accept('5'));
		Test.Assert(filter.Accept(' '));
		Test.Assert(filter.Accept('!'));
	}

	[Test]
	public static void Digits_AcceptsOnlyDigits()
	{
		let filter = InputFilter.Digits();
		defer delete filter;

		Test.Assert(filter.Accept('0'));
		Test.Assert(filter.Accept('5'));
		Test.Assert(filter.Accept('9'));
		Test.Assert(!filter.Accept('a'));
		Test.Assert(!filter.Accept(' '));
		Test.Assert(!filter.Accept('.'));
	}

	[Test]
	public static void HexDigits_AcceptsHexChars()
	{
		let filter = InputFilter.HexDigits();
		defer delete filter;

		Test.Assert(filter.Accept('0'));
		Test.Assert(filter.Accept('9'));
		Test.Assert(filter.Accept('a'));
		Test.Assert(filter.Accept('f'));
		Test.Assert(filter.Accept('A'));
		Test.Assert(filter.Accept('F'));
		Test.Assert(!filter.Accept('g'));
		Test.Assert(!filter.Accept('G'));
		Test.Assert(!filter.Accept(' '));
	}

	[Test]
	public static void Custom_UsesDelegate()
	{
		let filter = scope InputFilter();
		filter.SetCustomFilter(new (c) => c == 'x' || c == 'y');

		Test.Assert(filter.Accept('x'));
		Test.Assert(filter.Accept('y'));
		Test.Assert(!filter.Accept('z'));
		Test.Assert(!filter.Accept('a'));
	}
}
