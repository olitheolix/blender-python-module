import bpy  # type: ignore

# Print Blender version.
version = bpy.app.version_string
print(f"Blender version: {version}")

# List all objects in the scene, which should be the default cube, a light and
# a camera.
for obj in bpy.data.objects:
    print(f"Found {obj.name}")
