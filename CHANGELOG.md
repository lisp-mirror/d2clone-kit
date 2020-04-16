# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- DSL-like entitites initialization.
- HP and mana subsystems as well as player's HP and mana orbs.
- Mob system.

### Fixed
- Minor deployment-related fixes.
- Fixed character movement speed maths.
- Fixed bug causing memory faults on secondary start attempts after caught conditions.
- Fixed bug when the character was registered as colliding with some stuff when it really wasn't.



## [0.0.1] - 2020-04-10
### Added
- Aseprite format parser.
- Viewport handling routines.
- A* algorithm.
- Config subsystem built on top of [liballegro APIs](https://liballeg.org/a5docs/5.2.0/config.html).
- Simple engine demo.
- Means of visual debugging.
- Simple event loop built on top of [deeds](https://github.com/Shinmera/deeds) library.
- Support for loading assets from zip files.
- Utilities to easily parse binary files.
- Some data structures, including simple-vector of dynamic size, priority queue and sparse-matrix.
- Log subsystem built on top of liballegro APIs.
- Proper (not like the [last time](https://awkravchuk.itch.io/darkness-looming)) isometric <-> orthogonal conversion maths.
- Functional 2D renderer.
- Sprite batching subsystem.
- Stateful movable sprites.
- Simple ECS implementation.
- Tiled format parser.