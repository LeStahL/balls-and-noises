/*
 * Balls and Noises
 * Copyright (C) 2023  Alexander Kraus <nr4@z10.info>
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#version 450

uniform int smp;

vec3 x;
vec2 R = vec2(1920, 1080),
    c = vec2(1,0);
float d = 0,
    s = dot(gl_FragCoord.xy, vec2(1, R.x)) / 44100,
    p = .002 * smp;
int i = 0,
    si = int(s);
out vec4 O;

vec2 saw2(float time, vec2 x) {
    return (
        .63 - .4 * acos((time - 1) * cos(x))
    ) * atan(sin(x) / time) * min(1, time * 50);
}

float scene(vec3 x) {
    x.z += 1;
    x.xy *= mat2(cos(p), sin(p), -sin(p), cos(p));
    return length(abs(abs(x)-.2)-.1)-.05;
}

void main()
{
    // Music
    // O = c.yyyx; // !! This is undefined behavior and does not need to be correct.
    // Definitely test this on the compo hardware!
    for(; i < 5; ++i) // Loop upper limit: Note count.
        O.xy +=
            // Synthesizer
            saw2(
                min(
                    mod(s, .25) * (2. + cos(s)),
                    .7 + cos(s / 4) * .3
                ),
                vec2(i * .01 + s)
                // Sequencer
                * 220 * exp2(
                    int[] (
                        (si / 2 % 2) * 2,
                        (si     % 2) * 2 + 12,
                        (si / 2 % 2) * 2 + 16,
                        (si     % 2) * 2 + 21,
                        (si / 2 % 2) * 2 + 5
                    ) [i] / 12.
                )
            )
            // Equalizer
            * int[] (5, 3, 4, 2, 3) [i] * .06; // that .2 is 1./float(notes.length())., and it has a .3 factor for the equalizer
    
    // Graphics
    for(; i<200; ++i)
        d += s = scene(x = d * vec3(gl_FragCoord.xy/R-.5,-1));

    if(smp > 0)
        if(s < .01)
            O.xyz = vec3(.3 + .4 * dot(
                c.xxx,
                normalize(vec3(
                    scene(x+.01*c.xyy),
                    scene(x+.01*c.yxy),
                    scene(x+.01*c.yyx)
                ) - s)
            ));
}
