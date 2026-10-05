# ROS 2 Jazzy + Nav2 on Apple Silicon Mac

這個專案在 Docker Desktop 的 Linux/arm64 容器內執行 ROS 2 Jazzy 與 Nav2，macOS 只負責編輯檔案與執行 Docker。

## 成果展示

- [38 秒 TurtleBot3 多 waypoint 自主導航影片](outputs/nav2_waypoint_demo.mov)
- [完整成功執行紀錄](outputs/waypoint_demo.log)

展示中，TurtleBot3 依序抵達三個目標點；RViz 同時呈現地圖、AMCL 定位、TF、global/local costmap、規劃路徑與 Navigation feedback。三個目標均成功完成，且沒有觸發 recovery。

## 展示流程

```bash
./nav2.sh build
./nav2.sh sim-headless
./nav2.sh rviz-web
./nav2.sh waypoint-demo
./nav2.sh stop
```

`sim-headless` 會啟動 TurtleBot3、Gazebo、AMCL 與 Nav2，並送出出生位置 `(-2.0, -0.5)`。`rviz-web` 會在瀏覽器開啟 RViz。`waypoint-demo` 會建置並執行 Python 節點，依序送出三個 `NavigateToPose` action；每個 waypoint 成功後才會前往下一點。

成功時，終端最後會顯示：

```text
WAYPOINT_DEMO_SUCCEEDED
```

執行記錄會保存到 `outputs/waypoint_demo.log`。

## Waypoint 專案

程式位於：

```text
src/nav2_waypoint_demo/nav2_waypoint_demo/waypoint_demo.py
```

三個 waypoint 位於 `map` frame：

| 順序 | x | y | yaw | 說明 |
| --- | ---: | ---: | ---: | --- |
| 1 | 0.0 | 2.0 | 0° | 上方走廊 |
| 2 | 2.0 | 0.5 | -90° | 右側走廊 |
| 3 | 2.0 | -0.5 | 180° | 右下走廊 |

導航資料流：

```text
Sequential NavigateToPose goals
  → BT Navigator
  → global planner / global costmap
  → controller / local costmap
  → cmd_vel_nav
  → velocity smoother
  → collision monitor
  → cmd_vel
  → TurtleBot3
```

AMCL 使用靜態地圖、雷射掃描與里程計估計 `map → odom`；模擬器提供 `odom → base_link`，兩者組成 Nav2 使用的 TF 鏈。

## 其他診斷指令

```bash
./nav2.sh check
./nav2.sh shell
./nav2.sh sim-status
./nav2.sh sim-logs
./nav2.sh demo-goal
```

進入容器後，ROS 環境會自動載入。可先試：

```bash
ros2 pkg list | grep nav2
ros2 launch nav2_bringup tb3_simulation_launch.py --show-args
```

## 架構

- Host：Apple Silicon macOS
- Container：Ubuntu 24.04 (Noble), Linux/arm64
- ROS：ROS 2 Jazzy
- Navigation：Nav2 binary packages
- Simulation：Nav2 Minimal TurtleBot 3 + modern Gazebo packages

RViz 使用容器內的 Xvfb 與 Mesa llvmpipe 軟體 OpenGL，經 noVNC 顯示在 macOS 瀏覽器中，因此不依賴 XQuartz 的 OpenGL 版本。
