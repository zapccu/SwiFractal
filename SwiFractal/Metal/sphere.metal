//
//  sphere.metal
//  SwiFractal
//
//  Created by Dirk Braner on 24.08.26.
//


#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

[[ stitchable ]]
half4 planetEffect(float2 position, SwiftUI::Layer layer, float2 size,
                    float strength, float angle, float elevation) {
    float2 center = size * 0.5;
    float radius = min(size.x, size.y) * 0.5;
    float2 delta = position - center;
    float dist = length(delta);

    if (dist >= radius) {
        return half4(0.0);
    }

    float normDist = dist / radius;
    float theta = asin(clamp(normDist, 0.0, 1.0));
    float phi = atan2(delta.y, delta.x);

    float newNormDist = mix(normDist, theta / (M_PI_F * 0.5), strength);
    float2 direction = dist > 0.0001 ? delta / dist : float2(0.0);
    float2 samplePos = center + direction * newNormDist * radius;

    half4 color = layer.sample(samplePos);

    // Kugel-Normale aus Projektionsgeometrie
    float3 N = float3(sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta));

    // Lichtvektor aus denselben Parametern wie beim bestehenden Blinn-Phong
    float3 L = normalize(float3(cos(elevation) * cos(angle),
                                 cos(elevation) * sin(angle),
                                 sin(elevation)));
    float3 V = float3(0.0, 0.0, 1.0); // orthografischer Betrachter
    float3 H = normalize(L + V);

    float diffuse = max(dot(N, L), 0.0);
    float specular = pow(max(dot(N, H), 0.0), 32.0);

    float shade = mix(1.0, 0.1 + 0.9 * diffuse, strength);
    color.rgb *= shade;
    color.rgb += half3(specular * 0.3) * strength;

    return color;
}
