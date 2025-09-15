-- Client Animation Manager

local CAM = {}
local Player:Player = game:GetService("Players").LocalPlayer
local Humanoid:Humanoid = Player.Character.Humanoid
local Animator:Animator = Humanoid:FindFirstChildWhichIsA("Animator")

-- STATIC FUNCTIONS
function CAM:LoadAnimation(animation: Animation)
    local sc, tr:AnimationTrack = pcall(Animator.LoadAnimation, Animator, animation)
    if not sc or not tr then return nil end
    tr.Priority = Enum.AnimationPriority.Action
    return tr
end
function CAM:CleanAnimations()
    for _, tr in Animator:GetPlayingAnimationTracks() do
        if tr.Priority == Enum.AnimationPriority.Action then
            tr:Stop()
        end
    end
end

return CAM