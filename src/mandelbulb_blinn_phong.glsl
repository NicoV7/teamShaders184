#define PI 3.141592653589793238
float mandelbulb_SDF ( in vec3 pos )
{
    float n = 8.; // tune this number for different order mandelbulbs
    n = 8. + (2. * sin(iTime / 2.));
    
    // 2 is a good enough threshold
    float thresh = 2.;
    
    vec3 z = pos;
    float r = 0.0; // r is used outside scope of for loop, so declaration is outside
    float dr = 1.0; // not sure if initial value should be 0 or 1
    float max_iterations = 10.;

    // https://en.wikipedia.org/wiki/Mandelbulb
    for (float i = 0.0; i < max_iterations; i++)
    {
        r = length(z); 
        if (r > thresh) {break;} // unstable, so not in mandelbulb
        
        float p = atan(z.y, z.x); // phi (shortened name for shorter code)
        float t = acos(z.z / r); // theta (shortened name for shorter code)
        // mandelbrot function is (z_i)^n + z_i
        // derivative of this is: n * (z_i)^(n-1) * dz_i + 1
        dr = 1.0 + n * pow(r, n - 1.) * dr;
        
        // need to use Nylander's formula to get this iteration's contribution
        // v^n := r^n <sin(n * theta)cos(n * phi), sin(n * theta)sin(n * phi), cos(n * theta)
        vec3 z_n = vec3(sin(n * t) * cos(n * p), sin(n * t) * sin(n * p), cos(n * t));
        z_n *= pow(r, n);
        z = z_n + pos;
    }
    // https://iquilezles.org/articles/distancefractals/
    return 0.5 * (r * log(r)) / dr;   
}

//https://en.wikipedia.org/wiki/HSL_and_HSV#HSV_to_RGB
//helpful: https://en.wikipedia.org/wiki/File:RGB_2_HSV_conversion_with_grid.ogg
vec3 hsv2rgb(vec3 hsv) {
    float H = hsv.x; // Hue angle in degrees
    float S = hsv.y; // Saturation [0, 1]
    float V = hsv.z; // Value [0, 1]

    float C = V * S; // Chroma
    float H_prime = H / 60.0; // Sector of color wheel
    float X = C * (1.0 - abs(mod(H_prime, 2.0) - 1.0)); // Intermediate value

    // RGB calculation based on the sector determined by H_prime
    vec3 rgb = vec3(0.0); // Initialize RGB with 0
    if (0.0 <= H_prime && H_prime < 1.0) {
        rgb = vec3(C, X, 0.0);
    } else if (1.0 <= H_prime && H_prime < 2.0) {
        rgb = vec3(X, C, 0.0);
    } else if (2.0 <= H_prime && H_prime < 3.0) {
        rgb = vec3(0.0, C, X);
    } else if (3.0 <= H_prime && H_prime < 4.0) {
        rgb = vec3(0.0, X, C);
    } else if (4.0 <= H_prime && H_prime < 5.0) {
        rgb = vec3(X, 0.0, C);
    } else if (5.0 <= H_prime && H_prime < 6.0) {
        rgb = vec3(C, 0.0, X);
    }

    float m = V - C; // Value adjustment factor
    return rgb + vec3(m); // Adjust RGB to match the value
}

mat2 rot2D (float angle) {
  float s = sin (angle);
  float c = cos (angle);

  return mat2 (c, -s, s, c);
}

vec3 calculateNormal(vec3 p) {
    const float h = 0.01; // offset
    
    float d = mandelbulb_SDF(p); 
    float nx = mandelbulb_SDF(p + vec3(h, 0.0, 0.0)) - d;
    float ny = mandelbulb_SDF(p + vec3(0.0, h, 0.0)) - d;
    float nz = mandelbulb_SDF(p + vec3(0.0, 0.0, h)) - d;

    return normalize(vec3(nx, ny, nz));
}

// o and d are the origin and direction of the ray
// min_t and max_t tell us the valid range of t values for our ray
// min_thresh is the threshold which distance must be under to be considered a ray hit
// max_thresh is the threshold which distance must be over to be considered a ray miss

vec3 raymarch(in vec3 o, in vec3 d, in float min_t, in float max_t, in float min_thresh, in float max_thresh)
{
    float t = min_t;
    float max_iterations = 150.;
    float steps = 0.;
    vec3 color = vec3(0.0);
    for (float i = 0.; i < max_iterations; i++) 
    {
        steps++;
        vec3 curr = o + t * d;
        float dst = mandelbulb_SDF(curr);
        t += dst;
        if (dst < min_thresh)
        {
            vec3 p = curr; 
            vec3 n = calculateNormal(p);
            vec3 lightpos = vec3(1.0, 1.0, 1.0);
            vec3 campos = vec3(1.0, 1.0, 1.0);
            vec3 l = normalize(lightpos - p);
            vec3 v = normalize(campos - p);
            vec3 h = normalize(v + l);
            vec3 r = lightpos - p;
            
            float diff = max(0.0, dot(n, l));
            float sth = max(dot(n, h), 0.0);
            float spec = pow(sth, 100.);
            
            vec3 ambient = vec3(0.1,0.1,0.1) * vec3(1,1,1);
            vec3 diffuse = vec3(0.8,0.8,0.8) * diff * (vec3(1.0, 1.0, 1.0) / (length(r) * length(r)));
            vec3 specular = vec3(0.5,0.5,0.5) * spec * (vec3(1.0, 1.0, 1.0) / (length(r) * length(r)));
            
            
            color = mix(vec3(0.1, 0, 0.2), vec3(0.322,1.000,0.647) * (ambient + diffuse + specular), diffuse); 
            break;
        } else if (dst > max_thresh) {
            color = mix(vec3(0.816,0.545,0.639), vec3(0.925,0.682,0.957), 0.01);
            break;
        }
    }

    if (steps > max_iterations)
    {
        color = vec3(1.000,1.000,1.000);
    }
    
    return color;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from -1 to 1) + corrects for aspect ratio
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    uv *= 1.5; // coords now go from (-1.5 to 1.5)
    vec2 m = (iMouse.xy * 2. - iResolution.xy) / iResolution.y;
    m *= 1.5;

    vec3 ro = vec3 (0, 0, -2); // Ray origin
    // make a c2w matrix:
    // https://cs184.eecs.berkeley.edu/sp24/lecture/4-68/transforms
    vec3 up = vec3(0, 1., 0);
    vec3 view = vec3(0, 0, 1.); // looking straight ahead
    vec3 right = normalize(cross(up, view)); // right is perpendicular to both view and up dirs
    
    mat3 c2w = mat3(right, up, view);
    
    vec3 d = normalize((c2w * vec3(uv, -1)) - ro);
    
    // https://youtu.be/khblXafu7iA?si=ZsqbVRlyASmSA6I-&t=1404
    ro.yz *= rot2D(-m.y);
    d.yz *= rot2D(-m.y);
    
    ro.xz *= rot2D(-m.x);
    d.xz *= rot2D(-m.x);
    float min_t = .1;
    float max_t = 100.;
    float min_thresh = .001;
    float max_thresh = 100.;
    
    // raymarch
    vec3 col = raymarch(ro, d, min_t, max_t, min_thresh, max_thresh);

    // Output to screen
    fragColor = vec4(col,1.0);
}