FROM ros:jazzy-ros-base-noble

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ros-dev-tools \
        ros-jazzy-navigation2 \
        ros-jazzy-nav2-bringup \
        ros-jazzy-nav2-minimal-tb3-sim \
        ros-jazzy-rviz2 \
        xvfb \
        x11vnc \
        novnc \
        websockify \
        openbox \
        mesa-utils \
        libgl1-mesa-dri \
    && rm -rf /var/lib/apt/lists/*

# The Jazzy minimal TB3 URDF expects meshes directly under models/, while the
# Debian package installs them under models/turtlebot3_model/meshes/.
RUN cd /opt/ros/jazzy/share/nav2_minimal_tb3_sim/models \
    && ln -s turtlebot3_model/meshes/*.dae .

RUN printf '%s\n' \
    'source /opt/ros/jazzy/setup.bash' \
    'if [ -f /workspace/install/setup.bash ]; then source /workspace/install/setup.bash; fi' \
    >> /root/.bashrc

WORKDIR /workspace

CMD ["bash"]
