package prezi.text.harfbuzz;

import org.hamcrest.MatchersBase;

class HarfBuzzJsTestBase extends MatchersBase
{
	var ZWNJ:String;
	var harfbuzz:HarfBuzzBackend;
	var font:HarfBuzzFont;

	@Before
	public function init()
	{
		this.ZWNJ = String.fromCharCode(0x200C);
		this.harfbuzz = new HarfBuzzJs();
		this.font = harfbuzz.createFont("test", haxe.Resource.getBytes(getFontName()).getData(), null);
	}

	function getFontName():String
	{
		throw "Abstract method";
		return null;
	}

	function assertShapeProperties(shapes:Array<Shape>, property:String, expected:Array<Dynamic>)
	{
		assertThat("number of shapes", shapes.length, is(expected.length));
		for (shapeIdx in 0...shapes.length)
		{
			if (expected[shapeIdx] != null)
			{
				assertThat('shape ${shapeIdx} ${property}', Reflect.field(shapes[shapeIdx], property), is(expected[shapeIdx]));
			}
		}
	}
}
