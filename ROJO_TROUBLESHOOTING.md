# Rojo Mesh Preservation Troubleshooting

## Issue: Meshes not appearing in Studio after Rojo sync

### Checklist to verify:

1. **File naming**:
   - Meta files must have EXACT same name as .rbxm files
   - `G36.rbxm` → `G36.meta.json` ✓

2. **Asset ID format**:
   - Should be: `"rbxassetid://1234567890"`
   - NOT: `"rbxassetid://rbxassetid://1234567890"` ❌
   - Fixed in both files ✓

3. **Valid Asset IDs**:
   - All asset IDs must be valid uploaded meshes/textures
   - Check each ID exists in Studio Asset Manager
   - Make sure you own/have access to these assets

4. **Rojo sync process**:
   - Stop Rojo server
   - Restart Rojo server
   - Reconnect in Studio
   - Check if properties appear

5. **File structure verification**:
   ```
   WeaponModels/Primary/AssaultRifles/
   ├── G36.rbxm
   └── G36.meta.json

   ViewModels/Primary/AssaultRifles/
   ├── G36.rbxm
   └── G36.meta.json
   ```

### Common Issues:

1. **Asset ownership**: You must own or have access to the mesh/texture assets
2. **Asset type mismatch**: MeshId must point to a Mesh asset, TextureId to an Image
3. **Rojo cache**: Try deleting Rojo's cache and reconnecting
4. **Studio restart**: Sometimes Studio needs a full restart after Rojo changes

### Testing steps:

1. Try with just one simple asset ID first
2. Check if the meta file structure matches your actual .rbxm structure
3. Verify in Studio Properties panel that MeshId/TextureId fields are populated
4. Check Rojo output logs for any error messages

### Quick test:
Create a simple test case with a single MeshPart and known working asset ID to verify the system works.