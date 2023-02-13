# Balls and Noises
# Copyright (C) 2023  Alexander Kraus <nr4@z10.info>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

cmake_minimum_required(VERSION 3.15)

project(tas)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

# Configure this shit.
set(PROD_NAME "Balls and Noises")
set(PROD_AUTHOR "Team210")
set(PROD_WIDTH 1920)
set(PROD_HEIGHT 1080)
set(SCREENSHOT_FRAME 00000300)

# Generate the executable name
string(REPLACE " " "." SANE_PROD_NAME ${PROD_NAME})
string(REPLACE " " "." SANE_PROD_AUTHOR ${PROD_AUTHOR})
set(EXECUTABLE_NAME "${SANE_PROD_NAME}-${SANE_PROD_AUTHOR}")

# Download build requirements
include(external/cmake-find-or-download/find-or-download.cmake)
find_or_download_if_not_present(GLSLANG_VALIDATOR glslangValidator.exe "https://github.com/KhronosGroup/glslang/releases/download/master-tot/glslang-master-windows-x64-Release.zip" bin/)
find_or_download_if_not_present(SHADER_MINIFIER shader_minifier.exe "https://github.com/laurentlb/Shader_Minifier/releases/download/1.2/shader_minifier.exe" ./)
find_or_download_if_not_present(NASM nasm.exe "https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/win64/nasm-2.15.05-win64.zip" nasm-2.15.05/)
find_or_download_if_not_present(CRINKLER Crinkler.exe "https://github.com/runestubbe/Crinkler/releases/download/v2.3/crinkler23.zip" crinkler23/Win64/)
find_or_download_if_not_present(IMAGE_MAGICK magick.exe "https://imagemagick.org/archive/binaries/ImageMagick-7.1.0-58-portable-Q16-x64.zip" ./)
find_or_download_if_not_present(FFMPEG ffmpeg.exe "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" ffmpeg-5.1.2-essentials_build/bin/)
find_package(OpenGL REQUIRED COMPONENTS OpenGL)

# Note: Keep order below; For some reason we can not enable a language
# without having specified a compiler for the language.
set(CMAKE_ASM_NASM_COMPILER ${NASM})
enable_language(ASM_NASM)
set(CMAKE_LINKER ${CRINKLER})

# Global setup
# Note: We need this because cmake ASM_NASM + lld + crinkler is allergic to proper platform specification
set(CMAKE_SIZEOF_VOID_P 4)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/external/cmake-modules/")
find_package(WindowsSDK REQUIRED COMPONENTS tools)
get_windowssdk_library_dirs(${WINDOWSSDK_LATEST_DIR} WINDOWSSDK_LIBRARY_DIRS)
link_directories(${WINDOWSSDK_LIBRARY_DIRS})
link_libraries(opengl32.lib kernel32.lib user32.lib gdi32.lib winmm.lib)
include_directories(${PROJECT_SOURCE_DIR})
add_definitions(
    -DSHADER_MUSIC
    -DWIDTH=${PROD_WIDTH}
    -DHEIGHT=${PROD_HEIGHT}
)

# Validate shader
add_custom_target(validate-gfx ALL
    COMMAND ${GLSLANG_VALIDATOR} gfx.frag
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    COMMENT "Validating gfx.frag..."
)

# Generate minified shader assembly file
add_custom_target(gfx.big.inc ALL
    COMMAND ${SHADER_MINIFIER} gfx.frag -o "${PROJECT_BINARY_DIR}/gfx.big.inc" -v --format nasm
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
    COMMENT "Minifying gfx.frag..."
)
add_dependencies(gfx.big.inc validate-gfx)

# Strip unneccessary shit from shader assembly file
add_custom_target(gfx.inc ALL
    COMMAND tail -n +6 gfx.big.inc > gfx.inc
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
    COMMENT "Stripping unused sections from gfx.inc..."
)
add_dependencies(gfx.inc gfx.big.inc)

# Add the prod relase executable.
add_executable(${EXECUTABLE_NAME} intro.asm)
add_dependencies(${EXECUTABLE_NAME} gfx.inc)
target_link_options(${EXECUTABLE_NAME} PRIVATE
    /compmode:veryslow
    /tinyheader
    /tinyimport
    /unsafeimport
    /unaligncode
    /hashtries:12400
    /ordertries:20000
    /progressgui
    /largeaddressaware:no
    /noinitializers
    /report:${EXECUTABLE_NAME}.html
    /nodefaultlib
    /subsystem:windows
)
target_link_options(${EXECUTABLE_NAME} PRIVATE )

