# ----------------------------------------------------------------------------------
#  official NVIDIA base image with CUDA 11.8
# ----------------------------------------------------------------------------------
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04

# Prevent apt-get from asking interactive questions during the build
ENV DEBIAN_FRONTEND=noninteractive

# ----------------------------------------------------------------------------------
# Install ALL system dependencies, including build tools
# We keep the compilers here just in case another old package needs them.
# ----------------------------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    # Your application dependencies
    ffmpeg musescore3 libsndfile1 \
    # Python 3.9 and its essential tools
    python3.9 python3.9-dev python3.9-venv python3.9-distutils python3-pip \
    # General build tools and compilers
    build-essential libffi-dev libssl-dev git gfortran g++ \
    # Scientific computing libraries that can help with builds 
    libblas-dev liblapack-dev  \
    libx11-xcb1 libgl1-mesa-glx libxrender1 libxkbcommon-x11-0 libxcb-xinerama0  && \
    rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------------------------------
#  Configure Python and FIX the dependency issue before it happens
# ----------------------------------------------------------------------------------

# Set Python 3.9 as the default 'python'
RUN ln -s /usr/bin/python3.9 /usr/bin/python

# Upgrade the core packaging tools
RUN python -m pip install --upgrade pip setuptools wheel

# Set the working directory
WORKDIR /app

# Copy JUST the requirements file
COPY requirements.txt .

# ✅ --- THIS IS THE CRITICAL FIX ---
# The error is caused by an old NumPy version (1.19.5) in requirements.txt.
# We will PRE-INSTALL a modern, pre-compiled version of NumPy.
# This satisfies the dependency before pip tries to build the old, broken version.
RUN pip install --no-cache-dir "numpy>=1.22,<2.0"

# Now, install the rest of the requirements. Pip will see that NumPy is already
# installed and will not try to downgrade and re-compile it.
RUN pip install --no-cache-dir -r requirements.txt

# ----------------------------------------------------------------------------------
#  Finalize the image
# ----------------------------------------------------------------------------------
RUN pip install --no-cache-dir --upgrade "typing_extensions>=4.8.0"
# Copy the rest of your application code
COPY . .

# Set the default command
ENTRYPOINT ["python", "main.py"]
CMD []
