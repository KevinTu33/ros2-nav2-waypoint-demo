from setuptools import find_packages, setup

package_name = 'nav2_waypoint_demo'

setup(
    name=package_name,
    version='0.1.0',
    packages=find_packages(exclude=['test']),
    data_files=[
        ('share/ament_index/resource_index/packages',
            ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='Huan',
    maintainer_email='huan@example.com',
    description='Three-waypoint TurtleBot3 navigation demo using Nav2.',
    license='Apache-2.0',
    extras_require={
        'test': [
            'pytest',
        ],
    },
    entry_points={
        'console_scripts': [
            'waypoint_demo = nav2_waypoint_demo.waypoint_demo:main'
        ],
    },
)
