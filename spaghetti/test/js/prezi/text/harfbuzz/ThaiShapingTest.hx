package prezi.text.harfbuzz;

class ThaiShapingTest extends HarfBuzzJsTestBase
{
	override function getFontName()
	{
		return "Garuda.ttf";
	}

	@Test
	public function shouldShapeDiacriticsProperly()
	{
		var shapes = font.shape("ให้", []);
		assertShapeProperties(shapes, "cluster",   [    0,    1,    1 ]);
		assertShapeProperties(shapes, "codepoint", [  197,  173,  110 ]);
		assertShapeProperties(shapes, "xAdvance",  [  800, 1302,    0 ]);
	}

	@Test
	public function shouldShapeDiacriticsProperlyEvenIfTextStartsWithLatin()
	{
		var shapes = font.shape("A ให้", []);
		assertShapeProperties(shapes, "cluster",   [    0,    1,    2,    3,    3 ]);
		assertShapeProperties(shapes, "codepoint", [   36,    3,  197,  173,  110 ]);
		assertShapeProperties(shapes, "xAdvance",  [ 1332,  680,  800, 1302,    0 ]);
	}
}
