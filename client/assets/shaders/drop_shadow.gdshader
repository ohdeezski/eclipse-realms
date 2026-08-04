// Eclipse Realms — drop_shadow.gdshader (G-ART-SHADER / Shiki lane)
// 2.5D contact shadow: renders a soft ellipse at the entity's feet.
// Applied to a Sprite2D child positioned at the entity origin (feet).
// This is the CORE 2.5D depth cue. Final tuning owned by Shiki.
shader_type canvas_item;

uniform float shadow_scale : hint_range(0.3, 2.0) = 1.0;
uniform float shadow_alpha : hint_range(0.0, 1.0) = 0.35;
uniform vec2 shadow_offset = vec2(0.0, 0.0);
uniform vec3 shadow_color = vec3(0.0, 0.0, 0.0);

void fragment() {
	// Distance from center (UV 0..1) -> ellipse falloff
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float d = length(p * vec2(1.0, 0.6));
	float a = smoothstep(1.0, 0.0, d) * shadow_alpha;
	COLOR = vec4(shadow_color, a);
}
