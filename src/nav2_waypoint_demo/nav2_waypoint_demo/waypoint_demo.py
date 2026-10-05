import math
import time

from geometry_msgs.msg import PoseStamped
from nav2_simple_commander.robot_navigator import BasicNavigator, TaskResult
import rclpy


WAYPOINTS = [
    ('top corridor', 0.0, 2.0, 0.0),
    ('right corridor', 2.0, 0.5, -math.pi / 2.0),
    ('right lower corridor', 2.0, -0.5, math.pi),
]


def make_pose(navigator, x, y, yaw):
    """Create a map-frame pose from x, y, and yaw."""
    pose = PoseStamped()
    pose.header.frame_id = 'map'
    pose.header.stamp = navigator.get_clock().now().to_msg()
    pose.pose.position.x = x
    pose.pose.position.y = y
    pose.pose.orientation.z = math.sin(yaw / 2.0)
    pose.pose.orientation.w = math.cos(yaw / 2.0)
    return pose


def main(args=None):
    rclpy.init(args=args)
    navigator = BasicNavigator(node_name='waypoint_demo')
    exit_code = 1

    try:
        navigator.get_logger().info('Waiting for Nav2 to become active...')
        navigator.waitUntilNav2Active()

        poses = []
        for name, x, y, yaw in WAYPOINTS:
            navigator.get_logger().info(
                f'Waypoint {len(poses) + 1}: {name} '
                f'(x={x:.1f}, y={y:.1f}, yaw={math.degrees(yaw):.0f} deg)'
            )
            poses.append((name, make_pose(navigator, x, y, yaw)))

        all_succeeded = True
        for index, (name, pose) in enumerate(poses, start=1):
            navigator.get_logger().info(
                f'Sending waypoint {index}/{len(poses)}: {name}'
            )
            if not navigator.goToPose(pose):
                navigator.get_logger().error(
                    f'Waypoint {index} goal was rejected'
                )
                all_succeeded = False
                break

            last_feedback_log = 0.0
            while not navigator.isTaskComplete():
                feedback = navigator.getFeedback()
                now = time.monotonic()
                if feedback is not None and now - last_feedback_log >= 2.0:
                    navigator.get_logger().info(
                        f'Waypoint {index}/{len(poses)} feedback: '
                        f'{feedback.distance_remaining:.2f} m remaining, '
                        f'{feedback.number_of_recoveries} recoveries'
                    )
                    last_feedback_log = now

            result = navigator.getResult()
            if result == TaskResult.SUCCEEDED:
                navigator.get_logger().info(
                    f'WAYPOINT_{index}_SUCCEEDED: {name}'
                )
                continue

            all_succeeded = False
            if result == TaskResult.CANCELED:
                navigator.get_logger().warning(
                    f'WAYPOINT_{index}_CANCELED: {name}'
                )
            else:
                navigator.get_logger().error(
                    f'WAYPOINT_{index}_FAILED: {name}'
                )
            break

        if all_succeeded:
            navigator.get_logger().info('WAYPOINT_DEMO_SUCCEEDED')
            exit_code = 0
        else:
            navigator.get_logger().error('WAYPOINT_DEMO_FAILED')
    except KeyboardInterrupt:
        navigator.get_logger().warning('Canceling waypoint demo')
        navigator.cancelTask()
    finally:
        navigator.destroy_node()
        rclpy.shutdown()

    if exit_code:
        raise SystemExit(exit_code)


if __name__ == '__main__':
    main()
