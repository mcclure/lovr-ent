-- Common components for shaders

local basic = {}

basic.defaultVertex = [[
	vec4 position(mat4 projection, mat4 transform, vec4 vertex) {
		return lovrProjection * lovrTransform * lovrVertex;
	}
]]

basic.defaultFragment = [[
	vec4 color(vec4 graphicsColor, sampler2D image, vec2 uv) {
		return lovrGraphicsColor * lovrVertexColor * lovrDiffuseColor * texture(lovrDiffuseTexture, lovrTexCoord);
	}
]]

basic.screenVertex = [[
	vec4 position(mat4 projection, mat4 transform, vec4 vertex) {
		return lovrVertex;
	}
]]

basic.skyboxVertex = [[
	out vec3 texturePosition[2];
	vec4 position(mat4 projection, mat4 transform, vec4 vertex) {
		texturePosition[lovrViewID] = inverse(mat3(lovrTransform)) * (inverse(lovrProjection) * lovrVertex).xyz;
		return lovrVertex;
	}
]]

return basic