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
        oldLean = false,
        vanillaHead = true, --Change as needed
        maxLean = {
            x = 22.5,
            y = 15.0,
        },
        minLean = {
            x = -22.5,
            y = -15.0,
        },
        scale = {
            x = 1.0,
            y = 1.0
        },
        const = 45.5
    },
    parts = {
        root = models.MODELFILE.PATH.TO.ROOT --kinda useless rn
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
local pi = math.pi
local part = cfg.parts
local control = cfg.control
---[[Init Vars]]---
local lean, vHead, lHead = vec3(0,0,0)
local leanIntensity = 0

  local function inOutSine(a, b, t)
    return (a - b) / 2 * (math.cos(pi * t) - 1) + a
  end

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
    vHead = (((vanilla_model.HEAD:getOriginRot())+180)%360)-180 --Vanilla Head
    if control.stopLean then return end
    local headRotation = part.head:getOffsetRot()
    local targetVel = velocitymod()
    local selHead = control.vanillaHead and vHead:toRad() or not control.vanillaHead and headRotation:toRad()
    if not control.stopLean then
        local t = sin(world.getTime() / 16.0)
        local breathe = vec3(
                t * 2.0,
                math.sqrt(1 - (t * t)) / 2.0,
                0.0
                )
        if control.oldLean then
            leanIntensity = min(max((sin((selHead.x/2 * 0.75 / targetVel)) * 45) * (control.scale.x or 1.0), control.minLean.x), control.maxLean.x)
        else
            leanIntensity = min(max((sin(selHead.x / targetVel) * (control.const or 45.5)) * (control.scale.x or 1.0), control.minLean.x), control.maxLean.x)
            --leanIntensity = ((selHead.x / targetVel) * control.const) / 4
        end
        lean = vec3(
            leanIntensity,
            min(max(sin(selHead.y) * (control.const or 45.5) * (player:isSneaking() and 0.1 or (control.scale.y or 1.0)), control.minLean.y or -15.0), control.maxLean.y or 15.0),
            vHead.y*0.075
        )+breathe
    else
        lean = vec3(0,0,0)
    end
end

function events.render(delta)
    local sLean = inOutSine(part.torso:getOffsetRot(), lean, 0.1625)

    lHead = inOutSine(part.head:getOffsetRot(), vHead/vec3(1.875,2,1.875), 0.3)
    vanilla_model.HEAD:setRot(0,0,0)
    if not control.vanillaHead then
        part.head:setOffsetRot(inOutSine(vanilla_model.HEAD:getOriginRot() or vHead, vHead/vec3(1.875,2,1.875), 0.3) - (sLean*0.5) + vec(0,0,(-lHead.y*0.0625)))
    else
        vanilla_model.HEAD:setOffsetRot(inOutSine(vanilla_model.HEAD:getOriginRot() or vHead, vHead/vec3(1.875,2,1.875), 0.3) - (sLean*0.5) + vec(0,0,(-lHead.y*0.0625)))
    end
    if part.arms and part.arms.left and part.arms.right then
        if control.influenceArms then
            part.arms.left:setOffsetRot((lHead*-0.0625) + vec(0,0,-lHead.y*0.0625))
            part.arms.right:setOffsetRot((lHead*-0.0625) + vec(0,0,-lHead.y*0.0625))
        end
    end
    if part.legs and part.legs.right and part.legs.left then
        if control.influenceLegs then
            part.legs.left:setPos(0,0,lHead.y*0.0125)
            part.legs.right:setPos(0,0,-lHead.y*0.0125)
            part.legs.left:setRot(
                (sLean.y*0.0625) - (sLean.x*0.075),
                0,
                0
            )
            part.legs.right:setRot((-sLean.y*0.0625) - (sLean.x*0.075),0,0)
        end
    end

    part.torso:setOffsetRot(sLean)
end

return cfg --if you want external control.
