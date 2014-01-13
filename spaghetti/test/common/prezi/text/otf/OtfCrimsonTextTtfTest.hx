package prezi.text.otf;

import massive.munit.Assert;

class OtfCrimsonTextTtfTest extends FontTestBase
{
	override private function fontName():String
	{
		return "CrimsonText.ttf";
	}

	@Test
	public function testFontHeader()
	{
		assertFontProperties({
			"tag": OtfFont.TAG_CODE_SFNT,
			"ttfScale": 2,
			"ascent": 1026 * 2,
			"descent": -297 * 2,
			"lineGap": 92 * 2,
			"unitsPerEm": 1024 * 2,
			"underlinePosition": -135 * 2,
			"underlineThickness": 47 * 2,
			"numberOfHMetrics": 1796,
		});
	}

	@Test
	public function testGlyphCodeOfLowercaseP()
	{
		var glyphCode = font.unicodeToGlyphCode("p".code);
		assertThat(glyphCode, is(83));
	}

	@Test
	public function testLoadLowercasePGlyph()
	{
		var glyphCode = font.unicodeToGlyphCode("p".code);
		var outline = font.glyphOutline(glyphCode);
		assertThat("outline", outline, is([1,1,538,872,3,730,872,838,743,3,946,614,946,468,3,946,276,812,130,3,678,-16,508,-16,3,478,-16,455,-14,3,432,-12,414,-7,3,396,-2,386,2,3,376,6,360,13,3,344,20,340,22,3,332,12,332,-4,2,332,-176,3,332,-292,348,-354,3,352,-368,400,-381,3,448,-394,468,-394,3,474,-394,476,-419,3,478,-444,474,-452,3,274,-442,260,-442,3,248,-442,42,-452,3,34,-444,34,-419,3,34,-394,42,-394,3,66,-394,113,-381,3,160,-368,164,-354,3,178,-296,178,-214,2,178,612,3,178,690,150,720,3,130,744,101,753,3,72,762,53,762,3,34,762,34,766,3,34,814,46,816,3,258,848,322,868,3,324,868,328,869,3,332,870,332,870,3,338,870,338,859,3,338,848,336,832,3,334,816,334,814,2,334,802,3,362,822,427,847,3,492,872,538,872,1,474,774,3,412,774,372,741,3,332,708,332,646,2,332,196,3,332,142,390,105,3,448,68,516,68,3,634,68,704,174,3,774,280,774,412,3,774,580,685,677,3,596,774,474,774]));
	}

	@Test
	public function testAdvanceWidthOfLowercaseP()
	{
		var glyphCode = font.unicodeToGlyphCode("p".code);
		var advanceWidth = font.advanceWidth(glyphCode);
		assertThat("advanceWidth", advanceWidth, is(511 * 2));
	}
}
