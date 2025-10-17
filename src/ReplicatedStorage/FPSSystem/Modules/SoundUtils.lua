local SoundUtils = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Play a local sound by asset id. parent may be a Instance (Camera, character part), defaults to workspace.CurrentCamera
function SoundUtils:PlayLocalSound(soundId, parent, volume, pitch, loop)
    if not soundId then return end
    local sound = Instance.new("Sound")
    sound.SoundId = tostring(soundId)
    sound.Volume = volume or 1
    sound.Pitch = pitch or 1
    sound.Looped = loop and true or false

    local parentObj = parent or workspace.CurrentCamera
    if not parentObj or not parentObj.Parent then
        parentObj = workspace.CurrentCamera
    end

    sound.Parent = parentObj
    sound:Play()

    if not sound.Looped then
        sound.Ended:Connect(function()
            if sound and sound.Parent then
                sound:Destroy()
            end
        end)
        Debris:AddItem(sound, 5)
    end

    return sound
end

return SoundUtils


