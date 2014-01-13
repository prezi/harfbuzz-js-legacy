package prezi.text.harfbuzz;

import haxe.io.BytesData;

import prezi.text.otf.OtfFont;
import prezi.text.otf.OtfConstants;

class AbstractHarfBuzzFont implements HarfBuzzFont
{
	// Keg header: UTF-8 BOM + 🍺🍻🍺 + NEWLINE
	static var KEG_HEADER = [
		0xEF, 0xBB, 0xBF, 0xF0, 0x9F, 0x8D, 0xBA, 0xF0,
		0x9F, 0x8D, 0xBB, 0xF0, 0x9F, 0x8D, 0xBA, 0x0A
	];

	static inline var UCDN_SCRIPT_COMMON = 0;
	static inline var UCDN_SCRIPT_INHERITED = 40;

	var harfbuzz:HarfBuzzBackend;
	var fontId:String;
	var overrideLineMetrics:OverrideLineMetrics;
	var otfFont:OtfFont;

	public function new(harfbuzz:HarfBuzzBackend, fontId:String, otfFont:OtfFont, overrideLineMetrics:OverrideLineMetrics)
	{
		this.harfbuzz = harfbuzz;
		this.fontId = fontId;
		this.otfFont = otfFont;
		this.overrideLineMetrics = overrideLineMetrics;
	}

	public function destroy()
	{
		// Do nothing by default
	}

	public function getId():String
	{
		return fontId;
	}

	public function info():FontInfo
	{
		var ascent:Int;
		var descent:Int;
		var lineGap:Int;

		if (overrideLineMetrics != null)
		{
			// trace("Using override metrics", this.overrideLineMetrics);
			ascent  = Math.floor(overrideLineMetrics.ascent  * otfFont.unitsPerEm);
			descent = Math.floor(overrideLineMetrics.descent * otfFont.unitsPerEm);
			lineGap = Math.floor(overrideLineMetrics.lineGap * otfFont.unitsPerEm);
		}
		else
		{
			// trace("Using built-in metrics");
			ascent  = this.otfFont.ascent;
			descent = this.otfFont.descent;
			lineGap = this.otfFont.lineGap;
		}

		return { 
			id: fontId,
			unitsPerEm: otfFont.unitsPerEm,
			ascent: ascent,
			descent: descent,
			lineGap: lineGap,
			italicAngle: otfFont.italicAngle,
			underlinePosition: otfFont.underlinePosition,
			underlineThickness: otfFont.underlineThickness
		};
	}

	public function shape(text:String, features:Array<String>):Array<Shape>
	{
		// Do not shape empty strings
		if (text.length == 0)
		{
			return [];
		}

		// With legacy line metrics we also disable kerning and ligature support
		if (overrideLineMetrics != null)
		{
			features = features.concat([ "-kern", "-liga" ]);
		}

		// Make up hb_features array
		var hb_features = makeFeatures(features);

		// Find same-script ranges
		var start = 0;
		var end = 0;
		var currentScript = -1;
		var shapes = [];
		while (start < text.length)
		{
			var needsBreak = end == text.length;
			if (!needsBreak)
			{
				var script = getUcdnScript(text.charCodeAt(end));

				if (script != UCDN_SCRIPT_COMMON && script != UCDN_SCRIPT_INHERITED)
				{
					if (currentScript != -1 && currentScript != script)
					{
						needsBreak = true;
					}
					currentScript = script;
				}
			}

			if (needsBreak)
			{
				// console.log "Found segment #{start}..#{end} / #{script}: #{text.substring(start, end)}"
				shapeRun(text.substring(start, end), start, shapes, hb_features, features.length);
				start = end;
			}

			end++;
		}
		return shapes;
	}

	function makeFeatures(features:Array<String>):Dynamic
	{
		throw "Not implemented";
		return null;
	}

	function getUcdnScript(unicode:Int):Int
	{
		throw "Not implemented";
		return 0;
	}

	function shapeRun(textRun:String, startCluster:Int, shapes:Array<Shape>, hb_features:Dynamic, hb_feature_count:Int):Void
	{
		throw "Not implemented";
	}

	public function outline(glyphCode:Int):Array<Int>
	{
		return otfFont.glyphOutline(glyphCode);
	}

	static function isKegFile(fileData:BytesData):Bool
	{
		if (cast(fileData.length, Int) < KEG_HEADER.length)
		{
			return false;
		}
		for (i in 0...KEG_HEADER.length)
		{
			if (fileData[i] != KEG_HEADER[i])
			{
				return false;
			}
		}
		// trace("Ahhaha, some keg this is!");
		return true;
	}
}
