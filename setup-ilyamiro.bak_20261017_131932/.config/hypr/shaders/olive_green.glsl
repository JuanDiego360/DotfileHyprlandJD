#version 300 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    vec3 color = pixColor.rgb;

    // Tinte Verde Oliva Suave (menos profundo/saturado)
    // Aumentamos Rojo (0.60 -> 0.85) y Azul (0.40 -> 0.75)
    // El Verde se mantiene en 1.0 para que sea el dominante, pero los otros están más cerca
    vec3 oliveTint = vec3(0.85, 1.0, 0.70);

    // Calculamos luminancia para preservar el contraste
    float lum = dot(color, vec3(0.2126, 0.7152, 0.0722));
    
    // Aplicamos el tinte
    vec3 filtered = color * oliveTint;

    // Aumentamos la mezcla con la luminancia original (0.10 -> 0.30)
    // Esto hace que el filtro sea más "ligero" y menos denso
    vec3 finalColor = mix(filtered, vec3(lum) * oliveTint, 0.30);

    fragColor = vec4(finalColor, pixColor.a);
}
