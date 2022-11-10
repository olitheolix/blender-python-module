# ----------------------------------------------------------------------
# Create Blender as a Python module.
#
# Usage;
#   docker build -t blender .
#   docker run -ti --rm blender bash
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
    libegl-dev \
    libembree-dev \
    libfftw3-dev \
    libfreetype6-dev \
    libglew-dev \
    libgmp10-dev \
    libhpdf-dev \
    libjpeg-dev \
    libopenimageio-dev \
    libpng-dev \
    libpotrace-dev \
    libpugixml-dev \
    libtbb-dev \
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
    zlib1g \
    zlib1g-dev

# Blender does not require IPython but it is handy to have in any case.
RUN pip3 install ipython

# Clone Blender and checkout v3.3
RUN git clone https://github.com/blender/blender.git /src/blender
WORKDIR /src/blender
RUN git checkout blender-v3.3-release

# ----------------------------------------------------------------------
# Build and install the Blender module.
# ----------------------------------------------------------------------

# FYI: This will create a new folder </src/build_linux_bpy> which is NOT a
# sub-folder of </src/blender> for some reason.
RUN make update && make bpy

# Move into the build directory and run another CMake command to actually install the module.
WORKDIR /src/build_linux_bpy
RUN cmake ../blender \
  -DPYTHON_SITE_PACKAGES=/usr/local/lib/python3.10/dist-packages/ \
  -DWITH_INSTALL_PORTABLE=OFF \
  -DWITH_PYTHON_INSTALL=OFF \
  -DWITH_PLAYER=OFF \
  -DWITH_PYTHON_MODULE=ON
RUN make install -j$(nproc)

# ----------------------------------------------------------------------
# Verify the installation.
# ----------------------------------------------------------------------

# Try to import the `bpy` module as a first test.
RUN python3 -c "import bpy"

# Run a small demo script.
WORKDIR /demo
COPY demo.py .
RUN python3 demo.py
