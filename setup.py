#!/usr/bin/python
from setuptools import setup

with open('requirements.txt', 'r') as f:
    requires = [x.strip() for x in f if x.strip()]


setup(
    name='kinetic-swift',
    version='0.1',
    description='Kinetic Plugin for Swift',
    author='SwiftStack/Seagate',
    packages=['kinetic_swift'],
    install_requires=requires,
    entry_points={
        'paste.app_factory': [
            'object=kinetic_swift.obj.server:app_factory',
        ],
        'console_scripts': [
            'kinetic-swift-replicator = kinetic_swift.obj.replicator:main',
        ],
    },
)
