shader_type canvas_item;
render_mode unshaded;
uniform vec2 contour[21];
uniform float curvature : hint_range(0.0, 0.06) = 0.025;
uniform float strength : hint_range(0.0, 1.0) = 0.6;
uniform float fault : hint_range(0.0, 1.0) = 0.0;
uniform float motion = 1.0;
uniform float flicker = 0.0;
uniform float power = 1.0;
uniform float beam = 1.0;
uniform float outcome = 0.0;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float edge_mask(vec2 p) {
	float distance_to_edge = 1.0;
	bool inside = false;
	for (int i=0; i<21; i++) {
		vec2 a = contour[i]; vec2 b = contour[(i+1)%21]; vec2 ab = b-a;
		float h = clamp(dot(p-a,ab)/max(dot(ab,ab),0.000001),0.0,1.0);
		distance_to_edge = min(distance_to_edge,length(p-a-h*ab));
		if ((a.y>p.y)!=(b.y>p.y)) {
			if (p.x < (b.x-a.x)*(p.y-a.y)/(b.y-a.y)+a.x) { inside = !inside; }
		}
	}
	return inside ? smoothstep(0.0,0.0032,distance_to_edge) : 0.0;
}
float ordered_dither(vec2 pixel) {
	vec2 k = mod(floor(pixel),2.0);
	return (k.x*2.0+k.y*3.0-4.0*k.x*k.y)/4.0-0.375;
}
void fragment() {
	vec2 p = UV*2.0-1.0;
	vec2 uv = (p*(1.0+curvature*dot(p,p))+1.0)*0.5;
	float inside = step(0.0,uv.x)*step(uv.x,1.0)*step(0.0,uv.y)*step(uv.y,1.0);
	vec2 q = clamp(uv,vec2(0.0),vec2(1.0));
	vec3 base = texture(TEXTURE,q).rgb;
	float t = TIME*motion;
	float split = 0.0012*strength;
	vec3 halo = texture(TEXTURE,clamp(q+vec2(split,0.0),vec2(0.0),vec2(1.0))).rgb;
	vec3 ghost = texture(TEXTURE,clamp(q-vec2(split*2.0,0.0),vec2(0.0),vec2(1.0))).rgb;
	vec2 dy = vec2(0.0,2.0/962.0);
	vec3 vertical_halo = texture(TEXTURE,clamp(q+dy,vec2(0.0),vec2(1.0))).rgb + texture(TEXTURE,clamp(q-dy,vec2(0.0),vec2(1.0))).rgb;
	vec3 bloom = max((halo+ghost+vertical_halo)*0.25-base,vec3(0.0));
	vec3 rgb = base + bloom*0.32*strength + base*0.035*strength;
	rgb += vec3(halo.r-base.r,0.0,ghost.b-base.b)*0.18*strength;
	float scan = 0.92+0.08*cos(UV.y*481.0*3.14159265);
	rgb *= mix(1.0,scan,strength);
	float noise = hash(floor(UV*vec2(713.0,481.0))+floor(t*24.0))-0.5;
	float tear = step(0.985,hash(vec2(floor(UV.y*35.0),floor(t*7.0))))*fault*motion;
	// Tearing/glitch is additive: never displaces the clickable primary image.
	rgb += vec3(0.01,0.08,0.035)*tear*strength;
	float dither = ordered_dither(UV*vec2(713.0,481.0));
	rgb += (noise*0.015+dither*0.012)*strength + vec3(0.045,0.006,0.004)*fault*strength;
	rgb *= 1.0-strength*0.12*dot(p,p)*0.5;
	rgb *= 1.0-flicker*motion*strength*0.018*(0.5+0.5*sin(t*13.0));
	rgb += vec3(0.006,0.016,0.009)*strength*max(0.0,1.0-dot(p,p)*0.45);
	vec3 outcome_tint = outcome > 0.0 ? vec3(0.015,0.07,0.025) : vec3(0.09,0.015,0.008);
	rgb += outcome_tint*abs(outcome)*strength;
	float beam_mask = 1.0-smoothstep(max(0.0,beam-0.012),beam+0.012,abs(p.y));
	float line_glow = exp(-abs(p.y)*90.0)*(1.0-beam)*power;
	rgb = mix(vec3(0.012,0.025,0.017),rgb,inside*power*beam_mask);
	rgb += vec3(0.15,0.38,0.17)*line_glow;
	COLOR = vec4(rgb,edge_mask(UV));
}
