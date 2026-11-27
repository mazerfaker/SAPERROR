shader_type canvas_item;
render_mode unshaded;
uniform vec2 contour[21];
uniform float glass = 1.0;
uniform float bulge = 0.04;
uniform float signal_fault = 0.0;
uniform float scan_wave = -1.0;
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
// Fixed approved glass geometry, independent of CRT post-processing strength.
float bayer4(vec2 pixel) {
	vec2 p = mod(floor(pixel),4.0);
	vec2 low = mod(p,2.0);
	vec2 high = floor(p*0.5);
	float a = low.x*2.0+low.y*3.0-4.0*low.x*low.y;
	float b = high.x*2.0+high.y*3.0-4.0*high.x*high.y;
	return (4.0*a+b+0.5)/16.0-0.5;
}
float periodic_mask(float coord, float period) {
	float phase = coord/period;
	float width = max(fwidth(phase),0.0001);
	float resolved = 1.0-smoothstep(0.32,0.70,width);
	return cos(phase*6.2831853)*resolved;
}

void fragment() {
	vec2 p = UV*2.0-1.0;
	float r2 = dot(p,p);
	// Match Geometry.warp() exactly. Bulge never depends on strength.
	vec2 q = (p*(1.0+bulge*r2)/(1.0+2.0*bulge)+1.0)*0.5;
	vec3 base = texture(TEXTURE,q).rgb;
	vec3 rgb = base;
	vec2 pixel = UV*vec2(713.0,481.0);
	float t = TIME*motion;
	if (strength > 0.0001) {
		vec2 px = vec2(1.0/1426.0,1.0/962.0);
		vec3 near_halo = (
			texture(TEXTURE,clamp(q+vec2(px.x*2.0,0.0),vec2(0.0),vec2(1.0))).rgb+
			texture(TEXTURE,clamp(q-vec2(px.x*2.0,0.0),vec2(0.0),vec2(1.0))).rgb+
			texture(TEXTURE,clamp(q+vec2(0.0,px.y*2.0),vec2(0.0),vec2(1.0))).rgb+
			texture(TEXTURE,clamp(q-vec2(0.0,px.y*2.0),vec2(0.0),vec2(1.0))).rgb)*0.25;
		vec3 far_halo = (
			texture(TEXTURE,clamp(q+px*vec2(5.0,4.0),vec2(0.0),vec2(1.0))).rgb+
			texture(TEXTURE,clamp(q+px*vec2(-5.0,4.0),vec2(0.0),vec2(1.0))).rgb+
			texture(TEXTURE,clamp(q+px*vec2(5.0,-4.0),vec2(0.0),vec2(1.0))).rgb+
			texture(TEXTURE,clamp(q-px*vec2(5.0,4.0),vec2(0.0),vec2(1.0))).rgb)*0.25;
		// Color-preserving bloom; red and amber warnings remain distinct.
		vec3 glow = max(near_halo-base,vec3(0.0))*0.48 + max(far_halo-base,vec3(0.0))*0.26;
		vec3 graded = base*1.08+glow;
		float scan = 0.82+0.18*periodic_mask(pixel.y,3.0);
		float grille = 0.95+0.05*periodic_mask(pixel.x,3.0);
		graded *= scan*grille;
		float vignette = 1.0-glass*0.20*smoothstep(0.12,1.8,r2);
		graded *= vignette;
		// Coarse phosphor quantization / ordered dither, not animated white noise.
		float dither = bayer4(pixel);
		graded = floor(clamp(graded+dither/64.0,0.0,1.0)*64.0+0.5)/64.0;
		float grain = hash(floor(pixel)+floor(t*18.0))-0.5;
		graded += grain*0.012;
		// Soft glass reflection and black-level lift; no changes to approved art.
		vec2 reflection_pos = (p+vec2(0.48,0.72))*vec2(0.85,2.5);
		float reflection = exp(-dot(reflection_pos,reflection_pos));
		graded += glass*vec3(0.009,0.025,0.015)*reflection;
		graded += glass*vec3(0.004,0.013,0.008)*(1.0-0.45*clamp(r2,0.0,1.0));
		float tear = step(0.96,hash(vec2(floor(pixel.y/4.0),floor(t*8.0))))*fault*motion;
		graded += vec3(0.07,0.025,0.012)*tear;
		graded += vec3(0.07,0.008,0.004)*fault;
		vec3 tint = outcome > 0.0 ? vec3(0.015,0.07,0.025) : vec3(0.09,0.015,0.008);
		graded += tint*abs(outcome);
		// Low-amplitude, irregular luminance drift; no full-screen strobe.
		float drift = 0.5+0.3*sin(t*3.2)+0.2*sin(t*8.7+sin(t*1.1));
		graded *= 1.0-flicker*motion*0.065*drift;
		// Brief additive signal error: localized tearing and channel bleed. Base geometry stays fixed.
		// Zero signal/motion contributed exactly zero in the original path.
		if (signal_fault != 0.0 && motion != 0.0) {
			float band_id = floor(pixel.y/5.0);
			float tick = floor(t*23.0);
			float band = step(0.78,hash(vec2(band_id,tick)))*signal_fault*motion;
			float jitter = (hash(vec2(band_id+18.0,tick))-0.5)*0.035*band;
			vec2 offset = vec2(jitter,0.0);
			vec3 shifted = texture(TEXTURE,clamp(q+offset,vec2(0.0),vec2(1.0))).rgb;
			float split = 0.0028*band;
			vec3 chroma = vec3(texture(TEXTURE,clamp(q+offset+vec2(split,0.0),vec2(0.0),vec2(1.0))).r,shifted.g,texture(TEXTURE,clamp(q+offset-vec2(split,0.0),vec2(0.0),vec2(1.0))).b);
			graded = mix(graded,chroma,band*0.48);
			graded += vec3(0.025,0.09,0.035)*band;
		}
		if (scan_wave >= 0.0) {
			float field = step(0.272,q.x)*step(q.x,0.728)*step(0.187,q.y)*step(q.y,0.82);
			float line = exp(-abs(q.y-(0.187+0.633*scan_wave))*85.0);
			graded += vec3(0.06,0.25,0.10)*line*field;
		}
		rgb = mix(base,graded,strength);
	}
	float beam_mask = beam>=0.999 ? 1.0 : 1.0-smoothstep(max(0.0,beam-0.012),beam+0.012,abs(p.y));
	float line_glow = exp(-abs(p.y)*90.0)*(1.0-beam)*power;
	rgb = mix(vec3(0.012,0.025,0.017),rgb,power*beam_mask);
	rgb += vec3(0.15,0.38,0.17)*line_glow;
	COLOR = vec4(clamp(rgb,0.0,1.0),edge_mask(UV));
}
