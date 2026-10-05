#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker_host="$(docker context inspect desktop-linux --format '{{.Endpoints.docker.Host}}')"
docker_config_home="${DOCKER_CONFIG:-$HOME/.docker}"
compose_bin="${DOCKER_COMPOSE_BIN:-$docker_config_home/cli-plugins/docker-compose}"

if [[ ! -x "$compose_bin" ]]; then
  echo "Docker Compose plugin not found at: $compose_bin" >&2
  echo "Set DOCKER_COMPOSE_BIN to the docker-compose plugin path." >&2
  exit 1
fi

export DOCKER_HOST="$docker_host"
export DOCKER_CONFIG="$project_dir/work/docker-config"

compose() {
  "$compose_bin" --project-directory "$project_dir" -f "$project_dir/compose.yaml" "$@"
}

publish_initial_pose() {
  compose exec -T sim bash -lc '
    set -e
    source /opt/ros/jazzy/setup.bash
    for attempt in $(seq 1 45); do
      if ros2 topic info /initialpose 2>/dev/null | grep -q "Subscription count: [1-9]"; then
        break
      fi
      sleep 1
    done
    ros2 topic pub --once /initialpose geometry_msgs/msg/PoseWithCovarianceStamped \
      "{header: {frame_id: map}, pose: {pose: {position: {x: -2.0, y: -0.5, z: 0.0}, orientation: {z: 0.0, w: 1.0}}, covariance: [0.25, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0685]}}"
  '
}

case "${1:-help}" in
  build)
    compose build
    ;;
  shell)
    compose run --rm nav2 bash
    ;;
  check)
    compose run --rm nav2 bash -lc '
      set -e
      source /opt/ros/jazzy/setup.bash
      echo "ROS_DISTRO=$ROS_DISTRO"
      echo "ROS_VERSION=$ROS_VERSION"
      echo "nav2_bringup=$(ros2 pkg prefix nav2_bringup)"
      echo "nav2_bt_navigator=$(ros2 pkg prefix nav2_bt_navigator)"
      echo "nav2_planner=$(ros2 pkg prefix nav2_planner)"
      echo "nav2_controller=$(ros2 pkg prefix nav2_controller)"
      echo "nav2_costmap_2d=$(ros2 pkg prefix nav2_costmap_2d)"
      echo "nav2_minimal_tb3_sim=$(ros2 pkg prefix nav2_minimal_tb3_sim)"
    '
    ;;
  launch-args)
    compose run --rm nav2 bash -lc '
      source /opt/ros/jazzy/setup.bash
      ros2 launch nav2_bringup tb3_simulation_launch.py --show-args
    '
    ;;
  sim-headless)
    compose up -d sim
    publish_initial_pose
    ;;
  init-pose)
    publish_initial_pose
    ;;
  sim-status)
    compose ps
    compose exec sim bash -lc '
      source /opt/ros/jazzy/setup.bash
      echo "bt_navigator: $(ros2 lifecycle get /bt_navigator)"
      echo "planner_server: $(ros2 lifecycle get /planner_server)"
      echo "controller_server: $(ros2 lifecycle get /controller_server)"
      echo "amcl: $(ros2 lifecycle get /amcl)"
    '
    ;;
  sim-logs)
    compose logs --tail 120 sim
    ;;
  rviz-web)
    compose exec -d sim bash /workspace/scripts/rviz_web.sh
    sleep 2
    open 'http://127.0.0.1:6080/vnc.html?autoconnect=1&resize=scale'
    ;;
  demo-goal)
    compose exec -T sim bash -lc '
      source /opt/ros/jazzy/setup.bash
      timeout 90 ros2 action send_goal /navigate_to_pose \
        nav2_msgs/action/NavigateToPose \
        "{pose: {header: {frame_id: map}, pose: {position: {x: -2.0, y: 1.0, z: 0.0}, orientation: {z: 0.7071068, w: 0.7071068}}}}"
    '
    ;;
  waypoint-demo)
    compose exec -T sim bash -lc '
      set -e
      source /opt/ros/jazzy/setup.bash
      cd /workspace
      colcon build --packages-select nav2_waypoint_demo --symlink-install
      source /workspace/install/setup.bash
      ros2 run nav2_waypoint_demo waypoint_demo
    ' 2>&1 | tee "$project_dir/outputs/waypoint_demo.log"
    ;;
  stop)
    compose down
    ;;
  help|*)
    cat <<'EOF'
Nav2 Jazzy on Apple Silicon

Usage:
  ./nav2.sh build        Build the ROS 2 Jazzy + Nav2 image
  ./nav2.sh check        Verify the ROS 2 and Nav2 packages
  ./nav2.sh shell        Open a ROS-ready shell
  ./nav2.sh launch-args  Show TurtleBot 3 simulation launch options
  ./nav2.sh sim-headless Start TurtleBot 3, Gazebo, and Nav2 without GUI
  ./nav2.sh init-pose    Publish the official spawn pose (-2.0, -0.5)
  ./nav2.sh sim-status   Show simulation and Nav2 lifecycle status
  ./nav2.sh sim-logs     Show recent simulation logs
  ./nav2.sh rviz-web     Open RViz in a browser through noVNC
  ./nav2.sh demo-goal    Navigate to the safe demo goal (-2.0, 1.0)
  ./nav2.sh waypoint-demo Run the three-waypoint Python project
  ./nav2.sh stop         Stop project containers
EOF
    ;;
esac
