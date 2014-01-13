package prezi.text.harfbuzz;

class SimpleShapingTest extends HarfBuzzJsTestBase
{
	override function getFontName()
	{
		return "PTSans-B.keg";
	}

	@Test
	public function kerningShouldBeSelectivelyDisabledBetween0and3()
	{
		var shapes = font.shape("VAV VAV", [ "-kern[0:3]" ]);
		assertShapeProperties(shapes, "codepoint", [   57,   36,   57,    3,   57,   36,   57 ]);
		assertShapeProperties(shapes, "xAdvance",  [ 1204, 1210, 1204, null, 1068, 1074, 1204 ]);
	}

	@Test
	public function ligaturesShouldBeDisabledAt2()
	{
		var shapes = font.shape("ofi ofi", [ "-liga[2]" ]);
		assertShapeProperties(shapes, "codepoint", [ 82, 73, 76, 3, 82, 715 ]);
	}

	@Test
	public function shoudlSplitTheSecondLigature()
	{
		var shapes = font.shape("fif" + ZWNJ + "i", []);
		assertShapeProperties(shapes, "codepoint", [  715,   73,    3,   76 ]);
		assertShapeProperties(shapes, "xAdvance",  [ 1106,  642,    0,  538 ]);
	}

	@Test
	public function shouldBeKernedBothTimesDespiteTheZwnj()
	{
		var shapes = font.shape("VA V" + ZWNJ + "A V|A", []);
		assertShapeProperties(shapes, "codepoint", [   57,   36,    3,   57,    3,   36,    3,   57,   95,   36 ]);
		assertShapeProperties(shapes, "xAdvance",  [ 1068, 1122, null, 1068,    0, 1122, null, 1204, null, 1210 ]);
	}
}
