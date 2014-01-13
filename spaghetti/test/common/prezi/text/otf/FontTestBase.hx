package prezi.text.otf;

import org.hamcrest.MatchersBase;

class FontTestBase extends MatchersBase
{
	private var font:OtfFont;

	@Before
	public function setup()
	{
		var name = fontName();
		var fileData = haxe.Resource.getBytes(name);
		trace("Reading " + name + ": " + fileData.length + " bytes");
		var reader = new TestFontFileReader(fileData);
		font = new OtfFont(reader);
	}

	private function fontName():String
	{
		return throw "Not implemented";
	}

	public function assertFontProperties(expectedValues:Dynamic)
	{
		for (property in Reflect.fields(expectedValues))
		{
			var expectedValue = Reflect.field(expectedValues, property);
			var actualValue = Reflect.field(font, property);
			assertThat(property, actualValue, is(expectedValue));
		}
	}

	@Test
	public function testMissingGlyphCode()
	{
		var missingGlyphCode = font.unicodeToGlyphCode("蹪".code);
		assertThat(missingGlyphCode, is(OtfConstants.MISSING_GLYPH_CODE));
	}
}
