-- Common components for shaders

local basic = {}

basic.defaultVertex = [[
    vec4 position(mat4 projection, mat4 transform, vec4 vertex) {
        return projection * transform * vertex;
    }
]]

basic.defaultFragment = [[
    vec4 color(vec4 graphicsColor, sampler2D image, vec2 uv) {
        return graphicsColor * lovrDiffuseColor * vertexColor * texture(image, uv);
    }
]]

basic.screenVertex = [[
    vec4 position(mat4 projection, mat4 transform, vec4 vertex) {
        return vertex;
    }
]]

basic.skyboxVertex = [[
    out vec3 texturePosition[2];
    vec4 position(mat4 projection, mat4 transform, vec4 vertex) {
        texturePosition[lovrViewID] = inverse(mat3(transform)) * (inverse(projection) * vertex).xyz;
        return vertex;
    }
]]

return basic