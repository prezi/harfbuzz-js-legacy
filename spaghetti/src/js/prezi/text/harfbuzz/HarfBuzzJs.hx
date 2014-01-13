package prezi.text.harfbuzz;

class HarfBuzzJs implements HarfBuzzBackend
{
	public var raw (default, null):Dynamic;
	// TODO This might not be needed, since we don't support untyped access anymore
	public var heapName (default, null):String;

	public function new()
	{
		this.raw = untyped __js__('(function($) {
		    var Module={};
		    Module["FAST_MEMORY"]=1;
		    // Use 32 MB of memory by default -- Korean fonts can be big
		    Module["TOTAL_MEMORY"] = 32 * 1024 * 1024');

		haxe.macro.Compiler.includeFile("harfbuzz.js");

		untyped __js__('return Module; }).apply(this)');

		if (untyped __js__ ("this.raw['HEAP8']"))
		{
			this.heapName = "HEAP8";
		}
		else
		{
			this.heapName = "HEAP";
		}
	}

	public function createFont(fontId:String, fileData:haxe.io.BytesData, overrideLineMetrics:OverrideLineMetrics):HarfBuzzFont
	{
		return new HarfBuzzFontJs(this, fontId, fileData, overrideLineMetrics);
	}

	public function version():String
	{
		return untyped __js__('this.raw["version"] + " (built with emcc " + this.raw["emccVersion"] + ")"');
	}
}
