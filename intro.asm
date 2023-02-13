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

%include "win32.inc"

%ifdef VIDEO

%define VIDEO_FPS 60

section bmp_header data
bmp_header:
    db 'BM'
    dd bmp_header_end - bmp_header + 3 * WIDTH * HEIGHT ; File size
    dd 0 ; Reserved zero
    dd bmp_header_end - bmp_header ; Pixel data offset
meta_header:
    dd bmp_header_end - meta_header ; Metadata header size
    dd WIDTH
    dd HEIGHT
    dw 1 ; Number of layers
    dw 24 ; Bits per pixel
    dd 0 ; Compression level 0
    dd 3 * WIDTH * HEIGHT ; Size of pixel data
    times 2 dd 0x0EC4 ; X and y resolution are 75 dpi
    times 2 dd 0 ; Number of used and important colors
bmp_header_end:

section screenshot_pixels bss
screenshot_pixels:
    resd WIDTH * HEIGHT * 3

section screenshot_file data
screenshot_file:
    db "frames/00000000.bmp", 0

section screenshot_format data
screenshot_format:
    db "frames/%08d.bmp", 0

section music_file data
music_file:
    db "msx.raw", 0

section hfile bss:
hfile:
    resd 1

section bytes_written bss:
bytes_written:
    resd 1

section framecounter data:
framecounter:
    dd 0

%endif ; VIDEO

; Sample size is 4 for 32 bit floats.
%define SAMPLE_SIZE 4
; Sample rate is 44.1 kHz.
%define SAMPLE_RATE 44100
; Stereo.
%define CHANNEL_COUNT 2
; Track duration in seconds. This is ~94 seconds for full hd.
%define TRACK_DURATION WIDTH * HEIGHT * 2 / SAMPLE_SIZE / 44100
; Sample count of the track.
%define TRACK_SAMPLES WIDTH * HEIGHT * 2 / SAMPLE_SIZE

section soundbuffer bss
soundbuffer:
    resd WIDTH * HEIGHT

section hwaveout bss
hwaveout:
    resd 1

section shader data
%include "gfx.inc"

section pixelformat data
pixelformat:
    dw (pixelformat_end - pixelformat)
    dw 1
    dd PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER
    db PFD_TYPE_RGBA
    db 32
    times 6 db 0
    db 8
    times 3 dw 0
    db 32
    times 4 dd 0
pixelformat_end:

section glcreateshaderprogramv data
glcreateshaderprogramv:
    db "glCreateShaderProgramv", 0

section gluseprogram data
gluseprogram:
    db "glUseProgram", 0

section gluniform1i data
gluniform1i:
    db "glUniform1i", 0

%ifdef SHADER_MUSIC
section glgenframebuffers data
glgenframebuffers:
    db "glGenFramebuffers", 0

section glbindframebuffer data
glbindframebuffer:
    db "glBindFramebuffer", 0

section glframebuffertexture2d data
glframebuffertexture2d:
    db "glFramebufferTexture2D", 0
%endif ; SHADER_MUSIC

section sourceptr data
shadersource:
    dd _gfx_frag

%ifdef SANE_WINDOWPROC
section msg bss
msg:
    resd 8

section dispatch text
dispatch:
    push msg
    call _DispatchMessageA@4
    jmp dispatchloop

%endif

section wavefmt data
wavefmt:
    dw WAVE_FORMAT_IEEE_FLOAT
    dw 2
    dd SAMPLE_RATE
    dd SAMPLE_SIZE * SAMPLE_RATE * 2
    dw SAMPLE_SIZE * 2
    dw SAMPLE_SIZE * 8
    dw 0

section wavehdr data
wavehdr:
    dd soundbuffer
    dd TRACK_SAMPLES * SAMPLE_SIZE * 2
    times 2 dd 0
    dd WHDR_PREPARED
    times 4 dd 0
wavehdr_end:

%ifdef SHADER_MUSIC

section texture bss
texture:
    resd 1
%endif ; SHADER_MUSIC

