shader_type canvas_item;
render_mode unshaded;
uniform vec2 contour[21];
uniform float screen_power = 1.0;
uniform float screen_beam = 1.0;
uniform float line_strength = 0.0;
bool inside_crt(vec2 p) {
	bool inside = false;
	for (int i=0; i<21; i++) {
		vec2 a=contour[i]; vec2 b=contour[(i+1)%21];
		if ((a.y>p.y)!=(b.y>p.y)) {
			if (p.x<(b.x-a.x)*(p.y-a.y)/(b.y-a.y)+a.x) { inside=!inside; }
		}
	}
	return inside;
}
void fragment() {
	float y=abs(UV.y*2.0-1.0);
	float opening=screen_beam>=0.999 ? 1.0 : 1.0-smoothstep(max(0.0,screen_beam-0.003),screen_beam+0.003,y);
	float opacity=1.0-screen_power*opening;
	// A narrow phosphor line, never a full-screen flash.
	float line=exp(-y*180.0)*line_strength;
	COLOR=vec4(vec3(0.002,0.006,0.003)+vec3(0.20,0.55,0.22)*line,inside_crt(UV)?max(opacity,line):0.0);
}
