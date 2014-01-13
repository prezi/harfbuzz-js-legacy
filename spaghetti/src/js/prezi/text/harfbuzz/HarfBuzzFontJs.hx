package prezi.text.harfbuzz;

import prezi.text.otf.OtfConstants;
import prezi.text.otf.OtfFont;

class HarfBuzzFontJs extends AbstractHarfBuzzFont
{
	static inline var COPY_BLOCK_SIZE = 32768;

	var fontData:Dynamic;
	var hbFont:Dynamic;
	var glyphHAdvanceFunction:Dynamic;
	var glyphFunction:Dynamic;
	var buffer:Dynamic;

	public function new(harfBuzzJs:HarfBuzzJs, fontId:String, fileData:haxe.io.BytesData, overrideLineMetrics:OverrideLineMetrics = null)
	{
		var harfbuzz = harfBuzzJs.raw;
		var skipHeaderBytes = AbstractHarfBuzzFont.isKegFile(fileData) ? AbstractHarfBuzzFont.KEG_HEADER.length : 0;
		// Allocate memory on Emscripten heap and copy file data there
		// trace('Allocating array for font ${fontId}: ${fileData.length} bytes');
		this.fontData = untyped __js__ ("new (harfbuzz.array(harfbuzz.Char, fileData.length - skipHeaderBytes))()");
		if (harfBuzzJs.heapName == "HEAP8")
		{
			// console.log "Using HEAP8 (TypedArrays), skipping ${skipHeaderBytes}"
			var fileDataArray:Dynamic = untyped __js__ ("new Uint8Array(fileData)");
			if (skipHeaderBytes > 0)
			{
				fileDataArray = fileDataArray.subarray(skipHeaderBytes);
			}
			untyped __js__("harfbuzz['HEAP8'].set(fileDataArray, this.fontData.$ptr)");
		}
		else
		{
			// console.log "Using HEAP (JS Arrays)"
			var modern = untyped __js__ ("Array.prototype.splice && Array.prototype.unshift && fileData.slice && fileData.unshift");
			if (modern)
			{
				// Copy at most 32k
				// - IE9 in IE8 mode has a limit on the number of arguments for Function.apply()
				//   thqt seems to be around 200k
				// - The WebKit in Adobe Air 3.6 has a limit of 64k exactly, so to be safe we use
				//   only 32k blocks

				var copyOffset = skipHeaderBytes;
				while (copyOffset < fileData.length)
				{
					var copyLength = Std.int(Math.min(fileData.length - copyOffset, COPY_BLOCK_SIZE));
					untyped __js__ ("var args = fileData.slice(copyOffset, copyOffset + copyLength)");
					untyped __js__ ("args.unshift(this.fontData.$ptr + copyOffset - skipHeaderBytes, copyLength)");
					untyped __js__ ("Array.prototype.splice.apply(harfbuzz['HEAP'], args)");
					copyOffset += copyLength;
				}
			}
			else
			{
				// It might happen that we got a Uint8Array here that has no unshift() method.
				// It might even be missing a slice() method (Chrome/10). Revert to the most
				// basic way of doing this. This will be slow.
				for (idx in 0...(fileData.length - skipHeaderBytes))
				{
					untyped __js__ ("harfbuzz['HEAP'][this.fontData.$ptr + idx] = fileData[skipHeaderBytes + idx]");
				}
			}
		}
		super(harfBuzzJs, fontId, new OtfFont(new EmscriptenFontFileReader(harfBuzzJs, untyped __js__("this.fontData.$ptr"))), overrideLineMetrics);

		// Create HarfBuzz blob
		var blob = harfbuzz.hb_blob_create(fontData, fileData.length - skipHeaderBytes, 1, null, null);
		var face = harfbuzz.hb_face_create(blob, 0);
		harfbuzz.hb_blob_destroy(blob);
		this.hbFont = harfbuzz.hb_font_create(face);
		harfbuzz.hb_face_destroy(face);
		harfbuzz.hb_font_set_scale(hbFont, otfFont.unitsPerEm, otfFont.unitsPerEm);

		// Create font functions
		this.glyphHAdvanceFunction = createGlyphHAdvanceFunction(otfFont);
		this.glyphFunction = createGlyphFunction(otfFont);

		var ffuncs = harfbuzz.hb_font_funcs_create();
		harfbuzz.hb_font_funcs_set_glyph_h_advance_func(ffuncs, glyphHAdvanceFunction, null, null);
		harfbuzz.hb_font_funcs_set_glyph_func(ffuncs, glyphFunction, null, null);
		harfbuzz.hb_font_set_funcs(hbFont, ffuncs, null, null);
		harfbuzz.hb_font_funcs_destroy(ffuncs);

		this.buffer = harfbuzz.hb_buffer_create();

		// trace('Buffer @ ${this.buffer.$$ptr}, font at ${this.hbFont.$$ptr}');
	}