section declarations text
%ifdef VIDEO
    extern _sprintf
    extern _ExitProcess@4
    extern _CreateFileA@28
    extern _WriteFile@20
    extern _CloseHandle@4
    extern _glReadPixels@28
%endif ; VIDEO
%ifdef EXIT_WITH_ESCAPE
    extern _GetAsyncKeyState@4
%endif ; EXIT_WITH_ESCAPE
    extern _CreateWindowExA@48
    extern _GetDC@4
    extern _ChoosePixelFormat@8
    extern _SetPixelFormat@12
    extern _wglCreateContext@4
    extern _wglMakeCurrent@8
    extern _SwapBuffers@4
    extern _wglGetProcAddress@4
    extern _glRecti@16
    extern _waveOutOpen@24
    extern _waveOutWrite@12
%ifdef SHADER_MUSIC
    extern _glGenTextures@8
    extern _glBindTexture@8
    extern _glTexImage2D@36
    extern _glGetTexImage@20
%endif ; SHADER_MUSIC
%ifdef SANE_WINDOWPROC
    extern _PeekMessageA@20
    extern _DispatchMessageA@4
%endif ; SANE_WINDOWPROC

section entry text
    global _mainCRTStartup
_WinMainCRTStartup:
    ; hwnd is in eax.
    times 8 push 0
    push WS_POPUP | WS_VISIBLE | WS_MAXIMIZE
    push 0
    push ATOM_STATIC
    push 0
    call _CreateWindowExA@48

    ; store HDC in ebp.
    push eax
    call _GetDC@4
    mov ebp, eax

    ; store chosen pixel format in eax
    push pixelformat
    push ebp
    call _ChoosePixelFormat@8

    ; Set pixel format from eax 
    push pixelformat
    push eax
    push ebp
	call _SetPixelFormat@12

    ; Create OpenGL context, store in eax
    push ebp
    call _wglCreateContext@4

    ; Make OpenGL context current.
    push eax
    push ebp
    call _wglMakeCurrent@8
    
    ; Create shader program, push result
    push glcreateshaderprogramv
    call _wglGetProcAddress@4

    push shadersource
    push 1
    push GL_FRAGMENT_SHADER
    call eax
    push eax

    ; Use shader program
    push gluseprogram
    call _wglGetProcAddress@4
    call eax

%ifdef SHADER_MUSIC
    ; glGenFramebuffers(1, &snd_framebuffer);
    push glgenframebuffers
    call _wglGetProcAddress@4

    push texture
    push 1
    call eax
 
    ; glBindFramebuffer(GL_FRAMEBUFFER, snd_framebuffer);
    push glbindframebuffer
    call _wglGetProcAddress@4
    mov dword [glbindframebuffer], eax
    push dword [texture]
    push GL_FRAMEBUFFER
    call eax

    ; glGenTextures(1, &snd_texture);
    push texture
    push 1
    call _glGenTextures@8

    ; glBindTexture(GL_TEXTURE_2D, snd_texture);
    push dword [texture]
    push GL_TEXTURE_2D
    call _glBindTexture@8

    ; glTexImage2D(GL_TEXTURE_2D, 0, GL_RG32F, WIDTH, HEIGHT, 0, GL_RG, GL_FLOAT, 0);
    push 0
    push GL_FLOAT
    push GL_RG
    push 0
    push HEIGHT
    push WIDTH
    push GL_RG32F
    push 0
    push GL_TEXTURE_2D
    call _glTexImage2D@36
    
    ; glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, snd_texture, 0);
    push glframebuffertexture2d
    call _wglGetProcAddress@4
    push 0
    push dword [texture]
    push GL_TEXTURE_2D
    push GL_COLOR_ATTACHMENT0
    push GL_FRAMEBUFFER
    call eax

    ; glRecti(-1, -1, 1, 1);
    times 2 push dword 1
    times 2 push dword -1
    call _glRecti@16

    ; glGetTexImage(GL_TEXTURE_2D, 0, GL_RG, GL_FLOAT, lpSoundBuffer);
    push soundbuffer
    push GL_FLOAT
    push GL_RG
    push 0
    push GL_TEXTURE_2D
    call _glGetTexImage@20

    ; glBindFramebuffer(GL_FRAMEBUFFER, 0);
    push 0
    push GL_FRAMEBUFFER
    call [glbindframebuffer]

