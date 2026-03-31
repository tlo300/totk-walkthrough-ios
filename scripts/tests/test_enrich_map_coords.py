def test_slugify_shrine_name():
    from scripts.enrich_map_coords import slugify
    assert slugify("Ukouh Shrine") == "ukouh-shrine"


def test_slugify_strips_guide_suffix():
    from scripts.enrich_map_coords import slugify
    assert slugify("Ukouh Shrine Guide") == "ukouh-shrine"


def test_slugify_preserves_hyphens():
    from scripts.enrich_map_coords import slugify
    assert slugify("Ga-ahisas Shrine") == "ga-ahisas-shrine"


def test_layer_from_str_sky():
    from scripts.enrich_map_coords import layer_from_str
    assert layer_from_str("Sky") == "sky"


def test_layer_from_str_surface():
    from scripts.enrich_map_coords import layer_from_str
    assert layer_from_str("Surface") == "surface"


def test_layer_from_str_depths():
    from scripts.enrich_map_coords import layer_from_str
    assert layer_from_str("Depths") == "depths"


def test_layer_from_str_case_insensitive():
    from scripts.enrich_map_coords import layer_from_str
    assert layer_from_str("SURFACE") == "surface"


def test_layer_from_str_depth_singular():
    from scripts.enrich_map_coords import layer_from_str
    assert layer_from_str("depth") == "depths"
