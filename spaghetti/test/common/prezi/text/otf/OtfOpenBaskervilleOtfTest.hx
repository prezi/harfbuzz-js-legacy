package prezi.text.otf;

import massive.munit.Assert;

class OtfOpenBaskervilleOtfTest extends FontTestBase
{
	override private function fontName():String
	{
		return "OpenBaskerville-0.0.75.otf";
	}

	@Test
	public function testFontHeader()
	{
		assertFontProperties({
			"tag": OtfFont.TAG_CODE_OTTO,
			"ttfScale": 1,
			"ascent": 916,
			"descent": -218,
			"lineGap": 0,
			"unitsPerEm": 1000,
			"underlinePosition": -109,
			"underlineThickness": Std.int(54.5),
			"numberOfHMetrics": 240,
		});
	}

	@Test
	public function testGlyphCodeOfLowercaseP()
	{
		var glyphCode = font.unicodeToGlyphCode("p".code);
		assertThat(glyphCode, is(80));
	}

	@Test
	public function testLoadLowercasePGlyph()
	{
		var glyphCode = font.unicodeToGlyphCode("p".code);
		var outline = font.glyphOutline(glyphCode);
		assertThat("outline", outline, is( [1,1,159,210,4,159,75,178,2,275,2,4,380,2,422,106,422,210,4,422,325,375,418,275,418,4,195,418,159,335,159,210,1,163,437,2,165,377,4,181,397,211,434,288,434,4,412,434,502,331,502,210,4,502,89,432,-14,288,-14,4,221,-14,193,8,163,39,4,163,-155,166,-191,232,-191,2,232,-204,2,23,-204,2,23,-191,4,94,-191,97,-159,97,-71,2,97,311,4,97,394,91,406,25,408,2,25,418,4,50,420,153,437,153,437]));
	}

	@Test
	public function testAdvanceWidthOfLowercaseP()
	{
		var glyphCode = font.unicodeToGlyphCode("p".code);
		var advanceWidth = font.advanceWidth(glyphCode);
		assertThat("advanceWidth", advanceWidth, is(549));
	}
}
