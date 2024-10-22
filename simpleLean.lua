---[[                                                                                                                                                                           
-- dddddddd                                        
-- XXXXXXX       XXXXXXX                                               d::::::d                                        
-- X:::::X       X:::::X                                               d::::::d                                        
-- X:::::X       X:::::X                                               d::::::d                                        
-- X::::::X     X::::::X                                               d:::::d                                         
-- XXX:::::X   X:::::XXX  aaaaaaaaaaaaa  nnnn  nnnnnnnn        ddddddddd:::::d     eeeeeeeeeeee    rrrrr   rrrrrrrrr   
--    X:::::X X:::::X     a::::::::::::a n:::nn::::::::nn    dd::::::::::::::d   ee::::::::::::ee  r::::rrr:::::::::r  
--     X:::::X:::::X      aaaaaaaaa:::::an::::::::::::::nn  d::::::::::::::::d  e::::::eeeee:::::eer:::::::::::::::::r 
--      X:::::::::X                a::::ann:::::::::::::::nd:::::::ddddd:::::d e::::::e     e:::::err::::::rrrrr::::::r
--      X:::::::::X         aaaaaaa:::::a  n:::::nnnn:::::nd::::::d    d:::::d e:::::::eeeee::::::e r:::::r     r:::::r
--     X:::::X:::::X      aa::::::::::::a  n::::n    n::::nd:::::d     d:::::d e:::::::::::::::::e  r:::::r     rrrrrrr
--    X:::::X X:::::X    a::::aaaa::::::a  n::::n    n::::nd:::::d     d:::::d e::::::eeeeeeeeeee   r:::::r            
-- XXX:::::X   X:::::XXXa::::a    a:::::a  n::::n    n::::nd:::::d     d:::::d e:::::::e            r:::::r            
-- X::::::X     X::::::Xa::::a    a:::::a  n::::n    n::::nd::::::ddddd::::::dde::::::::e           r:::::r            
-- X:::::X       X:::::Xa:::::aaaa::::::a  n::::n    n::::n d:::::::::::::::::d e::::::::eeeeeeee   r:::::r            
-- X:::::X       X:::::X a::::::::::aa:::a n::::n    n::::n  d:::::::::ddd::::d  ee:::::::::::::e   r:::::r            
-- XXXXXXX       XXXXXXX  aaaaaaaaaa  aaaa nnnnnn    nnnnnn   ddddddddd   ddddd    eeeeeeeeeeeeee   rrrrrrr                                                                                                                                             
---]]

--Sorry, this isnt as user friendly as I wish I could make it.

---[[Config]]---

local cfg = {
    control = {
        stopLean = false,
        influenceArms = true,
        influenceLegs = true,
        vanillaHead = true, --Change as needed
        minAngle = -22.5, --in degrees
        maxAngle = 22.5 --in degrees
    },
    parts = {
        head = models.MODELFILE.PATH.TO.HEAD,
        torso = models.MODELFILE.PATH.TO.TORSO, --Make sure the pivot of the Torso is in an appropriate position for your model! (Say, 0,12,0 on a standard player model)
        arms = {
            left = models.MODELFILE.PATH.TO.LEFT.ARM, --can be omitted
            right = models.MODELFILE.PATH.TO.RIGHT.ARM
        },
        legs = {
            left = models.MODELFILE.PATH.TO.LEFT.LEG, --can be omitted
            right = models.MODELFILE.PATH.TO.RIGHT.LEG
        }
    },
    headStopper = nil --optional
}

---[[Aliases]]---
local p = nil --actual value set in entity initialization (player)
local min = math.min
local max = math.max
local vec3 = vectors.vec3
local sin = math.sin
local cos = math.cos
local rad = math.rad
local part = cfg.parts
local control = cfg.control
---[[Init Vars]]---
local lean, breathe, vHead, lHead = vec3(0,0,0)
--local headRotation = part.head:getRot()
local leanIntensity = 0

---[[Script]]---
function events.entity_init()
    p = player

    if not control.vanillaHead then
        assert(type(part.head) == "ModelPart", "ModelPart Expected, Got "..type(part.head))
        if cfg.headStopper and control.vanillaHead == false then
            assert(type(cfg.headStopper) == "Animation", "Animation Expected, got "..type(cfg.headStopper))
            cfg.headStopper:play()
        end
    end

end

local function velocitymod()
    if not player:isLoaded() then return 0 end
    if p:getPose() == "STANDING" then
        local velocity = p:getVelocity().x_z:length() - 0.21585
        return min(max(velocity, 0), 0.06486) / 0.06486 * 9 + 1
    else
        return 1000
    end
   
end

function events.tick()
    vHead = (((vanilla_model.HEAD:getOriginRot())+180)%360)-180 --Vanilla Head
    local headRotation = part.head:getRot()
    local targetVel = velocitymod()
    if not control.stopLean then
        breathe = vec3(sin(world.getTime()/16)*2, cos(world.getTime()/16)/2,0)
        if control.vanillaHead then
            leanIntensity = min(max(sin(rad(vHead.x/2 * 0.75 / targetVel)) * 45, control.minAngle), control.maxAngle)
            lean = vec3(leanIntensity, vHead.y/4, (part.torso:getOffsetRot().y+vHead.y)*(math.abs(math.rad(vHead.x)))/12)
        else
            leanIntensity = min(max(sin(rad(headRotation.x * 0.75 / targetVel)) * 45, control.minAngle), control.maxAngle)
            lean = vec3(leanIntensity, headRotation.y/2, (part.torso:getOffsetRot().y+headRotation.y)*(math.abs(math.rad(headRotation.x)))/8)
        end
    else
        lean = vec3(0,0,0)
    end
end

function events.render(delta)
    local sLean = math.lerp(part.torso:getOffsetRot(), lean+(breathe/2), 0.0725*delta)

    if not control.vanillaHead then
        lHead = math.lerp(part.head:getRot(), vHead/vec3(1.875,2,1.875), 0.3*delta)
        part.head:setRot(lHead)
    end
    
    if part.arms and part.arms.left and part.arms.right then
        if control.influenceArms then
            part.arms.left:setOffsetRot(sLean*vec3(-0.5,0.5,0.5))
            part.arms.right:setOffsetRot(sLean*vec3(-0.5,0.5,0.5))
        end
    end
    if part.legs and part.legs.right and part.legs.left then
        if control.influenceLegs then
            part.legs.left:setPos(0,0,math.rad(sLean.y))
            part.legs.right:setPos(0,0,math.rad(-sLean.y))
        end
    end

    part.torso:setOffsetRot(sLean)
    
end

return cfg --if you want external control.