package prezi.text.harfbuzz;

class HarfBuzzImpl implements HarfBuzz
{
	var harfBuzz:HarfBuzzBackend;

	public function new() {}

	public function getHarfBuzzBackend()
	{
		if (harfBuzz == null)
		{
			harfBuzz = new HarfBuzzJs();
		}
		return harfBuzz;
	}
}
