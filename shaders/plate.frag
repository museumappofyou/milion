#version 460 core
#include <flutter/runtime_effect.glsl>

// Milion plate pass. One shader composes a light with an effect, so masked
// effects are lit exactly like the plate around them.
//
// uLight  : 0 none, 1 gilded (specular gold follows the tilt),
//           2 raking (a draggable grazing light),
//           3 candle (a warm point light under the finger, flicker < 3 Hz)
// uEffect : 0 the whole plate (+ depth parallax; uMask = gold coverage)
//           1 flow: two-phase flow-map UV scrolling inside the mask
//           2 spiral: a UV twist inside the mask (never a body warp)
//           3 wipe: reconstruction only where damage and the wipe intersect
//
// uTexture : the layer being shown (original / depth / reconstruction)
// uSurface : RGB = normal map (0..1), A = height (0..1)
// uMask    : R = coverage; GB = flow direction (0.5 + dir * 0.5) for flow
//
// The painter draws this only inside the fitted frame rect and passes uFrame
// (left, top, width, height in local canvas units), so uv maps to the frame.
// Uniform order must match lib/plate/painter.dart.

precision highp float;

uniform vec4 uFrame;     // 0-3
uniform vec2 uImageSize; // 4-5
uniform float uLight;    // 6
uniform float uEffect;   // 7
uniform float uTime;     // 8
uniform vec2 uTilt;      // 9-10  (normalized, -1..1)
uniform vec2 uPoint;     // 11-12 (raking direction, candle position, wipe x)
uniform float uAmount;   // 13    (light strength / wipe amount)
uniform vec2 uFlow;      // 14-15 (flow: period s, distance; spiral: twist)
uniform vec2 uCenter;    // 16-17 (spiral pivot in uv space)
uniform float uDepth;    // 18    (parallax depth scale)
uniform sampler2D uTexture;
uniform sampler2D uSurface;
uniform sampler2D uMask;

out vec4 fragColor;

const vec3 GOLD = vec3(0.79, 0.63, 0.30);
const float TAU = 6.2831853;

vec3 lit(vec3 base, vec3 n, float gold, vec2 uv) {
  if (uLight < 0.5) return base;
  vec2 t = clamp(uTilt, vec2(-1.0), vec2(1.0));
  vec3 L = normalize(vec3(-t.x * 0.85, t.y * 0.85, 1.0));
  float ndl = clamp(dot(n, L), 0.0, 1.0);
  if (uLight < 1.5) {
    // Gilded: only the gold tesserae catch the light as the phone tilts.
    vec3 H = normalize(L + vec3(0.0, 0.0, 1.0));
    float spec = pow(clamp(dot(n, H), 0.0, 1.0), 42.0);
    return base * (0.92 + 0.08 * ndl) + GOLD * spec * gold * 2.6 * uAmount;
  }
  if (uLight < 2.5) {
    vec2 d = normalize(uPoint + vec2(0.0001));
    vec3 RL = normalize(vec3(-d.x, d.y, 0.45));
    float lift = 0.35 + 0.65 * clamp(dot(n, RL), 0.0, 1.0);
    return base * mix(1.0, lift, uAmount);
  }
  float flicker = 1.0 +
      0.12 * sin(uTime * TAU * 2.3) +
      0.06 * sin(uTime * TAU * 0.9 + 1.7);
  vec2 p = uv - uPoint;
  p.x *= uImageSize.x / uImageSize.y;
  float fall = exp(-dot(p, p) / (0.36 * 0.36)) * flicker;
  return base * (0.22 + 0.30 * ndl) +
      vec3(1.0, 0.72, 0.38) * clamp(fall, 0.0, 1.6) * (0.45 + 0.55 * ndl) *
          uAmount;
}

void main() {
  vec2 uv = (FlutterFragCoord().xy - uFrame.xy) / uFrame.zw;
  vec4 surface = texture(uSurface, uv);
  vec2 parallax = uTilt * (surface.a - 0.5) * uDepth;
  vec4 mask = texture(uMask, uv);

  if (uEffect > 2.5) {
    float wipe = 1.0 - smoothstep(uPoint.x - 0.006, uPoint.x + 0.006, uv.x);
    float alpha = clamp(mask.r * wipe * uAmount, 0.0, 1.0);
    fragColor = vec4(texture(uTexture, uv).rgb * alpha, alpha);
    return;
  }

  vec3 n = surface.rgb * 2.0 - 1.0;
  if (uEffect < 0.5) {
    vec3 base = texture(uTexture, uv + parallax).rgb;
    fragColor = vec4(lit(base, n, mask.r, uv), 1.0);
    return;
  }

  vec3 base;
  float alpha;
  if (uEffect < 1.5) {
    // Two samples half a period apart, crossfaded, so the flow never snaps.
    vec2 dir = (mask.gb * 2.0 - 1.0) * uFlow.y * mask.r;
    float p0 = fract(uTime / uFlow.x);
    float p1 = fract(uTime / uFlow.x + 0.5);
    vec3 a = texture(uTexture, uv + parallax - dir * p0).rgb;
    vec3 b = texture(uTexture, uv + parallax - dir * p1).rgb;
    base = mix(a, b, abs(1.0 - 2.0 * p0));
    alpha = smoothstep(0.0, 0.35, mask.r);
  } else {
    vec2 p = uv - uCenter;
    p.x *= uImageSize.x / uImageSize.y;
    float r = length(p);
    alpha = smoothstep(0.0, 0.25, mask.r);
    float twist = uFlow.x * (0.55 - clamp(r / 0.35, 0.0, 1.0)) * alpha;
    float ca = cos(twist), sa = sin(twist);
    vec2 q = mat2(ca, -sa, sa, ca) * p;
    q.x /= uImageSize.x / uImageSize.y;
    base = texture(uTexture, uCenter + q + parallax).rgb;
  }
  // Masked passes must not overwrite another pass outside their coverage.
  fragColor = vec4(lit(base, n, 0.0, uv) * alpha, alpha);
}
