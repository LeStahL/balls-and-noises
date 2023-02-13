; Balls and Noises
; Copyright (C) 2023  Alexander Kraus <nr4@z10.info>
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <https://www.gnu.org/licenses/>.

%ifndef WIN32_INC
%define WIN32_INC

; PeekMessageA shiat
%define PM_REMOVE 0x1

; CreateWindowExA crap
%define WS_POPUP 0x80000000
%define WS_VISIBLE 0x10000000
%define WS_MAXIMIZE 0x01000000

; Window class
%define ATOM_STATIC 0xc019

; Key codes
%define VK_ESCAPE 0x1B

; Devmode shit
%define DM_PELSWIDTH 0x80000
%define DM_PELSHEIGHT 0x100000

; ChangeDisplaySettingsA shit
%define CDS_FULLSCREEN 0x4

; OpenGL shit
%define GL_FRAGMENT_SHADER 0x8B30
%define GL_FRAMEBUFFER 0x8D40
%define GL_REPEAT 0x2901
%define GL_CLAMP_TO_EDGE 0x812F
%define GL_LINEAR 0x2601
%define GL_NEAREST 0x2600
%define GL_TEXTURE_1D 0x0DE0
%define GL_TEXTURE_2D 0x0DE1
%define GL_TEXTURE_3D 0x806F
%define GL_RGBA32F 0x8814
%define GL_RGBA 0x1908
%define GL_FRAMEBUFFER 0x8D40
%define GL_TEXTURE_2D 0x0DE1
%define GL_FLOAT 0x1406
%define GL_RG32F 0x8230
%define GL_RG 0x8227
%define GL_COLOR_ATTACHMENT0 0x8CE0
%define GL_TEXTURE0 0x84C0
%define GL_TEXTURE_MAG_FILTER 0x2800
%define GL_TEXTURE_MIN_FILTER 0x2801
%define GL_CLAMP 0x2900
%define GL_TEXTURE_WRAP_S 0x2802
%define GL_TEXTURE_WRAP_T 0x2803
%define GL_UNSIGNED_BYTE 0x1401
%define GL_BGR 0x80E0
%define GL_UNSIGNED_INT 0x1405

; Pixelformat shit
%define PFD_TYPE_RGBA 0
%define PFD_DOUBLEBUFFER 0x1
%define PFD_DRAW_TO_WINDOW 0x4
%define PFD_SUPPORT_OPENGL 0x20

; Waveformat shit
%define WAVE_FORMAT_PCM 0x1
%define WAVE_FORMAT_IEEE_FLOAT 0x3
%define WHDR_PREPARED 0x2

; winmm shit
%define CALLBACK_NULL 0x0

; Synth shit
%define SAMPLE_RATE 44100
%define SAMPLE_SIZE 4

; MMTime shit
%define TIME_SAMPLES 0x2

; unclear where this pile of shit is from
%define WAVE_MAPPER 0xFFFFFFFF
%define WHDR_PREPARED 0x2

; Generic win32 crap
%define NULL 0

; File output crap
%define FILE_ATTRIBUTE_NORMAL 0x00000080
%define CREATE_ALWAYS 2
%define GENERIC_WRITE 0x40000000

%endif
