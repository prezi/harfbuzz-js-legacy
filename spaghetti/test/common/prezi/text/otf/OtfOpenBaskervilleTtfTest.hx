package prezi.text.otf;

import massive.munit.Assert;

class OtfOpenBaskervilleTtfTest extends FontTestBase
{
	override private function fontName():String
	{
		return "OpenBaskerville-0.0.75.ttf";
	}

	@Test
	public function testFontHeader()
	{
		assertFontProperties({
			"tag": OtfFont.TAG_CODE_SFNT,
			"ttfScale": 2,
			"ascent": 916 * 2,
			"descent": -218 * 2,
			"lineGap": 0 * 2,
			"unitsPerEm": 1000 * 2,
			"underlinePosition": -109 * 2,
			"underlineThickness": Std.int(54.5 * 2),
			"numberOfHMetrics": 241,
		});
	}

	@Test
	public function testGlyphCodeOfLowercaseP()
	{
		var glyphCode = font.unicodeToGlyphCode("p".code);
		assertThat(glyphCode, is(82));
	}

	@Test
	public function testLoadLowercasePGlyph()
	{
		var glyphCode = font.unicodeToGlyphCode("p".code);
		var outline = font.glyphOutline(glyphCode);
		assertThat("outline", outline, is([1,1,318,420,3,318,614,376,725,3,434,836,550,836,3,694,836,769,719,3,844,602,844,420,3,844,246,770,125,3,696,4,550,4,3,412,4,365,102,3,318,200,318,420,1,326,874,2,306,874,3,100,840,50,836,2,50,816,3,148,814,171,781,3,194,748,194,622,2,194,-142,3,194,-288,170,-335,3,146,-382,46,-382,2,46,-408,2,464,-408,2,464,-382,3,368,-382,347,-304,3,326,-226,326,78,3,378,24,431,-2,3,484,-28,576,-28,3,782,-28,893,100,3,1004,228,1004,420,3,1004,604,882,736,3,760,868,576,868,3,422,868,330,754]));
	}

	@Test
	public function testAdvanceWidthOfLowercaseP()
	{
		var glyphCode = font.unicodeToGlyphCode("p".code);
		var advanceWidth = font.advanceWidth(glyphCode);
		assertThat("advanceWidth", advanceWidth, is(549 * 2));
	}
}
