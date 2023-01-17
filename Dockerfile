# ----------------------------------------------------------------------
# Build Blender 3.4 as a Python module.
#
# Usage;
#   docker build -t blender .
#   docker run -ti --rm blender bash -c "PYTHONPATH=/pyblender python3 demo.py"
# ----------------------------------------------------------------------
FROM ubuntu:22.04


# ----------------------------------------------------------------------
# Install dependencies.
# ----------------------------------------------------------------------
RUN apt update && apt install -y \
    build-essential \
    cmake \
    git \
    libboost-all-dev \
    libdbus-1-dev \
    libdecor-0-dev \
    libegl-dev \
    libembree-dev \
    libepoxy-dev \
    libfftw3-dev \
    libfreetype6-dev \
    libglew-dev \
    libgmp10-dev \
    libhpdf-dev \
    libjpeg-dev \
    libjpeg-dev \
    libopenexr-dev \
    libopenimageio-dev \
    libopenjp2-7-dev \
    libpng-dev \
    libpotrace-dev \
    libpugixml-dev \
    libtbb-dev \
    libtiff-dev \
    libwayland-dev \
    libwebp-dev \
    libx11-dev \
    libxcursor-dev \
    libxi-dev \
    libxinerama-dev \
    libxkbcommon-dev \
    libxrandr-dev \
    libxxf86vm-dev \
    libzstd-dev \
    linux-libc-dev \
    python3-numpy \
    python3-pip \
    python3.10-dev \
    wayland-protocols \
    wget \
    zlib1g \
    zlib1g-dev

# Blender does not require IPython but it is handy to have in any case.
RUN pip3 install ipython


# ----------------------------------------------------------------------
# Build OpenColorIO (Ubuntu packages are too old)
# ----------------------------------------------------------------------
RUN git clone https://github.com/AcademySoftwareFoundation/OpenColorIO.git /tmp/ocio
RUN cmake -S /tmp/ocio -B /tmp/ocio/build -DOCIO_INSTALL_EXT_PACKAGES=MISSING
RUN cmake --build /tmp/ocio/build -j24
RUN make -C /tmp/ocio/build install
RUN ldconfig


# ----------------------------------------------------------------------
# Build and install OpenSubdiv.
# ----------------------------------------------------------------------
RUN wget https://github.com/PixarAnimationStudios/OpenSubdiv/archive/refs/tags/v3_4_4.tar.gz --output-document=/tmp/osd.tar.gz
RUN tar -xvf /tmp/osd.tar.gz -C /tmp && mv /tmp/OpenSubdiv-3_4_4 /tmp/osd
RUN cmake -S /tmp/osd -B /tmp/osd/build/ -DCMAKE_BUILD_TYPE=Release -DNO_TBB=ON -DNO_CUDA=ON -DNO_OPENCL=ON -DNO_PTEX=ON
RUN cmake --build /tmp/osd/build -j24
RUN make -C /tmp/osd/build install
RUN ldconfig


# ----------------------------------------------------------------------
# Build and install the Blender module.
# ----------------------------------------------------------------------
RUN git clone https://github.com/blender/blender.git /src/blender
WORKDIR /src/blender
RUN git checkout blender-v3.4-release

# FYI: This will create a new folder </src/build_linux_bpy> which is NOT a
# sub-folder of </src/blender> for some reason.
RUN make update
RUN make bpy

# Move into the build directory and run another CMake command to actually install the module.
WORKDIR /src/build_linux_bpy
RUN cmake ../blender \
  -DPYTHON_SITE_PACKAGES=/pyblender \
  -DWITH_INSTALL_PORTABLE=OFF \
  -DWITH_PYTHON_INSTALL=OFF \
  -DWITH_PLAYER=OFF \
  -DWITH_PYTHON_MODULE=ON
RUN make install -j$(nproc)


# ----------------------------------------------------------------------
# Verify the build.
# ----------------------------------------------------------------------

# Import the `bpy` module as a first test.
RUN PYTHONPATH=/pyblender python3 -c "import bpy"

# Run a small demo script.
WORKDIR /demo
COPY demo.py .
RUN PYTHONPATH=/pyblender python3 demo.py
