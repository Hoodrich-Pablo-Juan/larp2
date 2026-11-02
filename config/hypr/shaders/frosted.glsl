// Frosted glass for every window, loaded by modules/frosted.lua through the
// Hypr-DarkWindow plugin (installed with hyprpm by install.sh).
//
// The plugin turns a window's fragment shader into this function, so the
// window's own colour is lowered in alpha: Hyprland then blurs whatever is
// behind it and the whole window reads as glass. Hyprland samples window
// textures with premultiplied alpha, hence the divide/multiply around the
// colour work — without it the glaze darkens as the window gets clearer.

uniform float frostOpacity; // window alpha, 1.0 = opaque
uniform float frostTint;    // how much of the milky glaze to mix in, 0-1
uniform float frostGrain;   // grain strength, 0 = perfectly smooth glass

float frostHash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void windowShader(inout vec4 color) {
    if (color.a <= 0.0)
        return;

    vec3 rgb = color.rgb / color.a; // unpremultiply

    // Diffused light: lift and cool the colour a touch instead of washing it out.
    rgb = mix(rgb, rgb * 0.96 + vec3(0.045, 0.05, 0.06), frostTint);

    // Static per-pixel grain in window space is the "frost". x_PixelPos is used
    // on purpose rather than x_Time: a frozen pattern costs nothing, an animated
    // one would redraw the entire window every frame.
    rgb += (frostHash(floor(x_PixelPos)) - 0.5) * frostGrain;

    float alpha = color.a * mix(1.0, frostOpacity, clamp(x_FadeIn - x_FadeOut, 0.0, 1.0));

    color = vec4(clamp(rgb, 0.0, 1.0) * alpha, alpha);
}
