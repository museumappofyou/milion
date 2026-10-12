#version 460 core
#include <flutter/runtime_effect.glsl>

// Milion LU look-up pass: a photograph taken straight up into a dome, mapped
// back overhead. Each screen pixel is a view ray; its elevation and azimuth
// index the photograph as an ordinary (rectilinear) lens pointed at the
// zenith: distance from uCenter (the crown) grows with tan(zenith angle), and
// the rim, the ellipse uRimCenter / uRimRadii (image-width units), is seen at
// uRim radians above the horizon. The pixels are the photograph's own; only
// the camera moves (DEPTH).
//
// World frame: Z up. The photograph's top is +Y, its right is -X (a camera
// looking up with its top to +Y has -X on its right).
// Uniform order must match lib/plate/look_up.dart.

precision highp float;

uniform vec2 uSize;      // 0-1   viewport in local canvas units
uniform vec3 uForward;   // 2-4   view direction
uniform vec3 uUp;        // 5-7   screen up
uniform vec3 uRight;     // 8-10  screen right
uniform float uTanHalf;  // 11    tan(vertical fov / 2)
uniform vec2 uCenter;    // 12-13 the crown (zenith) in image uv
uniform vec2 uRimCenter; // 14-15 rim ellipse centre in image uv
uniform vec2 uRimRadii;  // 16-17 rim semi-axes, fractions of image width
uniform float uRim;      // 18    rim elevation, radians
uniform vec2 uImageSize; // 19-20
uniform float uGilded;   // 21    0 or 1: gold catches the light you face
uniform sampler2D uTexture;
uniform sampler2D uSurface;
uniform sampler2D uGold;

out vec4 fragColor;

const float HALF_PI = 1.5707963;
const vec3 GOLD = vec3(0.79, 0.63, 0.30);
const vec3 LAMP = vec3(0.082, 0.075, 0.078);

void main() {
  vec2 fc = FlutterFragCoord().xy;
  vec2 s = (fc - 0.5 * uSize) / (0.5 * uSize.y) * vec2(1.0, -1.0);
  vec3 ray = normalize(uForward + s.x * uTanHalf * uRight + s.y * uTanHalf * uUp);
  float elevation = asin(clamp(ray.z, -1.0, 1.0));
  vec2 h = ray.xy;
  float hl = length(h);
  vec2 dir = hl > 1e-5 ? -h / hl : vec2(0.0);
  if (elevation < 0.05) {
    fragColor = vec4(LAMP, 1.0);
    return;
  }
  // Distance from the crown to the rim along dir (width units), solving
  // |crown + s dir - rimCenter| = 1 in ellipse units for s > 0.
  float aspect = uImageSize.x / uImageSize.y;
  vec2 p = (uCenter - uRimCenter) * vec2(1.0, 1.0 / aspect) / uRimRadii;
  vec2 d = dir / uRimRadii;
  float qa = dot(d, d), qb = 2.0 * dot(p, d), qc = dot(p, p) - 1.0;
  float rim = (-qb + sqrt(max(qb * qb - 4.0 * qa * qc, 0.0))) / (2.0 * qa);
  float r = tan(HALF_PI - elevation) / tan(HALF_PI - uRim) * rim;
  // Image offsets: right is +u, down is +v; up in the photograph is +Y.
  vec2 uv = uCenter + vec2(dir.x * r, dir.y * r * aspect);
  if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
    fragColor = vec4(LAMP, 1.0);
    return;
  }
  vec3 color = texture(uTexture, uv).rgb;
  if (uGilded > 0.5) {
    vec3 n = texture(uSurface, uv).rgb * 2.0 - 1.0;
    vec3 L = normalize(vec3(-s.x * 0.6, s.y * 0.6, 1.0));
    float spec = pow(clamp(dot(n, normalize(L + vec3(0.0, 0.0, 1.0))), 0.0, 1.0), 36.0);
    color += GOLD * spec * texture(uGold, uv).r * 2.2;
  }
  // Fade to lamp black at the edge of what was photographed.
  vec2 edge = min(uv, 1.0 - uv);
  float fade = smoothstep(0.0, 0.025, min(edge.x, edge.y));
  fragColor = vec4(mix(LAMP, color, fade), 1.0);
}
