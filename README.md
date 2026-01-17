# GDShader Library Plugin

A Godot Engine plugin that provides a browsable library of shaders directly within the Godot Editor. Browse, search, and download shaders from [gdshader.com](https://gdshader.com) without leaving your workspace.

## Features

- **Browse Shaders**: View a grid of available shaders with previews
- **Search**: Quickly find shaders by name or description
- **One-Click Download**: Download shaders directly to your project
- **Editor Integration**: Adds a "ShaderLib" tab to your main editor screen
- **Customizable Save Path**: Configure where downloaded shaders are saved

## Installation

1. Download or clone this repository
2. Copy the `addons/gdshader` folder to your Godot project's `addons/` directory
3. Enable the plugin in **Project Settings → Plugins → GDShaderPlugin**

## Usage

1. After enabling the plugin, you'll see a new **ShaderLib** tab in the main editor screen
2. The plugin will automatically fetch available shaders from the GDShader API
3. Browse through the shader cards or use the search bar to find specific shaders
4. Click on a shader card to view details and download

## Configuration

The plugin adds a project setting to configure the shader save location:

- **Path**: `addons/gdshader/save_path`
- **Default**: `res://shaders/`
- **Location**: Project Settings → General → Addons → Gdshader

Change this path to save shaders to a different directory in your project.

## Requirements

- Godot 4.x
- Internet connection (to fetch shaders from the API)

## License

See LICENSE file for details.

## Credits

Created by GDShader
