shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float strength : hint_range(0.0,1.0) = 0.0;
uniform float motion = 1.0;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float bayer(vec2 p) {
	vec2 q=mod(floor(p),2.0);
	return (q.x*2.0+q.y*3.0-4.0*q.x*q.y)/4.0-0.375;
}
void fragment() {
	vec3 original=texture(screen_texture,SCREEN_UV).rgb;
	vec2 pixel=floor(SCREEN_UV*vec2(1672.0,941.0));
	vec3 graded=floor(clamp(original+bayer(pixel)/48.0,0.0,1.0)*48.0+0.5)/48.0;
	graded += (hash(pixel+floor(TIME*12.0)*motion)-0.5)*0.015;
	vec2 p=SCREEN_UV*2.0-1.0;
	graded *= (1.0-0.07*dot(p,p))*vec3(0.99,1.0,0.985);
	COLOR=vec4(mix(original,graded,strength),1.0);
}
