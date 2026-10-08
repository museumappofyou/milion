#version 460 core
#include <flutter/runtime_effect.glsl>

// Milion plate pass. One shader carries the plate's depth and light modes:
//   0 pass-through (+ depth parallax)
//   1 gilded: specular gold follows the gyroscope tilt
//   2 raking: a draggable grazing light
//   3 candle: a warm point light under the finger, flicker below 3 Hz
//   4 flow: flow-map UV scrolling inside the mask (micro-motion)
//   5 spiral: a UV twist inside the mask (the scroll of heaven)
//   6 wipe: reconstruction only where damage and the user's wipe intersect
//
// uTexture : the layer being shown (original / relief)
// uSurface : RGB = normal map (0..1), A = height (0..1)
// uMask    : R = coverage, GB = flow direction (0.5 + dir * 0.5) when used
//
// The painter draws this only inside the fitted frame rect and passes uFrame
// (left, top, width, height in local canvas units), so uv maps to the frame.
// Uniform order must match lib/plate/painter.dart.

precision highp float;

uniform vec4 uFrame;     // 4
uniform vec2 uImageSize; // 2
uniform float uMode;     // 1
uniform float uTime;     // 1
uniform vec2 uTilt;      // 2  (normalized, -1..1)
uniform vec2 uLight;     // 2  (direction or position in uv space)
uniform float uAmount;   // 1  (mode strength)
uniform float uFlow;     // 1  (flow speed / twist amount)
uniform vec2 uCenter;    // 2  (spiral / candle anchor in uv space)
uniform float uDepth;    // 1  (parallax depth scale)
uniform sampler2D uTexture;
uniform sampler2D uSurface;
uniform sampler2D uMask;

out vec4 fragColor;

const vec3 GOLD = vec3(0.79, 0.63, 0.30);

void main() {
  vec2 fc = FlutterFragCoord().xy;
  vec2 uv = (fc - uFrame.xy) / uFrame.zw;
  vec4 surface = texture(uSurface, uv);
  float height = surface.a;

  // Depth parallax: the tilt the gyroscope/drag supplies shifts tall paint.
  vec2 tc = uv + uTilt * (height - 0.5) * uDepth;
  vec3 base = texture(uTexture, tc).rgb;
  vec4 mask = texture(uMask, uv);

  if (uMode > 5.5) {
    float wipe = 1.0 - smoothstep(uLight.x - 0.006, uLight.x + 0.006, uv.x);
    float alpha = clamp(mask.r * wipe * uAmount, 0.0, 1.0);
    fragColor = vec4(base * alpha, alpha);
    return;
  }

  if (uMode < 0.5) {
    fragColor = vec4(base, 1.0);
    return;
  }

  vec3 n = surface.rgb * 2.0 - 1.0;
  vec2 t = clamp(uTilt, vec2(-1.0), vec2(1.0));
  vec3 L = normalize(vec3(-t.x * 0.85, t.y * 0.85, 1.0));
  vec3 V = vec3(0.0, 0.0, 1.0);
  float ndl = clamp(dot(n, L), 0.0, 1.0);

  if (uMode < 1.5) {
    // Gilded: gold tesserae catch the light as the phone tilts.
    vec3 H = normalize(L + V);
    float spec = pow(clamp(dot(n, H), 0.0, 1.0), 42.0);
    vec3 color = base * (uAmount * 0.45 + 0.55) + vec3(0.18 * ndl * uAmount);
    color += GOLD * spec * mask.r * 2.6 * uAmount;
    fragColor = vec4(color, 1.0);
    return;
  }

  if (uMode < 2.5) {
    // Raking: a grazing light dragged by the finger.
    vec2 d = normalize(uLight + vec2(0.0001));
    vec3 RL = normalize(vec3(-d.x, d.y, 0.45));
    float diff = clamp(dot(n, RL), 0.0, 1.0);
    float lift = 0.35 + 0.65 * diff;
    fragColor = vec4(base * mix(1.0, lift, uAmount), 1.0);
    return;
  }

  if (uMode < 3.5) {
    // Candle: a warm point light under the finger, flickering.
    float flicker = 1.0 +
        0.12 * sin(uTime * 6.2831 * 2.3) +
        0.06 * sin(uTime * 6.2831 * 0.9 + 1.7);
    vec2 p = uv - uLight;
    p.x *= uImageSize.x / uImageSize.y;
    float dist = length(p);
    float radius = 0.36;
    float fall = exp(-dist * dist / (radius * radius)) * flicker;
    float warm = clamp(fall, 0.0, 1.6);
    vec3 color = base * (0.22 + 0.30 * ndl) +
        vec3(1.0, 0.72, 0.38) * warm * (0.45 + 0.55 * ndl) * uAmount;
    fragColor = vec4(color, 1.0);
    return;
  }

  if (uMode < 4.5) {
    // Micro-motion: scroll the paint along the flow field inside the mask.
    vec2 dir = (mask.gb * 2.0 - 1.0);
    vec2 offset = dir * uFlow * fract(uTime / 8.0) * mask.r;
    vec3 flowColor = texture(uTexture, uv - offset + uTilt * (height - 0.5) * uDepth).rgb;
    float feather = smoothstep(0.0, 0.35, mask.r);
    // Masked passes must not overwrite another pass outside their coverage.
    fragColor = vec4(flowColor * feather, feather);
    return;
  }

  // Spiral: the scroll of heaven rolls inside its mask, never a body warp.
  vec2 p = uv - uCenter;
  p.x *= uImageSize.x / uImageSize.y;
  float r = length(p);
  float a = atan(p.y, p.x);
  float edge = smoothstep(0.0, 0.25, mask.r);
  float twist = uFlow * (0.55 - clamp(r / 0.35, 0.0, 1.0)) * edge;
  float ca = cos(twist), sa = sin(twist);
  vec2 q = mat2(ca, -sa, sa, ca) * p;
  q.x /= uImageSize.x / uImageSize.y;
  vec2 spiralUv = uCenter + q;
  vec3 spiralColor = texture(uTexture, spiralUv + uTilt * (height - 0.5) * uDepth).rgb;
  fragColor = vec4(spiralColor * edge, edge);
}