# Add the prod debug executable
add_executable(${EXECUTABLE_NAME}-Debug intro.asm)
add_dependencies(${EXECUTABLE_NAME}-Debug gfx.inc)
target_compile_definitions(${EXECUTABLE_NAME}-Debug PRIVATE
    # Note: This adds DefWindowProc calls in the main loop. 
    # Without the definition, the exe will hang up when win32 sends any
    # message to it. This particularly happens with driver overlays, key press events 
    # and mouse clicks. Costs ~31 bytes.
    SANE_WINDOWPROC
    # Desparation. Disable exit with escape to save a few bytes.
    EXIT_WITH_ESCAPE
)
target_link_libraries(${EXECUTABLE_NAME}-Debug PRIVATE ucrt.lib)
target_link_options(${EXECUTABLE_NAME}-Debug PRIVATE
    /compmode:fast
    /nodefaultlib
    /subsystem:windows
)

# Add a custom debug target to have faster access
add_custom_target(debug ALL)
add_dependencies(debug ${EXECUTABLE_NAME}-Debug)

# Add a video executable
add_executable(${EXECUTABLE_NAME}-video intro.asm)
add_dependencies(${EXECUTABLE_NAME}-video gfx.inc)
target_compile_definitions(${EXECUTABLE_NAME}-video PRIVATE
    -DVIDEO
    -DSANE_WINDOWPROC
    -DEXIT_WITH_ESCAPE
)
target_link_options(${EXECUTABLE_NAME}-video PRIVATE
    /compmode:fast
    /subsystem:windows
)

# Generate video frames and sound
add_custom_target(video.raw ALL)
add_custom_command(TARGET video.raw
    COMMAND ${EXECUTABLE_NAME}-video
    COMMENT "Rendering video..."
)
add_dependencies(video.raw ${EXECUTABLE_NAME}-video)

# Encode the video
file(MAKE_DIRECTORY "${PROJECT_BINARY_DIR}/frames")
add_custom_target(video.encoded ALL)
add_custom_command(TARGET video.encoded
    COMMAND ${FFMPEG} -framerate 60 -i frames/%08d.bmp ${EXECUTABLE_NAME}-Visuals.mp4 -y
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
    COMMENT "Encoding graphics..."
)
add_custom_command(TARGET video.encoded
    COMMAND ${FFMPEG} -f f32le -ac 2 -ar 44100 -i msx.raw ${EXECUTABLE_NAME}-Music.wav -y
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
    COMMENT "Encoding music..."
)
add_custom_command(TARGET video.encoded
    COMMAND ${FFMPEG} -i ${EXECUTABLE_NAME}-Visuals.mp4 -i ${EXECUTABLE_NAME}-Music.wav -c:v libx264 -c:a libvorbis -shortest ${EXECUTABLE_NAME}.mp4 -y
    WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
    COMMENT "Encoding video..."
)
add_dependencies(video.encoded video.raw)

# Convert screenshot to PNG with image magick.
add_custom_target(${EXECUTABLE_NAME}-Screenshot.png ALL)
add_custom_command(TARGET ${EXECUTABLE_NAME}-Screenshot.png
    COMMAND ${IMAGE_MAGICK} frames/${SCREENSHOT_FRAME}.bmp ${EXECUTABLE_NAME}-Screenshot.png
    COMMENT "Generating ${EXECUTABLE_NAME}-Screenshot.png..."
)
add_dependencies(${EXECUTABLE_NAME}-Screenshot.png video.encoded)

# Generate Pouet.net prod thumbnail with image magick.
add_custom_target(${EXECUTABLE_NAME}-Thumbnail.jpg ALL)
add_custom_command(TARGET ${EXECUTABLE_NAME}-Thumbnail.jpg
    COMMAND ${IMAGE_MAGICK} frames/${SCREENSHOT_FRAME}.bmp -resize 400x320 ${EXECUTABLE_NAME}-Thumbnail.jpg
    COMMENT "Generating ${EXECUTABLE_NAME}-Thumbnail.jpg..."
)
add_dependencies(${EXECUTABLE_NAME}-Thumbnail.jpg video.encoded)

# Copy NFO.
add_custom_target(${EXECUTABLE_NAME}.nfo ALL)
add_custom_command(TARGET ${EXECUTABLE_NAME}.nfo
    COMMAND cp ${PROJECT_SOURCE_DIR}/Team210.nfo ${EXECUTABLE_NAME}.nfo
)

# Add a target to quickly produce the release archive
add_custom_target(release-archive ALL)
add_custom_command(TARGET release-archive
    COMMAND ${CMAKE_COMMAND} -E tar "cfv" "${EXECUTABLE_NAME}.zip" --format=zip
        ${EXECUTABLE_NAME}.exe
        ${EXECUTABLE_NAME}.nfo
        ${EXECUTABLE_NAME}-Screenshot.png
    COMMENT "Generating ${EXECUTABLE_NAME}.zip..."
)
add_dependencies(release-archive
    ${EXECUTABLE_NAME}
    ${EXECUTABLE_NAME}.nfo
    ${EXECUTABLE_NAME}-Screenshot.png
)