%endif ; SHADER_MUSIC
%ifdef VIDEO
    ; Write sound to file
    push NULL
    push FILE_ATTRIBUTE_NORMAL
    push CREATE_ALWAYS
    push NULL
    push 0
    push GENERIC_WRITE
    push music_file
    call _CreateFileA@28
    mov dword [hfile], eax

    push NULL
    push bytes_written
    push WIDTH * HEIGHT * CHANNEL_COUNT * SAMPLE_SIZE
    push soundbuffer
    push dword [hfile]
    call _WriteFile@20
    
    push dword [hfile]
    call _CloseHandle@4

    mov edi, 0

%else ; VIDEO
    ; waveOutOpen(&hWaveOut, WAVE_MAPPER, &WaveFMT, NULL, 0, CALLBACK_NULL );
    times 3 push 0
    push wavefmt
    push WAVE_MAPPER
    push hwaveout
    call _waveOutOpen@24

    ; waveOutWrite(hWaveOut, &WaveHDR, sizeof(WaveHDR));
    push wavehdr_end - wavehdr
    push wavehdr
    push dword [hwaveout]
    call _waveOutWrite@12
%endif ; VIDEO
mainloop:
    inc edi
%ifdef VIDEO
    ; Create file name.
    push edi
    push screenshot_format
    push screenshot_file
    call _sprintf

    ; Create bitmap file.
    push NULL
    push FILE_ATTRIBUTE_NORMAL
    push CREATE_ALWAYS
    push NULL
    push 0
    push GENERIC_WRITE
    push screenshot_file
    call _CreateFileA@28
    mov dword [hfile], eax

    ; Write bitmap header.
    push NULL
    push bytes_written
    push bmp_header_end-bmp_header
    push bmp_header
    push dword [hfile]
    call _WriteFile@20

%endif ; VIDEO

    ; Set time uniform (location 0) to time
    push gluniform1i
    call _wglGetProcAddress@4
    push edi
    push 0
    call eax

    ; glRecti(-1, -1, 1, 1);
    times 2 push dword 1
    times 2 push dword -1
    call _glRecti@16

%ifdef VIDEO
    ; Read the pixels.
    ; glReadPixels(0, 0, WIDTH, HEIGHT, GL_BGR, GL_UNSIGNED_BYTE, screenshot_pixels);
    push screenshot_pixels
    push GL_UNSIGNED_BYTE
    push GL_BGR
    push HEIGHT
    push WIDTH
    times 2 push 0
    call _glReadPixels@28

    ; Write pixel data to bitmap.
    push NULL
    push bytes_written
    push WIDTH * HEIGHT * 3
    push screenshot_pixels
    push dword [hfile]
    call _WriteFile@20

    ; Close the file.
    push dword [hfile]
    call _CloseHandle@4

    ; Check if we have all frames we need
    cmp edi, TRACK_DURATION * VIDEO_FPS * 2
    jg exit
%else ; VIDEO
    ; SwapBuffers(hDC);
    push ebp
    call _SwapBuffers@4
%endif ; VIDEO

%ifdef SANE_WINDOWPROC
    ; Dispatch all available win32 messages 
    dispatchloop:
        push PM_REMOVE
        times 3 push 0
        push msg
        call _PeekMessageA@20
        cmp eax, 0
        jne dispatch
%endif ; SANE_WINDOWPROC

%ifdef EXIT_WITH_ESCAPE
    ; Stall until escape.
    push VK_ESCAPE
    call _GetAsyncKeyState@4
    cmp eax, 0
    je mainloop

exit:
%ifdef VIDEO
    ; Exit gracefully if we're running this from CMake.
    push 0
    call _ExitProcess@4
%else ; VIDEO
    ; Fuck it, force-quit.
    hlt
%endif ; VIDEO
%else ; EXIT_WITH_ESCAPE
    jmp mainloop
%endif ; EXIT_WITH_ESCAPE
