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
    }
}

---[[Aliases]]---
local p = nil --actual value set in entity initialization (player)
local min = math.min
local max = math.max
local lerp = math.lerp
local sin = math.sin
local rad = math.rad
local abs = math.abs
local vec3 = vectors.vec3
local part = cfg.parts
local control = cfg.control
---[[Init Vars]]---
local lean, vHead, lHead = vec3(0,0,0)
local leanIntensity = 0

---[[Script]]---
function events.entity_init()
    p = player
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
    if control.stopHead then vHead = vec(0,0,0) return end
    vHead = (((vanilla_model.HEAD:getOriginRot())+180)%360)-180 --Vanilla Head
    if control.stopLean then return end
    local headRotation = part.head:getOffsetRot()
    local targetVel = velocitymod()
    local selHead = control.vanillaHead and vHead:toRad() or headRotation:toRad()
    local divmod = control.vanillaHead and 12 or 8
    if not control.stopLean then
        local t = sin(world.getTime() / 16.0)
        local breathe = vec3(
                t * 2.0,
                math.sqrt(1 - (t * t)) / 2.0,
                0.0
                )
            leanIntensity = min(max(sin((selHead.x/2 * 0.75 / targetVel)) * 45, control.minAngle), control.maxAngle)
            lean = vec3(leanIntensity,  selHead.y/4, (part.torso:getOffsetRot().y+vHead.y)*(abs(rad(vHead.x)))/divmod)+breathe
    else
        lean = vec3(0,0,0)
    end
end

function events.render(delta)
    local sLean = math.lerp(part.torso:getOffsetRot(), lean, 0.0725*delta)
    if not control.vanillaHead then
        part.head:setRot(-vanilla_model.HEAD:getOriginRot())
        lHead = lerp(part.head:getOffsetRot(), vHead/vec3(1.875,2,1.875), 0.3*delta)
        part.head:setOffsetRot(lHead)
    end
    
    if part.arms and part.arms.left and part.arms.right then
        if control.influenceArms then
            part.arms.left:setOffsetRot(sLean*vec3(-0.5,0.5,0.5))
            part.arms.right:setOffsetRot(sLean*vec3(-0.5,0.5,0.5))
        end
    end
    if part.legs and part.legs.right and part.legs.left then
        if control.influenceLegs then
            part.legs.left:setPos(0,0,rad(sLean.y))
            part.legs.right:setPos(0,0,rad(-sLean.y))
        end
    end

    part.torso:setOffsetRot(sLean)
end

return cfg --if you want external control.