	override public function destroy()
	{
		var harfbuzz = cast (harfbuzz, HarfBuzzJs).raw;
		harfbuzz.hb_buffer_destroy(buffer);
		harfbuzz.hb_font_destroy(hbFont);
		harfbuzz.free(fontData);

		harfbuzz.unregisterCallback(glyphHAdvanceFunction);
		harfbuzz.unregisterCallback(glyphFunction);
	}

	override function makeFeatures(features:Array<String>):Dynamic
	{
		var harfbuzz = cast (harfbuzz, HarfBuzzJs).raw;
		var hb_features = null;
		if (features.length > 0)
		{
			hb_features = untyped __js__ ("new (harfbuzz.array(harfbuzz.hb_feature_t, features.length))()");
			for (i in 0...features.length)
			{
				var feature = features[i];
				var featureString = untyped __js__ ("new harfbuzz.string(feature, harfbuzz.ALLOC_STACK)");
				harfbuzz.hb_feature_from_string(featureString, -1, hb_features.ptr(i));
				// trace('${featureString}: ${hb_features.ptr(i)});
			}
		}
		return hb_features;
	}

	override function getUcdnScript(unicode:Int):Int
	{
		return cast (harfbuzz, HarfBuzzJs).raw.ucdn_get_script(unicode);
	}

	override function shapeRun(textRun:String, startCluster:Int, shapes:Array<Shape>, hb_features:Dynamic, hb_feature_count:Int)
	{
		var harfbuzz = cast (harfbuzz, HarfBuzzJs).raw;
		var string = untyped __js__ ("new harfbuzz.string(textRun, harfbuzz.ALLOC_STACK)");
		harfbuzz.hb_buffer_reset(buffer);
		harfbuzz.hb_buffer_add_utf8(buffer, string, -1, 0, -1);
		harfbuzz.hb_buffer_guess_segment_properties(buffer);
		harfbuzz.hb_buffer_set_direction(buffer, harfbuzz.HB_DIRECTION_LTR);

		// Clusters by defaut refer to byte-indexes in the UTF-8 string.
		// We need character indexes, so we override them before shaping.
		var len = harfbuzz.hb_buffer_get_length(buffer);
		var glyph = harfbuzz.hb_buffer_get_glyph_infos(buffer, null);
		for (i in 0...len)
		{
			glyph.set("cluster", startCluster + i);
			glyph = untyped __js__ ("glyph.$next()");
		}

		harfbuzz.hb_shape(hbFont, buffer, hb_features, hb_feature_count);

		len = harfbuzz.hb_buffer_get_length(buffer);
		glyph = harfbuzz.hb_buffer_get_glyph_infos(buffer, null);
		var pos = harfbuzz.hb_buffer_get_glyph_positions(buffer, null);
		for (i in 0...len)
		{
			// trace('Glyph #${i}: ${glyph}, position: ${pos}');
			shapes.push({
				codepoint: glyph.get("codepoint"),
				cluster: glyph.get("cluster"),
				xAdvance: pos.get("x_advance"),
				yAdvance: pos.get("y_advance"),
				xOffset: pos.get("x_offset"),
				yOffset: pos.get("y_offset")
			});
			glyph = untyped __js__ ("glyph.$next()");
			pos = untyped __js__ ("pos.$next()");
		}
	}

	function createGlyphHAdvanceFunction(otfFont:OtfFont):Dynamic
	{
		var harfbuzz = cast (harfbuzz, HarfBuzzJs).raw;
		return harfbuzz.callback(harfbuzz.hb_position_t, null, {
			font: harfbuzz.ptr(harfbuzz.hb_font_t),
			font_data: harfbuzz.ptr(harfbuzz.Void),
			glyph: harfbuzz.hb_codepoint_t,
			user_data: harfbuzz.ptr(harfbuzz.Void)
		}, function(font, font_data, glyph, user_data) {
			return otfFont.advanceWidth(glyph);
		});
	}

	function createGlyphFunction(otfFont:OtfFont):Dynamic
	{
		var harfbuzz = cast (harfbuzz, HarfBuzzJs).raw;
		return harfbuzz.callback(harfbuzz.Bool, null, {
			font: harfbuzz.ptr(harfbuzz.hb_font_t),
			font_data: harfbuzz.ptr(harfbuzz.Void),
			unicode: harfbuzz.hb_codepoint_t,
			variant_selector: harfbuzz.hb_codepoint_t,
			glyph: harfbuzz.ptr(harfbuzz.hb_codepoint_t),
			user_data: harfbuzz.ptr(harfbuzz.Void)
		}, function(font, font_data, unicode, variant_selector, glyph, user_data) {
			var glyphIndex = otfFont.unicodeToGlyphCode(unicode);
			glyph.set(glyphIndex);
			return glyphIndex != OtfConstants.MISSING_GLYPH_CODE;
		});
	}
}
