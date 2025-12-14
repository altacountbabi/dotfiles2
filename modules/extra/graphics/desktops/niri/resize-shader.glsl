vec4 resize_color(vec3 coords_curr_geo, vec3 size_curr_geo) {
  vec3 coords_next_geo = niri_curr_geo_to_next_geo * coords_curr_geo;

  vec3 coords_stretch = niri_geo_to_tex_next * coords_curr_geo;
  vec3 coords_crop = niri_geo_to_tex_next * coords_next_geo;

  bool can_crop_by_x = niri_curr_geo_to_next_geo[0][0] <= 1.0;
  bool can_crop_by_y = niri_curr_geo_to_next_geo[1][1] <= 1.0;

  vec3 coords = coords_stretch;
  if (can_crop_by_x)
    coords.x = coords_crop.x;
  if (can_crop_by_y)
    coords.y = coords_crop.y;

  vec4 color = texture2D(niri_tex_next, coords.st);

  if (can_crop_by_x && (coords_curr_geo.x < 0.0 || 1.0 < coords_curr_geo.x))
    color = vec4(0.0);
  if (can_crop_by_y && (coords_curr_geo.y < 0.0 || 1.0 < coords_curr_geo.y))
    color = vec4(0.0);

  return color;
}
