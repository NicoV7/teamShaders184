//https://complex-analysis.com/content/mandelbrot_set.html
vec3 mandelbrot_col( in vec2 z0 ) 
{
   // z0 = (x0, y0)
   // our point is x0 + y0i
   float thresh = pow(10., 8.);
   
   
   vec2 z = vec2(0.0);
   float i = 0.;
   float max_iterations = 8000.;
   while (i < max_iterations) 
   {
       // z^2 = (x + yi)(x + yi) = x^2 - y^2 + 2xyi
       z = vec2(z.x * z.x - z.y * z.y, 2. * z.x * z.y) + z0;
       // magnitude of z = sqrt(x^2 + y^2)
       if (sqrt(z.x * z.x + z.y * z.y) > thresh) {break;}
       i++;
   }
   
   if (i == max_iterations) // in mandelbrot set
   {
       return vec3(0.0); // black 
   } else 
   {
       vec3 col_far = vec3(0.0, 0.0, 255.); // color for stuff far from mandelbrot (blue far)
       vec3 col_close = vec3(255., 110., 0.0); // color for stuff close to the mandelbrot (orange close)
       
       // base color off number of iterations since
       // more instability = farther from mandelbrot set
       // the value explodes and hits the threshold faster -> fewer iterations
       
       // mix function just does a lerp:
       // https://registry.khronos.org/OpenGL-Refpages/gl4/html/mix.xhtml
       return mix(col_far, col_close, i / max_iterations);
   }
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from -2 to 2) + corrects for aspect ratio
    vec2 uv = 2. * (fragCoord * 2.0 - iResolution.xy) / iResolution.y;
    // shift uv to the left a little bit to center fractal
    uv = vec2(uv.x - .5, uv.y);
    
    // zoom: https://www.shadertoy.com/view/td3GRB
    vec2 center = vec2(-0.45, 0.6);
    uv = center + (uv-center) / (iTime + 1.);
    
    
    // Rotation stuff
    //float angle = iTime; 
    //uv = vec2 ( 
    //    uv.x * cos(angle) - uv.y * sin(angle),
    //    uv.x * sin(angle) + uv.y * sin(angle)
    //); 
    
    // Output to screen
    fragColor = vec4(mandelbrot_col(uv), 1.0);
}