local netboost = 1000 --velocity 
--netboost usage: 
--set to false to disable
--vector3 if you dont want the velocity to change
--number to change the velocity in real time with magnitude equal to the number
local simradius = "shp" --simulation radius method
--"shp" - sethiddenproperty
--"ssr" - setsimulationradius
--false - disable
local antiragdoll = true --removes hingeConstraints and ballSocketConstraints from your character
local newanimate = true --disables the animate script and enable after reanimation
local discharscripts = true --disables all localScripts parented to your character before reanimation
local R15toR6 = true --tries to convert your character to r6 if its r15
local addtools = false --puts all tools from backpack to character and lets you hold them after reanimation
local loadtime = game:GetService("Players").RespawnTime + 0.5 --anti respawn delay
local method = 3 --reanimation method
--methods:
--0 - breakJoints (takes [loadtime] seconds to laod)
--1 - limbs
--2 - limbs + anti respawn
--3 - limbs + breakJoints after [loadtime] seconds
--4 - remove humanoid + breakJoints
--5 - remove humanoid + limbs
local alignmode = 2 --AlignPosition mode
--modes:
--1 - AlignPosition rigidity enabled true
--2 - 2 AlignPositions rigidity enabled both true and false
--3 - AlignPosition rigidity enabled false
local hedafterneck = true --disable aligns for head and enable after neck is removed

local lp = game:GetService("Players").LocalPlayer
local rs = game:GetService("RunService")
local stepped = rs.Stepped
local heartbeat = rs.Heartbeat
local renderstepped = rs.RenderStepped
local sg = game:GetService("StarterGui")
local ws = game:GetService("Workspace")
local cf = CFrame.new
local v3 = Vector3.new
local v3_0 = v3(0, 0, 0)
local inf = math.huge

local c = lp.Character

if not (c and c.Parent) then
    return
end

c:GetPropertyChangedSignal("Parent"):Connect(function()
    if not (c and c.Parent) then
        c = nil
    end
end)

local function gp(parent, name, className)
	local ret = nil
	pcall(function()
		for i, v in pairs(parent:GetChildren()) do
			if (v.Name == name) and v:IsA(className) then
				ret = v
				break
			end
		end
	end)
	return ret
end

local function align(Part0, Part1)
	Part0.CustomPhysicalProperties = PhysicalProperties.new(0.0001, 0.0001, 0.0001, 0.0001, 0.0001)

	local att0 = Instance.new("Attachment", Part0)
	att0.Orientation = v3_0
	att0.Position = v3_0
	att0.Name = "att0_" .. Part0.Name
	local att1 = Instance.new("Attachment", Part1)
	att1.Orientation = v3_0
	att1.Position = v3_0
	att1.Name = "att1_" .. Part1.Name

	if (alignmode == 1) or (alignmode == 2) then
    	local ape = Instance.new("AlignPosition", att0)
    	ape.ApplyAtCenterOfMass = false
    	ape.MaxForce = inf
    	ape.MaxVelocity = inf
    	ape.ReactionForceEnabled = false
    	ape.Responsiveness = 200
    	ape.Attachment1 = att1
    	ape.Attachment0 = att0
    	ape.Name = "AlignPositionRtrue"
    	ape.RigidityEnabled = true
	end

	if (alignmode == 2) or (alignmode == 3) then
    	local apd = Instance.new("AlignPosition", att0)
    	apd.ApplyAtCenterOfMass = false
    	apd.MaxForce = inf
    	apd.MaxVelocity = inf
    	apd.ReactionForceEnabled = false
    	apd.Responsiveness = 200
    	apd.Attachment1 = att1
    	apd.Attachment0 = att0
    	apd.Name = "AlignPositionRfalse"
    	apd.RigidityEnabled = false
    end

	local ao = Instance.new("AlignOrientation", att0)
	ao.MaxAngularVelocity = inf
	ao.MaxTorque = inf
	ao.PrimaryAxisOnly = false
	ao.ReactionTorqueEnabled = false
	ao.Responsiveness = 200
	ao.Attachment1 = att1
	ao.Attachment0 = att0
	ao.RigidityEnabled = false

    if netboost then
        Part0:GetPropertyChangedSignal("Parent"):Connect(function()
            if not (Part0 and Part0.Parent) then
                Part0 = nil
            end
        end)
        spawn(function()
            if typeof(netboost) == "Vector3" then
    	        local vel = v3_0
    	        local rotvel = v3_0
            	while Part0 do
                    Part0.Velocity = vel
                    Part0.RotVelocity = rotvel
                    heartbeat:Wait()
                    if Part0 then
                        vel = Part0.Velocity
                        Part0.Velocity = netboost
                        Part0.RotVelocity = v3_0
                        stepped:Wait()
                    end
                end
        	elseif typeof(netboost) == "number" then
    	        local vel = v3_0
    	        local rotvel = v3_0
            	while Part0 do
                    Part0.Velocity = vel
                    Part0.RotVelocity = rotvel
                    heartbeat:Wait()
                    if Part0 then
                        local newvel = vel
                        local mag = newvel.Magnitude
                        if mag < 0.001 then
                            newvel = v3(0, netboost, 0)
                        else
                            local multiplier = netboost / mag
                            newvel *= v3(multiplier,  multiplier, multiplier)
                        end
                        vel = Part0.Velocity
                        rotvel = Part0.RotVelocity
                        Part0.Velocity = newvel
                        Part0.RotVelocity = v3_0
                        stepped:Wait()
                    end
                end
        	end
        end)
    end
end

local function respawnrequest()
    local c = lp.Character
    local ccfr = ws.CurrentCamera.CFrame
	local fc = Instance.new("Model")
	local nh = Instance.new("Humanoid", fc)
	lp.Character = fc
	nh.Health = 0
	lp.Character = c
	fc:Destroy()
    local con = nil
    local function confunc()
        con:Disconnect()
        ws.CurrentCamera.CFrame = ccfr
    end
    con = renderstepped:Connect(confunc)
end

local destroyhum = (method == 4) or (method == 5)
local breakjoints = (method == 0) or (method == 4)
local antirespawn = (method == 0) or (method == 2) or (method == 3)

addtools = addtools and gp(lp, "Backpack", "Backpack")

if simradius == "shp" then
    local shp = sethiddenproperty or set_hidden_property or set_hidden_prop or sethiddenprop
    if shp then
        spawn(function()
            while c and heartbeat:Wait() do
                shp(lp, "SimulationRadius", inf)
            end
        end)
    end
elseif simradius == "ssr" then
    local ssr = setsimulationradius or set_simulation_radius or set_sim_radius or setsimradius or set_simulation_rad or setsimulationrad
    if ssr then
        spawn(function()
            while c and heartbeat:Wait() do
                ssr(inf)
            end
        end)
    end
end

antiragdoll = antiragdoll and function(v)
    if v:IsA("HingeConstraint") or v:IsA("BallSocketConstraint") then
        v:Destroy()
    end
end

if antiragdoll then
    for i, v in pairs(c:GetDescendants()) do
        antiragdoll(v)
    end
    c.DescendantAdded:Connect(antiragdoll)
end

if antirespawn then
    respawnrequest()
end

if method == 0 then
	wait(loadtime)
	if not c then
	    return
	end
end

if discharscripts then
    for i, v in pairs(c:GetChildren()) do
        if v:IsA("LocalScript") then
            v.Disabled = true
        end
    end
elseif newanimate then
    local animate = gp(c, "Animate", "LocalScript")
    if animate and (not animate.Disabled) then
        animate.Disabled = true
    else
        newanimate = false
    end
end

local hum = c:FindFirstChildOfClass("Humanoid")
if hum then
    for i, v in pairs(hum:GetPlayingAnimationTracks()) do
	    v:Stop()
    end
end

if addtools then
    for i, v in pairs(addtools:GetChildren()) do
        if v:IsA("Tool") then
            v.Parent = c
        end
    end
end

pcall(function()
    settings().Physics.AllowSleep = false
    settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
end)

local OLDscripts = {}

for i, v in pairs(c:GetDescendants()) do
	if v.ClassName == "Script" then
		table.insert(OLDscripts, v)
	end
end

local scriptNames = {}

for i, v in pairs(c:GetDescendants()) do
	if v:IsA("BasePart") then
	    local newName = tostring(i)
	    local exists = true
	    while exists do
		    exists = false
		    for i, v in pairs(OLDscripts) do
		        if v.Name == newName then
		            exists = true
		        end
		    end
		    if exists then
		        newName = newName .. "_"    
		    end
	    end
        table.insert(scriptNames, newName)
		Instance.new("Script", v).Name = newName
	end
end

c.Archivable = true
local cl = c:Clone()
for i, v in pairs(cl:GetDescendants()) do
    pcall(function()
        v.Transparency = 1
        v.Anchored = false
    end)
end

local model = Instance.new("Model", c)
model.Name = model.ClassName

model:GetPropertyChangedSignal("Parent"):Connect(function()
    if not (model and model.Parent) then
        model = nil
    end
end)

for i, v in pairs(c:GetChildren()) do
	if v ~= model then
	    if destroyhum and v:IsA("Humanoid") then
	        v:Destroy()
	    else
	        if addtools and v:IsA("Tool") then
	            for i1, v1 in pairs(v:GetDescendants()) do
	                if v1 and v1.Parent and v1:IsA("BasePart") then
	                    local bv = Instance.new("BodyVelocity", v1)
	                    bv.Velocity = v3_0
	                    bv.MaxForce = v3(1000, 1000, 1000)
	                    bv.P = 1250
	                    bv.Name = "bv_" .. v.Name
	                end
	            end
	        end
		    v.Parent = model
	    end
	end
end
local head = gp(model, "Head", "BasePart")
local torso = gp(model, "Torso", "BasePart") or gp(model, "UpperTorso", "BasePart")
if breakjoints then
    model:BreakJoints()
else
    if head and torso then
        for i, v in pairs(model:GetDescendants()) do
            if v:IsA("Weld") or v:IsA("Snap") or v:IsA("Glue") or v:IsA("Motor") or v:IsA("Motor6D") then
                local save = false
                if (v.Part0 == torso) and (v.Part1 == head) then
                    save = true
                end
                if (v.Part0 == head) and (v.Part1 == torso) then
                    save = true
                end
                if save then
                    if hedafterneck then
                        hedafterneck = v
                    end
                else
                    v:Destroy()
                end
            end
        end
    end
    if method == 3 then
        spawn(function()
            wait(loadtime)
            if model then
                model:BreakJoints()
            end
        end)
    end
end

cl.Parent = c
for i, v in pairs(cl:GetChildren()) do
	v.Parent = c
end
cl:Destroy()

local modelcolcon = nil
local function modelcolf()
    if model then
        for i, v in pairs(model:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = false
			end
		end
    else
        modelcolcon:Disconnect()
    end
end
modelcolcon = stepped:Connect(modelcolf)
modelcolf()

for i, scr in pairs(model:GetDescendants()) do
	if (scr.ClassName == "Script") and table.find(scriptNames, scr.Name) then
		local Part0 = scr.Parent
		if Part0:IsA("BasePart") then
			for i1, scr1 in pairs(c:GetDescendants()) do
				if (scr1.ClassName == "Script") and (scr1.Name == scr.Name) and (not scr1:IsDescendantOf(model)) then
					local Part1 = scr1.Parent
					if (Part1.ClassName == Part0.ClassName) and (Part1.Name == Part0.Name) then
						align(Part0, Part1)
						break
					end
				end
			end
		end
	end
end

if (typeof(hedafterneck) == "Instance") and head and head.Parent then
    local aligns = {}
    for i, v in pairs(head:GetDescendants()) do
        if v:IsA("AlignPosition") or v:IsA("AlignOrientation") then
            table.insert(aligns, v)
            v.Enabled = false
        end
    end
    spawn(function()
        while c and hedafterneck and hedafterneck.Parent do
            stepped:Wait()
        end
        if not (c and head and head.Parent) then
            return
        end
        for i, v in pairs(aligns) do
            pcall(function()
                v.Enabled = true
            end)
        end
    end)
end

for i, v in pairs(c:GetDescendants()) do
	if v and v.Parent then
		if v.ClassName == "Script" then
			if table.find(scriptNames, v.Name) then
				v:Destroy()
			end
		elseif not v:IsDescendantOf(model) then
			if v:IsA("Decal") then
			    v.Transparency = 1
			elseif v:IsA("ForceField") then
			    v.Visible = false
			elseif v:IsA("Sound") then
			    v.Playing = false
			elseif v:IsA("BillboardGui") or v:IsA("SurfaceGui") or v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
				v.Enabled = false
			end
		end
	end
end

if newanimate then
    local animate = gp(c, "Animate", "LocalScript")
    if animate then
        animate.Disabled = false
    end
end

if addtools then
    for i, v in pairs(c:GetChildren()) do
        if v:IsA("Tool") then
            v.Parent = addtools
        end
    end
end

local hum0 = model:FindFirstChildOfClass("Humanoid")
local hum1 = c:FindFirstChildOfClass("Humanoid")
if hum1 then
    ws.CurrentCamera.CameraSubject = hum1
    local camSubCon = nil
    local function camSubFunc()
        camSubCon:Disconnect()
        if c and hum1 and (hum1.Parent == c) then
            ws.CurrentCamera.CameraSubject = hum1
        end
    end
    camSubCon = renderstepped:Connect(camSubFunc)
	if hum0 then
		hum0.Changed:Connect(function(prop)
			if (prop == "Jump") and hum1 and hum1.Parent then
				hum1.Jump = hum0.Jump
			end
		end)
	else
	    lp.Character = nil
	    lp.Character = c
	end
end

local rb = Instance.new("BindableEvent", c)
rb.Event:Connect(function()
	rb:Destroy()
	sg:SetCore("ResetButtonCallback", true)
	if destroyhum then
	    c:BreakJoints()
	    return
	end
	if antirespawn then
	    if hum0 and hum0.Parent and (hum0.Health > 0) then
	        model:BreakJoints()
	        hum0.Health = 0
	    end
		respawnrequest()
	else
	    if hum0 and hum0.Parent and (hum0.Health > 0) then
	        model:BreakJoints()
	        hum0.Health = 0
	    end
	end
end)
sg:SetCore("ResetButtonCallback", rb)

spawn(function()
	while c do
		if hum0 and hum0.Parent and hum1 and hum1.Parent then
            hum1.Jump = hum0.Jump
        end
		wait()
	end
	sg:SetCore("ResetButtonCallback", true)
end)

R15toR6 = R15toR6 and hum1 and (hum1.RigType == Enum.HumanoidRigType.R15)
if R15toR6 then
	local cfr = nil
	pcall(function()
		cfr = gp(c, "HumanoidRootPart", "BasePart").CFrame
	end)
	if cfr then
		local R6parts = { 
			head = {
				Name = "Head",
				Size = v3(2, 1, 1),
				R15 = {
					Head = 0
				}
			},
			torso = {
				Name = "Torso",
				Size = v3(2, 2, 1),
				R15 = {
					UpperTorso = 0.2,
					LowerTorso = -0.8
				}
			},
			root = {
				Name = "HumanoidRootPart",
				Size = v3(2, 2, 1),
				R15 = {
					HumanoidRootPart = 0
				}
			},
			leftArm = {
				Name = "Left Arm",
				Size = v3(1, 2, 1),
				R15 = {
					LeftHand = -0.85,
					LeftLowerArm = -0.2,
					LeftUpperArm = 0.4
				}
			},
			rightArm = {
				Name = "Right Arm",
				Size = v3(1, 2, 1),
				R15 = {
					RightHand = -0.85,
					RightLowerArm = -0.2,
					RightUpperArm = 0.4
				}
			},
			leftLeg = {
				Name = "Left Leg",
				Size = v3(1, 2, 1),
				R15 = {
					LeftFoot = -0.85,
					LeftLowerLeg = -0.15,
					LeftUpperLeg = 0.6
				}
			},
			rightLeg = {
				Name = "Right Leg",
				Size = v3(1, 2, 1),
				R15 = {
					RightFoot = -0.85,
					RightLowerLeg = -0.15,
					RightUpperLeg = 0.6
				}
			}
		}
		for i, v in pairs(c:GetChildren()) do
			if v:IsA("BasePart") then
				for i1, v1 in pairs(v:GetChildren()) do
					if v1:IsA("Motor6D") then
						v1.Part0 = nil
					end
				end
			end
		end
		for i, v in pairs(R6parts) do
			local part = Instance.new("Part")
			part.Name = v.Name
			part.Size = v.Size
			part.CFrame = cfr
			part.Anchored = false
			part.Transparency = 1
			part.CanCollide = false
			for i1, v1 in pairs(v.R15) do
				local R15part = gp(c, i1, "BasePart")
				local att = gp(R15part, "att1_" .. i1, "Attachment")
				if R15part then
					local weld = Instance.new("Weld", R15part)
					weld.Name = "Weld_" .. i1
					weld.Part0 = part
					weld.Part1 = R15part
					weld.C0 = cf(0, v1, 0)
					weld.C1 = cf(0, 0, 0)
					R15part.Massless = true
					R15part.Name = "R15_" .. i1
				    if att then
				        att.Parent = part
				        att.Position = v3(0, v1, 0)
				        R15part.Parent = att
				    else
				        R15part.Parent = part
				    end
				end
			end
			part.Parent = c
			R6parts[i] = part
		end
		local R6joints = {
			neck = {
				Parent = R6parts.torso,
				Name = "Neck",
				Part0 = R6parts.torso,
				Part1 = R6parts.head,
				C0 = cf(0, 1, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0),
				C1 = cf(0, -0.5, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0)
			},
			rootJoint = {
				Parent = R6parts.root,
				Name = "RootJoint" ,
				Part0 = R6parts.root,
				Part1 = R6parts.torso,
				C0 = cf(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0),
				C1 = cf(0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0)
			},
			rightShoulder = {
				Parent = R6parts.torso,
				Name = "Right Shoulder",
				Part0 = R6parts.torso,
				Part1 = R6parts.rightArm,
				C0 = cf(1, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0),
				C1 = cf(-0.5, 0.5, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0)
			},
			leftShoulder = {
				Parent = R6parts.torso,
				Name = "Left Shoulder",
				Part0 = R6parts.torso,
				Part1 = R6parts.leftArm,
				C0 = cf(-1, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
				C1 = cf(0.5, 0.5, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)
			},
			rightHip = {
				Parent = R6parts.torso,
				Name = "Right Hip",
				Part0 = R6parts.torso,
				Part1 = R6parts.rightLeg,
				C0 = cf(1, -1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0),
				C1 = cf(0.5, 1, 0, 0, 0, 1, 0, 1, -0, -1, 0, 0)
			},
			leftHip = {
				Parent = R6parts.torso,
				Name = "Left Hip" ,
				Part0 = R6parts.torso,
				Part1 = R6parts.leftLeg,
				C0 = cf(-1, -1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0),
				C1 = cf(-0.5, 1, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0)
			}
		}
		for i, v in pairs(R6joints) do
			local joint = Instance.new("Motor6D")
			for prop, val in pairs(v) do
				joint[prop] = val
			end
			R6joints[i] = joint
		end
		hum1.RigType = Enum.HumanoidRigType.R6
		hum1.HipHeight = 0
	end
end

local c = game.Players.LocalPlayer.Character
local function gp(parent, name, className)
    local ret = nil
    if parent then
        for i, v in pairs(parent:GetChildren()) do
            if (v.Name == name) and v:IsA(className) then
                ret = v
            end
        end
    end
    return ret
end

--
local power = 9e9
local partName = "HumanoidRootPart"

local function gp(parent, name, className)
    local ret = nil
    if parent then
        for i, v in pairs(parent:GetChildren()) do
            if (v.Name == name) and v:IsA(className) then
                ret = v
            end
        end
    end
    return ret
end

local lp = game:GetService("Players").LocalPlayer

local m = lp:GetMouse()
local p = false
game.Players.LocalPlayer:GetMouse().KeyDown:Connect(function(KeyPressed)
 if KeyPressed == "q" then
    p = true
elseif KeyPressed == "e" then
    p = true
elseif KeyPressed == "y" then
    p = true
end

end)
game.Players.LocalPlayer:GetMouse().KeyUp:Connect(function(KeyPressed)
 if KeyPressed == "q" then
    p = false
elseif KeyPressed == "e" then
    p = false
elseif KeyPressed == "y" then
    p = false
end

end)
local c = lp.Character
if not (c and c.Parent) then
    print("character not found")
    return
end
local hrp = gp(gp(c, "Model", "Model"), partName, "BasePart")
if not hrp then
    print("part not found")
    return
end
local a = {}
for i, v in pairs(hrp:GetDescendants()) do
    if v:IsA("AlignPosition") or v:IsA("AlignOrientation") then
        table.insert(a, v)
    end
end
if hrp.Transparency > 0.5 then
    hrp.Transparency = 0.5
end
local bp = Instance.new("BodyPosition", hrp)
bp.P = 300000000000
bp.D = 5000000
bp.Name = "flingPos"
game:GetService("RunService").Stepped:Connect(function()
    if hrp and hrp.Parent and bp and bp.Parent then
        if p and m.Target then
            for i, v in pairs(a) do
                v.Enabled = false 
            end
            bp.Position = m.Hit.Position
            hrp.RotVelocity = Vector3.new(power, power, power)
            bp.Parent = hrp
        else
            for i, v in pairs(a) do
                v.Enabled = true 
            end
            if bp.Parent == hrp then
                hrp.RotVelocity = Vector3.new(0, 0, 0)
            end
            bp.Parent = c
        end
    end
end)


local att = gp(gp(gp(c, "MeshPartAccessory", "Accessory"), "Handle", "BasePart"), "att1_Handle", "Attachment")

local script = game:GetObjects("rbxassetid://9525246992")[1]

Player=game.Players.LocalPlayer
mouse = Player:GetMouse()
Character=Player.Character
Character.Humanoid.Name = "noneofurbusiness"
hum = Character.noneofurbusiness
LeftArm=Character["Left Arm"]
LeftLeg=Character["Left Leg"]
RightArm=Character["Right Arm"]
RightLeg=Character["Right Leg"]
Root=Character["HumanoidRootPart"]
Head=Character["Head"]
Torso=Character["Torso"]
RootJoint = Root["RootJoint"]
Neck = Torso["Neck"]
RightShoulder = Torso["Right Shoulder"]
LeftShoulder = Torso["Left Shoulder"]
RightHip = Torso["Right Hip"]
LeftHip = Torso["Left Hip"]
walking = false
debounce = false
attacking = false
tauntdebounce = false
themeallow = true
secondform = false

	att.Parent = c["Torso"]
att.Position = Vector3.new(0, -40, -0)
att.Orientation = Vector3.new(-0, 0, -0)

m2hallow = false
position = nil
MseGuide = true
girl = false
equipping = false
varsp = 1
settime = 0
sine = 0
sine2 = 0
ws = 120
hpheight = 1.5
change = 1
change2 = .8
dgs = 75
RunSrv = game:GetService("RunService")
RenderStepped = game:GetService("RunService").RenderStepped
removeuseless = game:GetService("Debris")
smoothen = game:GetService("TweenService")
cam = workspace.CurrentCamera
lig = game:GetService("Lighting")
local armorparts = {1,2}
local dmt2 = {1843358057,4558398377}
local bloodfolder = Instance.new("Folder",Torso)
local introable = {4591927570,4591936781,4591937586,4591937895,4591938363,4591938832,4591941299,4591941817}
local fireable = {4611185293,4611185698,4611184354,4611184817}
local firekillable = {4611187644,4611186611,4611186138}
local damagable = {1,2}
local attackable = {4614474035,4614474491,4614474930,4614475327,4614475760,4614476430,4614477011,4614477539,4614477980,4614478550,4614479082,4614479500,4614479928,4614480500,4614481083}
local cowardable = {1,2}
local followable = {4620497575,4620498118,4620498754,4620499179,4620499755}
local killable = {4673844363,4673848773,4673849571,4673877422,4673880146,4673881182,4673881958,4673882852,4673883581,4673886551,4673887593,4673892311,4673893081,4673894021}
local roarable = {1,2}
local chargable = {1,2}
local ouchable = {1,2}
local tauntable = {4563118321,4563118321}
local tauntable2 = {4592338195,4592338768,4592339199,4592340047,4592304446,4592337281,4592337771}
local rdx = {"Really black","Really red"}
local girlemy = script.enemy:Clone()
local realhead = script.head:Clone() realhead.Parent = Torso
local realhead2 = script.secondhead:Clone()
local staff = script.staff:Clone()
local energyball = script.energb:Clone()
local spkball = script.Effects.spikeball
local shckwav = script.Effects.shockwave
local spkball2 = script.Effects.ball
local explse = script.Effects.exploseball
local cards = script.cards
local wosh = script.Effects.woosh
local dox = false
local previd = nil
pcall(function()
script.intro.Parent = game:GetService("ServerStorage")
end)


RootJoint.Parent = Root
Neck.Parent = Torso
RightShoulder.Parent = Torso
LeftShoulder.Parent = Torso
RightHip.Parent = Torso
LeftHip.Parent = Torso
local fkhead = realhead.mainp
local fkhead2 = realhead2.mainp
local skully = script.skully:Clone()
local axe = script.pickaxe:Clone() axe.Parent = Torso
local skully2 = script.skullscript:Clone()

for i,v in pairs(Character:GetDescendants()) do
if v:IsA("Shirt") then v:Destroy() end end
for i,v in pairs(Character:GetDescendants()) do
if v:IsA("Pants") then v:Destroy() end end
screenGui = Instance.new("ScreenGui")
screenGui.Parent = script.Parent

local HEADLERP = Instance.new("ManualWeld")
HEADLERP.Parent = Head
HEADLERP.Part0 = Head
HEADLERP.Part1 = Torso
HEADLERP.C0 = CFrame.new(0, -1.5, -0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0))

local TORSOLERP = Instance.new("ManualWeld")
TORSOLERP.Parent = Root
TORSOLERP.Part0 = Torso
TORSOLERP.C0 = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0))

local ROOTLERP = Instance.new("ManualWeld")
ROOTLERP.Parent = Root
ROOTLERP.Part0 = Root
ROOTLERP.Part1 = Torso
ROOTLERP.C0 = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0))

local RIGHTARMLERP = Instance.new("ManualWeld")
RIGHTARMLERP.Parent = RightArm
RIGHTARMLERP.Part0 = RightArm
RIGHTARMLERP.Part1 = Torso
RIGHTARMLERP.C0 = CFrame.new(-1.5, 0, -0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0))

local LEFTARMLERP = Instance.new("ManualWeld")
LEFTARMLERP.Parent = LeftArm
LEFTARMLERP.Part0 = LeftArm
LEFTARMLERP.Part1 = Torso
LEFTARMLERP.C0 = CFrame.new(1.5, 0, -0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0))

local RIGHTLEGLERP = Instance.new("ManualWeld")
RIGHTLEGLERP.Parent = RightLeg
RIGHTLEGLERP.Part0 = RightLeg
RIGHTLEGLERP.Part1 = Torso
RIGHTLEGLERP.C0 = CFrame.new(-0.5, 2, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0))

local LEFTLEGLERP = Instance.new("ManualWeld")
LEFTLEGLERP.Parent = LeftLeg
LEFTLEGLERP.Part0 = LeftLeg
LEFTLEGLERP.Part1 = Torso
LEFTLEGLERP.C0 = CFrame.new(0.5, 2, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0))

local AXELERP = Instance.new("ManualWeld")
AXELERP.Parent = axe
AXELERP.Part0 = axe
AXELERP.Part1 = RightArm
AXELERP.C0 = CFrame.new(0.5, 2, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0))

local STAFFLERP = Instance.new("ManualWeld")
STAFFLERP.Parent = LeftArm
STAFFLERP.Part0 = nil
STAFFLERP.Part1 = nil

local function weldBetween(a, b)
    local weld = Instance.new("ManualWeld", a)
    weld.Part0 = a
    weld.Part1 = b
    weld.C0 = a.CFrame:inverse() * b.CFrame
    return weld
end
local leftlocation = Instance.new("Part",Torso)
leftlocation.Size = Vector3.new(.1,.1,.1)
leftlocation.Anchored = false
leftlocation.Massless = true
leftlocation.Transparency = 1
leftlocation.CanCollide = false
local leftlocationweld = weldBetween(leftlocation,LeftArm)
leftlocationweld.C0 = CFrame.new(0,2.05,0)
local rightlocation = Instance.new("Part",Torso)
rightlocationSize = Vector3.new(.1,.1,.1)
rightlocation.Anchored = false
rightlocation.Massless = true
rightlocation.Transparency = 1
rightlocation.CanCollide = false
local rightlocationweld = weldBetween(rightlocation,RightArm)
rightlocationweld.C0 = CFrame.new(0,2.05,0)
local leftlocation2 = Instance.new("Part",Torso)
leftlocation2.Size = Vector3.new(.1,.1,.1)
leftlocation2.Anchored = false
leftlocation2.Massless = true
leftlocation2.Transparency = 1
leftlocation2.CanCollide = false
local leftlocationweld2 = weldBetween(leftlocation2,RightLeg)
leftlocationweld2.C0 = CFrame.new(0,1.85,0)

local hdweld = weldBetween(fkhead,Head)

local shirt = Instance.new("Shirt",Character)
shirt.ShirtTemplate = "rbxassetid://215295188"
local pants = Instance.new("Pants",Character)
pants.PantsTemplate = "rbxassetid://215295280"

local a = Instance.new("Part",Torso)
a.Size = Vector3.new(1,1,1)
a.Anchored = false
a.CanCollide = false
a.Massless = true
a.Transparency = 1
a.CFrame = Root.CFrame
local aweld = weldBetween(a,Root)
local z = 0
local cardtable={}
for i,v in pairs(cards:GetChildren()) do
	table.insert(cardtable,v)
end
for i = 1, 25 do
	z = z + 20
	local randomc = math.random(1,#cardtable)
	local pick = cardtable[randomc]
	local cardo = pick:Clone() cardo.Parent = Torso cardo.Massless = true cardo.Anchored = false
	local bweld = weldBetween(cardo,a) bweld.C0 = CFrame.new(0,0,6.25) * CFrame.Angles(0,math.rad(z),0)
	bweld.C1 = CFrame.Angles(math.rad(math.random(-180,180)),math.rad(math.random(-180,180)),math.rad(math.random(-180,180)))
	coroutine.wrap(function()
		local time = .5
		local randomtime1 = math.random(-7.5,7.5)/10
		local randomtime2 = math.random(-7.5,7.5)/10
		local randomtime3 = math.random(-7.5,7.5)/10
		local anotherrandomtime = math.random(-1,1)/18
		while game:GetService("RunService").Stepped:wait() do
			bweld.C1 = bweld.C1:lerp(CFrame.Angles(math.rad(0),math.rad(time),math.rad(0)),.2)
			bweld.C0 = bweld.C0*CFrame.new(anotherrandomtime*math.sin(sine/32),anotherrandomtime*math.sin(sine/32),anotherrandomtime*math.sin(sine/32))* CFrame.Angles(math.rad(0+randomtime1),math.rad(0+randomtime2),math.rad(0+-randomtime3))
		end
	end)()
end

function MAKETRAIL(PARENT,POSITION1,POSITION2,LIFETIME,COLOR)
local A = Instance.new("Attachment", PARENT)
A.Position = POSITION1
A.Name = "A"
local B = Instance.new("Attachment", PARENT)
B.Position = POSITION2
B.Name = "B"
local x = Instance.new("Trail", PARENT)
x.Attachment0 = A
x.Attachment1 = B
x.Enabled = true
x.Lifetime = LIFETIME
x.TextureMode = "Static"
x.LightInfluence = 0
x.Color = COLOR
x.Transparency = NumberSequence.new(0, 1)
end

function ray(pos, di, ran, ignore)
	return workspace:FindPartOnRay(Ray.new(pos, di.unit * ran), ignore)
end

function ray2(StartPos, EndPos, Distance, Ignore)
local di = CFrame.new(StartPos,EndPos).lookVector
return ray(StartPos, di, Distance, Ignore)
end

function colortween(a,speed,color1)
local z = {
Color = color1
}
local tween = smoothen:Create(a,TweenInfo.new(speed,Enum.EasingStyle.Linear),z)
tween:Play()
end

function takeDamage(victim,damage)
if victim.MaxHealth < 50000 and victim ~= hum then
victim.Health = victim.Health - damage
if victim.Health < 1 then
killtaunt()
end
else
victim.Parent:BreakJoints()
killtaunt()
end
end

function death(chara)
	for i,v in pairs(chara:GetDescendants()) do
		if v:IsA("Part") or v:IsA("MeshPart") then 
			v.Transparency = 1
			local mrandom = math.random(1,2)
			if mrandom == 1 then
	local randomc = math.random(1,#cardtable)
	local pick = cardtable[randomc]
	local cardz = pick:Clone() cardz.Parent = Torso
	cardz.Size = Vector3.new(1, 0.05, 1.5)
	cardz.Transparency = 0
	cardz.Material = "Neon"
	cardz.CFrame = v.CFrame
	cardz.Anchored = false
	cardz.CanCollide = true
	removeuseless:AddItem(cardz,math.random(10,20))
			end
coroutine.wrap(function()
if tauntdebounce then return end
tauntdebounce = true
if not secondform then
local bell = Instance.new("Sound",Torso)
bell.SoundId = "rbxassetid://4577865183"
bell.Volume = 10
bell.Pitch = math.random(9,10)/10
bell:Play()
repeat swait() until bell.TimePosition > 3
rdnm2 = tauntable[math.random(1,#tauntable)]
local tauntsound = Instance.new("Sound", Head)
tauntsound.Volume = 10
tauntsound.SoundId = "rbxassetid://"..rdnm2
tauntsound.Looped = false
tauntsound.Pitch = math.random(9.5,10.5)/10
tauntsound:Play()
coroutine.wrap(function()-----futile coding
repeat swait() until tauntsound.IsPlaying == false
tauntsound:Destroy()
wait()
tauntdebounce = false
end)()
removeuseless:AddItem(tauntsound,6)
elseif secondform then
local rdnm2 = killable[math.random(1,#killable)]
for i = 1, 2 do
local tauntsound = Instance.new("Sound", Head)
tauntsound.Volume = 10
tauntsound.SoundId = "rbxassetid://"..rdnm2
tauntsound.Looped = false
tauntsound.Pitch = 1
tauntsound:Play()
coroutine.wrap(function()-----futile coding
repeat swait() until tauntsound.IsPlaying == false
tauntsound:Destroy()
wait()
tauntdebounce = false
end)()
removeuseless:AddItem(tauntsound,6)
end
end
end)()
				local soundbox = Instance.new("Part",Torso)
				soundbox.CFrame = v.CFrame
				soundbox.Anchored = true
				soundbox.CanCollide = false
				soundbox.Transparency = 1
				soundbox.Size = Vector3.new(1,1,1)
				SOUND(soundbox,4610425194,10,false,math.random(9,11)/10,5)
				removeuseless:AddItem(soundbox,5)
			local clone = v:Clone() clone.Parent = Torso clone.Transparency = 0
			local a = Instance.new("Part",Torso)
			a.Anchored = true
			a.CanCollide = false
			a.Transparency = 1
			a.CFrame = v.CFrame * CFrame.new(math.random(-10,10),math.random(-10,10),math.random(-5,10))
			coroutine.wrap(function()
				local z1 = math.random(-180,180)
				local z2 = math.random(-180,180)
				local z3 = math.random(-180,180)
				clone.Anchored = true
				clone.CanCollide = false
				for i = 1, 40 do
					clone.Transparency = clone.Transparency + .05
					clone.CFrame = clone.CFrame:lerp(CFrame.new(a.Position)*CFrame.Angles(math.rad(z1),math.rad(z2),math.rad(z3)),.125)
					swait()
				end
				a:Destroy()
				clone:Destroy()
			end)()
		end
	end
	chara:Destroy()
end

function taunt()
coroutine.wrap(function()
if tauntdebounce then return end
tauntdebounce = true
if not secondform then
local bell = Instance.new("Sound",Torso)
bell.SoundId = "rbxassetid://4577865183"
bell.Volume = 10
bell.Pitch = math.random(9,10)/10
bell:Play()
repeat swait() until bell.TimePosition > 3
rdnm2 = tauntable[math.random(1,#tauntable)]
local tauntsound = Instance.new("Sound", Head)
tauntsound.Volume = 10
tauntsound.SoundId = "rbxassetid://"..rdnm2
tauntsound.Looped = false
tauntsound.Pitch = math.random(9.5,10.5)/10
tauntsound:Play()
coroutine.wrap(function()-----futile coding
repeat swait() until tauntsound.IsPlaying == false
tauntsound:Destroy()
wait()
tauntdebounce = false
end)()
removeuseless:AddItem(tauntsound,6)
elseif secondform then
local rdnm2 = tauntable2[math.random(1,#tauntable2)]
for i = 1, 2 do
local tauntsound = Instance.new("Sound", Head)
tauntsound.Volume = 10
tauntsound.SoundId = "rbxassetid://"..rdnm2
tauntsound.Looped = false
tauntsound.Pitch = 1
tauntsound:Play()
coroutine.wrap(function()-----futile coding
repeat swait() until tauntsound.IsPlaying == false
tauntsound:Destroy()
wait()
tauntdebounce = false
end)()
removeuseless:AddItem(tauntsound,6)
end
end
end)()
end

function attacktaunt2()
coroutine.wrap(function()
if tauntdebounce then return end
tauntdebounce = true
local rdnm2 = followable[math.random(1,#followable)]
for i = 1, 2 do
tauntsound = Instance.new("Sound", Head)
tauntsound.Volume = 10
tauntsound.SoundId = "rbxassetid://"..rdnm2
tauntsound.Looped = false
tauntsound.Pitch = 1
tauntsound:Play()
coroutine.wrap(function()-----futile coding
repeat swait() until tauntsound.IsPlaying == false
tauntsound:Destroy()
wait()
tauntdebounce = false
end)()
removeuseless:AddItem(tauntsound,6)
end
end)()
end

function attacktaunt()
coroutine.wrap(function()
if tauntdebounce then return end
tauntdebounce = true
local rdnm2 = attackable[math.random(1,#attackable)]
for i = 1, 2 do
tauntsound = Instance.new("Sound", Head)
tauntsound.Volume = 10
tauntsound.SoundId = "rbxassetid://"..rdnm2
tauntsound.Looped = false
tauntsound.Pitch = 1
tauntsound:Play()
coroutine.wrap(function()-----futile coding
repeat swait() until tauntsound.IsPlaying == false
tauntsound:Destroy()
wait()
tauntdebounce = false
end)()
removeuseless:AddItem(tauntsound,6)
end
end)()
end

function killtaunt()
coroutine.wrap(function()
if tauntdebounce then return end
tauntdebounce = true
local rdnm2 = killable[math.random(1,#killable)]
for i = 1, 3 do
coroutine.wrap(function()
tauntsound = Instance.new("Sound", Head)
tauntsound.Volume = 10
tauntsound.SoundId = "http://www.roblox.com/asset/?id="..rdnm2
tauntsound.Looped = false
tauntsound.Pitch = 1
tauntsound:Play()
wait(.5)
wait(tauntsound.TimeLength)
tauntsound:Destroy()
tauntdebounce = false
end)()
end
end)()
end

function velo(a,name,pos,speed)
local bov = Instance.new("BodyVelocity",a)
bov.Name = name
bov.maxForce = Vector3.new(99999,99999,99999)
a.CFrame = CFrame.new(a.Position,pos)
bov.velocity = a.CFrame.lookVector*speed
end
function bolt(parent,from,too,endtarget,color,size,mat,offset)
local function iray(pos, di, ran, ignore)
local ing={endtarget}
	return workspace:FindPartOnRayWithWhitelist(Ray.new(pos, di.unit * ran),ing)
end
local function iray2(StartPos, EndPos, Distance, Ignore)
local di = CFrame.new(StartPos,EndPos).lookVector
return iray(StartPos, di, Distance, Ignore)
end
lastposition = from
local step = 16
local distance = (from-too).magnitude
for i = 1,distance, step do
local from = lastposition
local too = from + -(from-too).unit*step+ Vector3.new(math.random(-offset,offset),math.random(-offset,offset),math.random(-offset,offset))
local bolt = Instance.new("Part",parent)
bolt.Size = Vector3.new(size,size,(from-too).magnitude)
bolt.Anchored = true
bolt.CanCollide = false
bolt.Name = "supeffect"
bolt.BrickColor = color
bolt.Material = mat
bolt.CFrame = CFrame.new(from:lerp(too,.5),too)
lastposition = too
coroutine.wrap(function()
for i = 1, 5 do
bolt.Transparency = bolt.Transparency + .2
wait()
end
bolt:Destroy()
end)()
end
local lastbolt = Instance.new("Part",parent)
lastbolt.Size = Vector3.new(1,1,(from-too).magnitude)
lastbolt.Anchored = true
lastbolt.CanCollide = false
lastbolt.BrickColor = color
lastbolt.Name = "supeffect"
lastbolt.Material = mat
lastbolt.CFrame = CFrame.new(lastposition,too)
lastbolt.Size = Vector3.new(size,size,size)
local start = lastposition
local hit,endp = iray2(lastposition,too,650,lastbolt)
local dis = (start - endp).magnitude
lastbolt.CFrame = CFrame.new(lastposition,too) * CFrame.new(0,0,-dis/2)
if dis < 20 then
lastbolt.Size = Vector3.new(size,size,dis)
else
lastbolt.Size = Vector3.new(size,size,20)
end
coroutine.wrap(function()
for i = 1, 5 do
lastbolt.Transparency = lastbolt.Transparency + .2
wait()
end
lastbolt:Destroy()
end)()
end
function littlebolt(parent,from,too,endtarget,color,size,mat,offset)
local function iray(pos, di, ran, ignore)
local ing={endtarget}
	return workspace:FindPartOnRayWithWhitelist(Ray.new(pos, di.unit * ran),ing)
end
local function iray2(StartPos, EndPos, Distance, Ignore)
local di = CFrame.new(StartPos,EndPos).lookVector
return iray(StartPos, di, Distance, Ignore)
end
lastposition = from
local step = 1
local distance = (from-too).magnitude
for i = 1,distance, step do
local from = lastposition
local too = from + -(from-too).unit*step+ Vector3.new(math.random(-offset,offset),math.random(-offset,offset),math.random(-offset,offset))
local bolt = Instance.new("Part",parent)
bolt.Size = Vector3.new(size,size,(from-too).magnitude)
bolt.Anchored = true
bolt.CanCollide = false
bolt.Name = "supeffect"
bolt.BrickColor = color
bolt.Material = mat
bolt.CFrame = CFrame.new(from:lerp(too,.5),too)
lastposition = too
coroutine.wrap(function()
for i = 1, 5 do
bolt.Transparency = bolt.Transparency + .2
wait()
end
bolt:Destroy()
end)()
end
local lastbolt = Instance.new("Part",parent)
lastbolt.Size = Vector3.new(1,1,(from-too).magnitude)
lastbolt.Anchored = true
lastbolt.CanCollide = false
lastbolt.BrickColor = color
lastbolt.Name = "supeffect"
lastbolt.Material = mat
lastbolt.CFrame = CFrame.new(lastposition,too)
lastbolt.Size = Vector3.new(size,size,size)
local start = lastposition
local hit,endp = iray2(lastposition,too,650,lastbolt)
local dis = (start - endp).magnitude
lastbolt.CFrame = CFrame.new(lastposition,too) * CFrame.new(0,0,-dis/2)
if dis < 20 then
lastbolt.Size = Vector3.new(size,size,dis)
else
lastbolt.Size = Vector3.new(size,size,20)
end
coroutine.wrap(function()
for i = 1, 5 do
lastbolt.Transparency = lastbolt.Transparency + .2
wait()
end
lastbolt:Destroy()
end)()
end
function ballshockwave(position,transparency,brickcolor,mate,transparencyincrease,size)
local borb = Instance.new("Part",Torso)
borb.Anchored = true
borb.CanCollide = false
borb.Shape = "Ball"
borb.Name = "supeffect"
borb.Transparency = transparency
borb.Size = Vector3.new(1,1,1)
borb.Material = mate
borb.BrickColor = brickcolor
borb.CFrame = position
coroutine.wrap(function()
while borb.Transparency < 1 do
borb.Size = borb.Size + size
borb.Transparency = borb.Transparency + transparencyincrease
swait()
end
borb:Destroy()
end)()
end

dmt2random = dmt2[math.random(1,#dmt2)]
doomtheme = Instance.new("Sound", Torso)
doomtheme.Volume = 4
doomtheme.Name = "doomtheme"
doomtheme.Looped = false
doomtheme.SoundId = "rbxassetid://"..dmt2random
previd = dmt2random
doomtheme:Play()
coroutine.wrap(function()
while wait() do
pcall(function()
doomtheme.Ended:Wait()
doomtheme.Name = "removing"
doomtheme:Destroy()
doomtheme = Instance.new("Sound", Torso)
doomtheme.Volume = 4
doomtheme.Name = "doomtheme"
doomtheme.Looped = false
repeat dmt2random = dmt2[math.random(1,#dmt2)] until dmt2random ~= previd
doomtheme.SoundId = "rbxassetid://"..dmt2random
doomtheme:Play()
end)
end
end)()

Torso.ChildRemoved:connect(function(removed)
if removed.Name == "doomtheme" then
dmt2random = dmt2[math.random(1,#dmt2)]
doomtheme = Instance.new("Sound",Torso)
doomtheme.SoundId = "rbxassetid://"..dmt2random
doomtheme.Name = "doomtheme"
doomtheme.Looped = true
doomtheme.Volume = 5
doomtheme:Play()
end
end)

coroutine.wrap(function()
while wait() do
hum.WalkSpeed = ws
hum.JumpPower = 80
end
end)()
godmode = coroutine.wrap(function()
for i,v in pairs(Character:GetChildren()) do
if v:IsA("BasePart") and v ~= Root then
v.Anchored = false
end
end
while true do
hum.MaxHealth = math.huge
wait(0.0000001)
hum.Health = math.huge
swait()
end
end)
godmode()
ff = Instance.new("ForceField", Character)
ff.Visible = false

pcall(function()
----defaultpos----
LEFTARMLERP.C0 = LEFTARMLERP.C0:lerp(CFrame.new(1.5,0,0) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)), 0.2)
RIGHTARMLERP.C0 = RIGHTARMLERP.C0:lerp(CFrame.new(-1.5,0,0) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)), 0.2)
ROOTLERP.C0 = ROOTLERP.C0:lerp(CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)),.2)
RIGHTLEGLERP.C0 = RIGHTLEGLERP.C0:lerp(CFrame.new(-.5, 2, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)), 0.2)
LEFTLEGLERP.C0 = LEFTLEGLERP.C0:lerp(CFrame.new(0.5, 2, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0)), 0.2)
----defaultpos----
end)

function damagealll(Radius,Position)		
	local Returning = {}		
	for _,v in pairs(workspace:GetChildren()) do		
		if v~=Character and v:FindFirstChildOfClass('Humanoid') and v:FindFirstChild('Torso') or v:FindFirstChild('UpperTorso') then
if v:FindFirstChild("Torso") then		
			local Mag = (v.Torso.Position - Position).magnitude		
			if Mag < Radius then		
				table.insert(Returning,v)		
			end
elseif v:FindFirstChild("UpperTorso") then	
			local Mag = (v.UpperTorso.Position - Position).magnitude		
			if Mag < Radius then		
				table.insert(Returning,v)		
			end
end	
		end		
	end		
	return Returning		
end

function swait(num)
	if num == 0 or num == nil then
		game:service("RunService").Stepped:wait(0)
	else
		for i = 0, num do
			game:service("RunService").Stepped:wait(0)
		end
	end
end

function SOUND(PARENT,ID,VOL,LOOP,PITCH,REMOVE)
local so = Instance.new("Sound")
so.Parent = PARENT
so.SoundId = "rbxassetid://"..ID
so.Volume = VOL
so.Looped = LOOP
so.Pitch = PITCH
so:Play()
removeuseless:AddItem(so,REMOVE)
end

function meshify(parent,scale,mid,tid)
local mesh = Instance.new("SpecialMesh",parent)
mesh.Name = "mesh"
mesh.Scale = scale
mesh.MeshId = "rbxassetid://"..mid
mesh.TextureId = "rbxassetid://"..tid
end
function blocktrail(position,size,trans,mat,color)
local trailblock = Instance.new("Part",Torso)
trailblock.Anchored = true
trailblock.CanCollide = false
trailblock.Transparency = trans
trailblock.Material = mat
trailblock.BrickColor = color
trailblock.CFrame = CFrame.new(position) * CFrame.Angles(math.rad(math.random(-180,180)),math.rad(math.random(-180,180)),math.rad(math.random(-180,180)))
trailblock.Size = size
coroutine.wrap(function()
while trailblock.Transparency < 1 do
trailblock.Transparency = trailblock.Transparency + trans/10
trailblock.Size = trailblock.Size - trailblock.Size/20
swait()
end
trailblock:Destroy()
end)()
end

function blood(parent,intensity)
coroutine.wrap(function()
local particlemiter1 = Instance.new("ParticleEmitter", parent)
particlemiter1.Enabled = true
particlemiter1.Color = ColorSequence.new(BrickColor.new("Crimson").Color)
particlemiter1.Texture = "rbxassetid://1391189545"
particlemiter1.Lifetime = NumberRange.new(.6)
particlemiter1.Size = NumberSequence.new(3,3)
particlemiter1.Transparency = NumberSequence.new(0,1)
particlemiter1.Rate = intensity
particlemiter1.Rotation = NumberRange.new(0,360)
particlemiter1.Speed = NumberRange.new(6)
particlemiter1.SpreadAngle = Vector2.new(180,180)
wait(.2)
particlemiter1.Enabled = false
removeuseless:AddItem(particlemiter1,10)
end)()
coroutine.wrap(function()
for i = 1, intensity/20 do
local ray = Ray.new(parent.Position, Vector3.new(0,-25,0))
local part, hitPosition = workspace:FindPartOnRayWithIgnoreList(ray, {bloodfolder,parent.Parent,bloc,Character,blooddecal,blowd,Torso},false,true)
if part and part.Parent ~= parent.Parent and not part.Parent:FindFirstChildOfClass("Humanoid") then
local vbn = math.random(5,15)
coroutine.wrap(function()
local blooddecal = Instance.new("Part",bloodfolder)
blooddecal.Size =  Vector3.new(vbn,.1,vbn)
blooddecal.Transparency = 1
blooddecal.Anchored = true
blooddecal.Name = "blowd"
blooddecal.CanCollide = false
blooddecal.Position = hitPosition 
blooddecal.Rotation = Vector3.new(0,math.random(-180,180),0)
local blood = Instance.new("Decal",blooddecal)
blood.Face = "Top"
blood.Texture = "rbxassetid://1391189545"
blood.Transparency = math.random(.1,.4)
wait(60)
for i = 1, 100 do
blood.Transparency = blood.Transparency + .01
swait()
end
blooddecal:Destroy()
end)()
else
end
swait()
end
end)()
end
function spikeball(position,scale,brickcolor,transparencyincrease,mat)
coroutine.wrap(function()
local spikeball = spkball:Clone() spikeball.Parent = Torso
spikeball.Anchored = true
spikeball.CanCollide = false
spikeball.Size = Vector3.new(1,1,1)
spikeball.BrickColor = brickcolor
spikeball.CFrame = position
spikeball.Transparency = .85
spikeball.Material = mat
while spikeball.Transparency < 1 do
spikeball.CFrame = spikeball.CFrame * CFrame.Angles(math.rad(0+math.random(7,14)),math.rad(0+math.random(16,21)),math.rad(0+math.random(23,29)))
spikeball.Size = spikeball.Size + scale*4
spikeball.Transparency = spikeball.Transparency + transparencyincrease/10
swait()
end
spikeball:Destroy()
end)()
end
function shockwave(position,scale,transparency,brickcolor,speed,transparencyincrease,mat)
coroutine.wrap(function()
local shockwave = shckwav:Clone() shockwave.Parent = Torso
shockwave.Size = Vector3.new(1,1,1)
shockwave.CanCollide = false
shockwave.Anchored = true
shockwave.Transparency = transparency
shockwave.BrickColor = brickcolor
shockwave.Material = mat
shockwave.CFrame = position * CFrame.new(0,scale.Y*1.25,0)
local shockwave2 = shckwav:Clone() shockwave2.Parent = Torso
shockwave2.Size = Vector3.new(1,1,1)
shockwave2.CanCollide = false
shockwave2.Anchored = true
shockwave2.Transparency = shockwave.Transparency
shockwave2.BrickColor = shockwave.BrickColor
shockwave2.CFrame = shockwave.CFrame
shockwave2.Material = mat
while shockwave.Transparency < 1 do
shockwave.CFrame = shockwave.CFrame * CFrame.Angles(math.rad(0),math.rad(0+speed),0)
shockwave2.CFrame = shockwave2.CFrame * CFrame.Angles(math.rad(0),math.rad(0-speed),0)
shockwave.Transparency = shockwave.Transparency + transparencyincrease
shockwave2.Transparency = shockwave2.Transparency + transparencyincrease
shockwave2.Size = shockwave2.Size + scale
shockwave.Size = shockwave.Size + scale
swait()
end
shockwave:Destroy()
shockwave2:Destroy()
end)()
end

function blockyeffect(brickcolor,size,trans,posi,mater,spread)
local blocky = Instance.new("Part",Torso)
blocky.Anchored = true
blocky.CanCollide = false
blocky.BrickColor = brickcolor
blocky.Size = size
blocky.Transparency = trans
blocky.CFrame = posi * CFrame.Angles(math.rad(math.random(-180,180)),math.rad(math.random(-180,180)),math.rad(math.random(-180,180)))
blocky.Material = mater
local locbloc = Instance.new("Part",Torso)
locbloc.Anchored = true
locbloc.CanCollide = false
locbloc.Transparency = 1
locbloc.Size = Vector3.new(1,1,1)
locbloc.CFrame = blocky.CFrame * CFrame.new(math.random(-spread,spread),math.random(-spread,spread),math.random(-spread,spread))
coroutine.wrap(function()
local a = math.random(-180,180)
local b = math.random(-180,180)
local c = math.random(-180,180)
for i = 1, 20 do
blocky.CFrame = blocky.CFrame:lerp(CFrame.new(locbloc.Position) * CFrame.Angles(math.rad(a),math.rad(b),math.rad(c)),.2)
blocky.Transparency = blocky.Transparency + .05
swait()
end
blocky:Destroy()
locbloc:Destroy()
end)()
end

Head.BrickColor = BrickColor.new("Really black")
Torso.BrickColor = Head.BrickColor
LeftArm.BrickColor = Head.BrickColor
RightArm.BrickColor = Head.BrickColor
RightLeg.BrickColor = Head.BrickColor
LeftLeg.BrickColor = Head.BrickColor

Head.face:Destroy()

coroutine.wrap(function()
for i,v in pairs(Character:GetChildren()) do
if v.Name == "Animate" then
end
end
end)()

for _,v in pairs(game.Players.LocalPlayer.Character.Torso.head:GetChildren()) do
	if v:IsA("BasePart") then
		v.Transparency = 1
	end
end

coroutine.wrap(function()
		for i,v in pairs(Character:GetDescendants()) do
		if v:IsA("BodyVelocity") then
			v:Destroy()
		end
	end
	Character.Parent = workspace
	local det = Instance.new("Part",Torso)
	det.Anchored = true
	det.CanCollide = false
	det.Size = Vector3.new(1,1,1)
	det.Transparency = 1
	det.CFrame = CFrame.new(0,0,0)
	while wait() do
	script.Parent = Player.PlayerGui
	local char = script.char char.PrimaryPart = char.HumanoidRootPart
	local cfr = char:GetPrimaryPartCFrame()
	local ncfr = CFrame.new(Root.Position)
	local ncfr2 = CFrame.new(det.Position)
	local ma = (det.Position - Root.Position).Magnitude
	if ma > 1000 then
	char:SetPrimaryPartCFrame(ncfr2)
	else
	char:SetPrimaryPartCFrame(ncfr)
	end
	if Root.Parent == nil then
	char:SetPrimaryPartCFrame(CFrame.new(0,0,0))
	end
if Character.Parent == nil then
	pcall(function()
	Character:Destroy()
	end)
	local char = script.char
	local char2 = char:Clone()
	local kkk = realhead:Clone()
	local scripty = script.mousthingy:Clone()
	local fakechar = char:Clone() fakechar.Parent = workspace fakechar.Name = Player.Name
	Player.Character = fakechar
	local mainscript = script:Clone() kkk.Parent = mainscript char2.Parent = mainscript scripty.Parent = mainscript mainscript.Parent = Player.PlayerGui
	script:Destroy()
end
		end
end)()
mouse.KeyDown:connect(function(Press)
Press=Press:lower()
if Press=='m' then
if not tauntdebounce then
rdnm2 = damagable[math.random(1,#damagable)]
local pcs = Instance.new("Sound",script.char.Head)
pcs.SoundId = "rbxassetid://"..rdnm2
pcs.Volume = 10
pcs.Name = "pcs"
removeuseless:AddItem(pcs,15)
end
	local char = script.char
	local char2 = char:Clone()
	local scripty = script.mousthingy:Clone()
	local kkk = realhead:Clone()
	local effects = script.Effects:Clone()
	local fakechar = char:Clone() fakechar.Parent = workspace fakechar.Name = Player.Name
	Player.Character = fakechar
	local mainscript = script:Clone() chain.Parent = mainscript effects.Parent = mainscript kkk.Parent = mainscript char2.Parent = mainscript scripty.Parent = mainscript mainscript.Parent = Player.PlayerGui
		script:Destroy()
	for i,v in pairs(Player.Character:GetDescendants()) do
		if v:IsA("BodyVelocity") then
			v:Destroy()
		end
	end
elseif Press=='y' then
	if secondform then
	if debounce then return end
	debounce = true
	attacking = true
		attacktaunt()
local g1 = Instance.new("BodyGyro", nil)
g1.CFrame = Root.CFrame
g1.Parent = Root
g1.D = 175
g1.P = 20000
g1.MaxTorque = Vector3.new(500,90000,500)
		for i = 1, 20 do
			g1.CFrame = g1.CFrame:lerp(CFrame.new(Root.Position,mouse.Hit.p),.09)
			HEADLERP.C0 = HEADLERP.C0:lerp(CFrame.new(0.1,-1.5,-0.1)*CFrame.Angles(math.rad(3),math.rad(-24.5),math.rad(2.8))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
			LEFTARMLERP.C0 = LEFTARMLERP.C0:lerp(CFrame.new(1.3,2.4,-0.3)*CFrame.Angles(math.rad(-112.8),math.rad(-37.1),math.rad(8.4))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
			LEFTLEGLERP.C0 = LEFTLEGLERP.C0:lerp(CFrame.new(0.3,2.5,0.6)*CFrame.Angles(math.rad(-10.9),math.rad(-32),math.rad(20.3))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
			RIGHTARMLERP.C0 = RIGHTARMLERP.C0:lerp(CFrame.new(-0.8,-0.7,0.3)*CFrame.Angles(math.rad(171.5),math.rad(79.5),math.rad(-109.6))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
			RIGHTLEGLERP.C0 = RIGHTLEGLERP.C0:lerp(CFrame.new(-0.6,1.7,1.6)*CFrame.Angles(math.rad(28.7),math.rad(12.7),math.rad(-11.1))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
			STAFFLERP.C0 = STAFFLERP.C0:lerp(CFrame.new(0.7,-1.5,0.4)*CFrame.Angles(math.rad(161.4),math.rad(-0.5),math.rad(-26.5))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
			ROOTLERP.C0 = ROOTLERP.C0:lerp(CFrame.new(0,0,0)*CFrame.Angles(math.rad(-21.6),math.rad(-35.3),math.rad(7))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
			swait()
		end
		spikeball(st.shbox.CFrame,Vector3.new(.25,.25,.25),BrickColor.new("White"),.05,"Neon")
		ballshockwave(st.shbox.CFrame,.05,BrickColor.new("White"),"Neon",.05,Vector3.new(.6,.6,.6))
		coroutine.wrap(function()
		for i = 1, 10 do
			HEADLERP.C0 = HEADLERP.C0:lerp(CFrame.new(0,-1.4,-0.4)*CFrame.Angles(math.rad(17.9),math.rad(-24.5),math.rad(2.8))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.4)
			LEFTARMLERP.C0 = LEFTARMLERP.C0:lerp(CFrame.new(1.3,2.4,-0.3)*CFrame.Angles(math.rad(-112.8),math.rad(-37.1),math.rad(8.4))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.4)
			LEFTLEGLERP.C0 = LEFTLEGLERP.C0:lerp(CFrame.new(0.1,2.5,1.3)*CFrame.Angles(math.rad(22.1),math.rad(-28.7),math.rad(31.3))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.4)
			RIGHTARMLERP.C0 = RIGHTARMLERP.C0:lerp(CFrame.new(-1.5,-0.4,0.3)*CFrame.Angles(math.rad(117.5),math.rad(66.9),math.rad(-53.7))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.4)
			RIGHTLEGLERP.C0 = RIGHTLEGLERP.C0:lerp(CFrame.new(-0.5,2,1.3)*CFrame.Angles(math.rad(28.7),math.rad(12.7),math.rad(-11.1))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.4)
			STAFFLERP.C0 = STAFFLERP.C0:lerp(CFrame.new(0.6,-1.4,0.9)*CFrame.Angles(math.rad(83.9),math.rad(-0.5),math.rad(-26.5))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.4)
			ROOTLERP.C0 = ROOTLERP.C0:lerp(CFrame.new(-.2,0,2)*CFrame.Angles(math.rad(7.5),math.rad(-28.7),math.rad(22.7))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.4)
			swait()
		end
		g1:Destroy()
		debounce = false
		attacking = false
		end)()
		local shpos = Root
		for i = 1, 3 do
			local hbx = Instance.new("Part",Torso)
			hbx.Size = Vector3.new(1,1,1)
			hbx.CanCollide = false
			hbx.Anchored = true
			hbx.Transparency = 1
			hbx.CFrame = shpos.CFrame * CFrame.new(math.random(-20,20),math.random(5,25),math.random(-20,-12))
	local randomc = math.random(1,#cardtable)
	local pick = cardtable[randomc]
	local card = pick:Clone() card.CanCollide = false card.Parent = Torso card.Size = Vector3.new(2.5,.25,1.75) card.Anchored = true card.CFrame = st.shbox.CFrame
	local ae = explse:Clone() ae.Anchored = false ae.Parent = Torso local aeweld = weldBetween(ae,card)
	SOUND(card,1544022435,8,false,math.random(9,11)/10,10)
	SOUND(card,1843578719,8,false,math.random(9,11)/10,10)
	coroutine.wrap(function()
		local hitz = false
		for i = 1, 12 do
			card.CFrame = card.CFrame:lerp(CFrame.new(hbx.Position),.2)
			swait()
		end
		hbx:Destroy()
		card.Anchored = false
		velo(card,"vel",mouse.Hit.p,310)
		card.Touched:Connect(function(hit)
			if hit.Parent ~= Character and hit.Parent.Parent ~= Character then
				for i,v in pairs(ae:GetDescendants()) do
					if v:IsA("ParticleEmitter") then v.Enabled = false end
				end
				removeuseless:AddItem(card,10)
				removeuseless:AddItem(ae,10)
				hitz = true
						local hit = damagealll(43,card.Position)
		for _,v in pairs(hit) do
        if v:FindFirstChildOfClass("Humanoid") and v:FindFirstChildOfClass("Humanoid").Health > 0 then
	--death(v:FindFirstChildOfClass("Humanoid").Parent)
    end
end
				card.Anchored = true
				card.Size = Vector3.new(.1,.1,.1)
				card.Transparency = 1
				ballshockwave(card.CFrame,.05,BrickColor.new("White"),"Neon",.05,Vector3.new(3,3,3))
				ballshockwave(card.CFrame,.05,BrickColor.new("White"),"Neon",.05,Vector3.new(3,3,3)/2)
				ballshockwave(card.CFrame,.05,BrickColor.new("White"),"Neon",.05,Vector3.new(3,3,3)*2)
				spikeball(card.CFrame,Vector3.new(2.5,2.5,2.5),BrickColor.new("Really red"),.05,"Neon")
				spikeball(card.CFrame,Vector3.new(2.75,2.75,2.75)/2,BrickColor.new("White"),.05,"Neon")
	shockwave(CFrame.new(card.Position),Vector3.new(9,4,9)/1.5,.5,BrickColor.new("White"),math.random(5,8),.0125,"Neon")
	shockwave(CFrame.new(card.Position),Vector3.new(12,1,12)/1.5,.5,BrickColor.new("White"),math.random(2,6),.0125,"Neon")
			end
		end)
		coroutine.wrap(function()
			for i = 1, 900 do
				if hitz then break end
				swait()
			end
			if not hitz then
				hitz = true
								for i,v in pairs(ae:GetDescendants()) do
					if v:IsA("ParticleEmitter") then v.Enabled = false end
				end
				removeuseless:AddItem(card,10)
				removeuseless:AddItem(ae,10)
				hitz = true
				card.Anchored = true
				card.Size = Vector3.new(.1,.1,.1)
				card.Transparency = 1
			end
		end)()
	end)()
		end
end

elseif Press=='q' then
	if secondform then
	if debounce then return end
	debounce = true
	attacking = true
	ws = 0
	local marandom = math.random(1,2)
	if marandom == 1 then
	coroutine.wrap(function()
if tauntdebounce then return end
tauntdebounce = true
local rdnm2 = fireable[math.random(1,#fireable)]
for i = 1, 2 do
local tauntsound = Instance.new("Sound", Head)
tauntsound.Volume = 10
tauntsound.SoundId = "rbxassetid://"..rdnm2
tauntsound.Looped = false
tauntsound.Pitch = 1
tauntsound:Play()
coroutine.wrap(function()-----futile coding
repeat swait() until tauntsound.IsPlaying == false
tauntsound:Destroy()
wait()
tauntdebounce = false
end)()
removeuseless:AddItem(tauntsound,12)
end
	end)()
	end
	local a = 0
		local g1 = Instance.new("BodyGyro", nil)
g1.CFrame = Root.CFrame
g1.Parent = Root
g1.D = 175
g1.P = 20000
g1.MaxTorque = Vector3.new(3000,90000,3000)
local spin = Instance.new("Sound",st.shbox)
spin.SoundId = "rbxassetid://4255432837"
spin.Volume = 8
spin.Pitch = 1.15
spin.Looped = true
spin:Play()
for i = 1, 30 do
	a = a + 30
	g1.CFrame = g1.CFrame:lerp(CFrame.new(Root.Position,mouse.Hit.p),.09)
	blocktrail(st.shbox.Position,Vector3.new(1,1,1),.05,"Neon",BrickColor.new("Really red"))
	HEADLERP.C0 = HEADLERP.C0:lerp(CFrame.new(-0.1,-1.5,0)*CFrame.Angles(math.rad(1.6),math.rad(26),math.rad(-2.4))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25/2)
	LEFTARMLERP.C0 = LEFTARMLERP.C0:lerp(CFrame.new(1.3,1.7,0.9)*CFrame.Angles(math.rad(-145.3),math.rad(-5),math.rad(-26.2))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25/2)
	LEFTLEGLERP.C0 = LEFTLEGLERP.C0:lerp(CFrame.new(0.3,1.7,1.4)*CFrame.Angles(math.rad(8.8),math.rad(-27.1),math.rad(0.5))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25/2)
	RIGHTARMLERP.C0 = RIGHTARMLERP.C0:lerp(CFrame.new(-0.8,-0.7,0.3)*CFrame.Angles(math.rad(171.5),math.rad(79.5),math.rad(-109.6))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25/2)
	RIGHTLEGLERP.C0 = RIGHTLEGLERP.C0:lerp(CFrame.new(-0.6,1.7,1.6)*CFrame.Angles(math.rad(28.7),math.rad(12.7),math.rad(-11.1))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25/2)
	STAFFLERP.C0 = STAFFLERP.C0:lerp(CFrame.new(0.5,-0.2,1)*CFrame.Angles(math.rad(92.6),math.rad(10.8),math.rad(-21.9))*CFrame.Angles(math.rad(a/2),math.rad(0),math.rad(a)),.25/2)
	ROOTLERP.C0 = ROOTLERP.C0:lerp(CFrame.new(0,0,0)*CFrame.Angles(math.rad(-21),math.rad(27.3),math.rad(-0.5))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25/2)
	swait()
end
ws = 6
spin:Destroy()
local fireamb = Instance.new("Sound",st.shbox)
fireamb.SoundId = "rbxassetid://1301200629"
fireamb.Volume = 0
fireamb.Pitch = math.random(9,11)/10
fireamb.Looped = true
fireamb:Play()
for i = 1, 150 do
	fireamb.Volume = fireamb.Volume + .5
	g1.CFrame = g1.CFrame:lerp(CFrame.new(Root.Position,mouse.Hit.p),.09)
	local zz = math.random(1,2)
	if zz == 1 then
	local rrandom = rdx[math.random(1,#rdx)]
	local locater = Instance.new("Part",Torso)
	locater.Size = Vector3.new(2,2,2)
	locater.Anchored = false
	locater.CanCollide = false
	locater.Transparency = 1
	locater.Massless = true
	locater.CFrame = Root.CFrame*CFrame.new(0,0,-5)
	spikeball(locater.CFrame,Vector3.new(2,2,2),BrickColor.new(rrandom),.25,"Neon")
	local fire = Instance.new("Part",Torso)
	fire.Anchored = false
	fire.CanCollide = false
	fire.Massless = true
	fire.Material = "Neon"
	fire.BrickColor = BrickColor.new(rrandom)
	fire.Size = Vector3.new(1,1,1)
	fire.Transparency = 1
	local fireweld = weldBetween(fire,locater) fireweld.C0 = fireweld.C0 * CFrame.Angles(math.rad(math.random(-180,180)),math.rad(math.random(-180,180)),math.rad(math.random(-180,180)))
	fire.Touched:Connect(function(hit)
		if hit.Parent ~= nil and hit.Parent:FindFirstChildOfClass("Humanoid") and hit.Parent:FindFirstChildOfClass("Humanoid") ~= hum then
		end
	end)
coroutine.wrap(function()
	velo(locater,"velo",mouse.Hit.p,250)
		for i = 1, 40 do
			fire.Size = fire.Size + Vector3.new(.7,.7,.7)
			 fire.Transparency = fire.Transparency - .025
			swait()
		end
		for i = 1, 20 do
			fire.Transparency = fire.Transparency + .05
			swait()
		end
		locater:Destroy()
		fire:Destroy()
end)()
end
	STAFFLERP.C0 = STAFFLERP.C0:lerp(CFrame.new(-0.2,-0.5,1.1)*CFrame.Angles(math.rad(103.5),math.rad(-15.3),math.rad(7.2))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
	HEADLERP.C0 = HEADLERP.C0:lerp(CFrame.new(0,-1.5,-0.1)*CFrame.Angles(math.rad(1.9),math.rad(-38.4),math.rad(-0.6))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
	LEFTARMLERP.C0 = LEFTARMLERP.C0:lerp(CFrame.new(1.9,1.8,-0.1)*CFrame.Angles(math.rad(-82.6),math.rad(-32.5),math.rad(24.2))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
	LEFTLEGLERP.C0 = LEFTLEGLERP.C0:lerp(CFrame.new(0.3,2,1.5)*CFrame.Angles(math.rad(19),math.rad(-40),math.rad(16.3))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
	RIGHTARMLERP.C0 = RIGHTARMLERP.C0:lerp(CFrame.new(-0.8,-0.7,0.3)*CFrame.Angles(math.rad(171.5),math.rad(79.5),math.rad(-109.6))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
	RIGHTLEGLERP.C0 = RIGHTLEGLERP.C0:lerp(CFrame.new(-0.6,1.6,1.5)*CFrame.Angles(math.rad(45.3),math.rad(12.7),math.rad(-11.1))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
	ROOTLERP.C0 = ROOTLERP.C0:lerp(CFrame.new(0,0,0)*CFrame.Angles(math.rad(-21.6),math.rad(-39.9),math.rad(-0.6))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
	swait()
end
coroutine.wrap(function()
	fireamb.Volume = 10
	repeat swait() fireamb.Volume = fireamb.Volume - .5 until fireamb.Volume <= 0
	fireamb:Destroy()
end)()
	debounce = false
	g1:Destroy()
	attacking = false
	ws = 100
	end
elseif Press=='g' then
	if secondform then
	if girl then return end
	if debounce then return end
	girl = true
	attacking = true
	debounce = true
	SOUND(st.shbox,3292075199,8,false,1.1,15)
	ws = 8
local g1 = Instance.new("BodyGyro", nil)
g1.CFrame = Root.CFrame
g1.Parent = Root
g1.D = 175
g1.P = 20000
g1.MaxTorque = Vector3.new(0,90000,0)
	for i = 1, 4 do
	for i = 1, 10 do
		g1.CFrame = g1.CFrame:lerp(CFrame.new(Root.Position,mouse.Hit.p),.09)
		blockyeffect(BrickColor.new("Really red"),Vector3.new(.5,.5,.5),.05,st.shbox.CFrame,"Neon",15)
		blocktrail(st.shbox.Position,Vector3.new(1.5,1.5,1.5),.05,"Neon",BrickColor.new("Really red"))
		HEADLERP.C0 = HEADLERP.C0:lerp(CFrame.new(-0.3,-1.5,-0.1)*CFrame.Angles(math.rad(-0.8),math.rad(-14.6+6*math.sin(sine/27)),math.rad(-6.9))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
		LEFTLEGLERP.C0 = LEFTLEGLERP.C0:lerp(CFrame.new(0.3,2.4,0.5)*CFrame.Angles(math.rad(-22.1+2*math.sin(sine/16)),math.rad(-27.1+2*math.sin(sine/16)),math.rad(0.5+1*math.sin(sine/16)))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
		RIGHTARMLERP.C0 = RIGHTARMLERP.C0:lerp(CFrame.new(-0.8,-0.7,0.3)*CFrame.Angles(math.rad(171.5-1*math.sin(sine/16)),math.rad(79.5),math.rad(-109.6))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
		RIGHTLEGLERP.C0 = RIGHTLEGLERP.C0:lerp(CFrame.new(-0.6,1.6,1.5)*CFrame.Angles(math.rad(34.4+1*math.sin(sine/16)),math.rad(12.7+1*math.sin(sine/16)),math.rad(-11.1+1*math.sin(sine/16)))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
		ROOTLERP.C0 = ROOTLERP.C0:lerp(CFrame.new(.15*math.sin(sine/32),0,.15*math.sin(sine/27))*CFrame.Angles(math.rad(-21.3 + 4 * math.sin(sine/24)),math.rad(-14.9+4*math.sin(sine/31)),math.rad(-0.5+4*math.sin(sine/27)))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
		LEFTARMLERP.C0 = LEFTARMLERP.C0:lerp(CFrame.new(1.7,1.1,0.5)*CFrame.Angles(math.rad(-76.8),math.rad(-25.7),math.rad(-3.4))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
	STAFFLERP.C0 = STAFFLERP.C0:lerp(CFrame.new(-0.1,-0.5,1.2)*CFrame.Angles(math.rad(102.8),math.rad(10.9),math.rad(2))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
	swait()
	end
	for i = 1, 10 do
		g1.CFrame = g1.CFrame:lerp(CFrame.new(Root.Position,mouse.Hit.p),.09)
		blockyeffect(BrickColor.new("Really red"),Vector3.new(.5,.5,.5),.05,st.shbox.CFrame,"Neon",15)
		blocktrail(st.shbox.Position,Vector3.new(1.5,1.5,1.5),.05,"Neon",BrickColor.new("Really red"))
		HEADLERP.C0 = HEADLERP.C0:lerp(CFrame.new(-0.3,-1.5,-0.1)*CFrame.Angles(math.rad(-0.8),math.rad(-14.6+6*math.sin(sine/27)),math.rad(-6.9))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
		LEFTLEGLERP.C0 = LEFTLEGLERP.C0:lerp(CFrame.new(0.3,2.4,0.5)*CFrame.Angles(math.rad(-22.1+2*math.sin(sine/16)),math.rad(-27.1+2*math.sin(sine/16)),math.rad(0.5+1*math.sin(sine/16)))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
		RIGHTARMLERP.C0 = RIGHTARMLERP.C0:lerp(CFrame.new(-0.8,-0.7,0.3)*CFrame.Angles(math.rad(171.5-1*math.sin(sine/16)),math.rad(79.5),math.rad(-109.6))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
		RIGHTLEGLERP.C0 = RIGHTLEGLERP.C0:lerp(CFrame.new(-0.6,1.6,1.5)*CFrame.Angles(math.rad(34.4+1*math.sin(sine/16)),math.rad(12.7+1*math.sin(sine/16)),math.rad(-11.1+1*math.sin(sine/16)))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
		ROOTLERP.C0 = ROOTLERP.C0:lerp(CFrame.new(.15*math.sin(sine/32),0,.15*math.sin(sine/27))*CFrame.Angles(math.rad(-21.3 + 4 * math.sin(sine/24)),math.rad(-14.9+4*math.sin(sine/31)),math.rad(-0.5+4*math.sin(sine/27)))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
STAFFLERP.C0 = STAFFLERP.C0:lerp(CFrame.new(-0.1,-0.5,1.2)*CFrame.Angles(math.rad(102.8),math.rad(10.9),math.rad(2))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
LEFTARMLERP.C0 = LEFTARMLERP.C0:lerp(CFrame.new(1,1.6,0.1)*CFrame.Angles(math.rad(-141.7),math.rad(-17.2),math.rad(-11.8))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
		swait()
	end
	swait()
	end
	local zx = girlemy:Clone() zx.Parent = Torso zx.ai.Disabled = false zx.core.Disabled = false zx.Torso.CFrame = CFrame.new(mouse.Hit.p)
debounce = false
attacking = false
ws = 90
g1:Destroy()
	else
		if debounce then return end
			ws = 12
			attacking = true
			debounce = true
local g1 = Instance.new("BodyGyro", nil)
g1.CFrame = Root.CFrame
g1.Parent = Root
g1.D = 175
g1.P = 20000
g1.MaxTorque = Vector3.new(500,90000,500)
	for i = 1, 30 do
					g1.CFrame = g1.CFrame:lerp(CFrame.new(Root.Position,mouse.Hit.p),.09)
		HEADLERP.C0 = HEADLERP.C0:lerp(CFrame.new(-0.2,-1.5,0)*CFrame.Angles(math.rad(-10.5),math.rad(-50.4),math.rad(-10.5))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125/2)
		LEFTARMLERP.C0 = LEFTARMLERP.C0:lerp(CFrame.new(1.9,0.3,0.1)*CFrame.Angles(math.rad(-119.6),math.rad(50.5),math.rad(37))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125/2)
		LEFTLEGLERP.C0 = LEFTLEGLERP.C0:lerp(CFrame.new(0.2,1.5,0.2)*CFrame.Angles(math.rad(-28.9),math.rad(-55.6),math.rad(9.9))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125/2)
		RIGHTARMLERP.C0 = RIGHTARMLERP.C0:lerp(CFrame.new(-1.8,1.5,0.5)*CFrame.Angles(math.rad(-136.4),math.rad(-7.4),math.rad(3.9))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125/2)
		RIGHTLEGLERP.C0 = RIGHTLEGLERP.C0:lerp(CFrame.new(-0.8,1.7,1.8)*CFrame.Angles(math.rad(13),math.rad(25),math.rad(11.5))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125/2)
		ROOTLERP.C0 = ROOTLERP.C0:lerp(CFrame.new(0,0,0)*CFrame.Angles(math.rad(-30.6),math.rad(-56.3),math.rad(-8.4))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125/2)
		swait()
	end
			SOUND(Torso,4571960003,10,false,math.random(9.5,10.5)/10,15)
				for i = 1, 6 do
		 blockyeffect(BrickColor.new("White"),Vector3.new(1,1,1),.05,leftlocation.CFrame,"Neon",math.random(7,12))
		end
	for i = 1, 12 do
		g1.CFrame = g1.CFrame:lerp(CFrame.new(Root.Position,mouse.Hit.p),.09)
		HEADLERP.C0 = HEADLERP.C0:lerp(CFrame.new(-0.2,-1.5,0)*CFrame.Angles(math.rad(-10.5),math.rad(-50.4),math.rad(-10.5))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.35)
		LEFTARMLERP.C0 = LEFTARMLERP.C0:lerp(CFrame.new(1.7,0.2,0)*CFrame.Angles(math.rad(-147.7),math.rad(58.8),math.rad(54.3))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.35)
		LEFTLEGLERP.C0 = LEFTLEGLERP.C0:lerp(CFrame.new(0.2,1.5,0.2)*CFrame.Angles(math.rad(-28.9),math.rad(-55.6),math.rad(9.9))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.35)
		RIGHTARMLERP.C0 = RIGHTARMLERP.C0:lerp(CFrame.new(-1.8,-0.2,0.2)*CFrame.Angles(math.rad(-123.4),math.rad(-44.8),math.rad(-24.4))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.35)
		RIGHTLEGLERP.C0 = RIGHTLEGLERP.C0:lerp(CFrame.new(-0.8,1.7,1.8)*CFrame.Angles(math.rad(13),math.rad(25),math.rad(11.5))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.35)
		ROOTLERP.C0 = ROOTLERP.C0:lerp(CFrame.new(0,0,0)*CFrame.Angles(math.rad(-30.6),math.rad(-59.3),math.rad(-8.4))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.15)
		swait()
	end
		if mouse.Target ~= nil then
		local sicko = skully2:Clone() sicko.Parent = workspace sicko.skully.mainp.CFrame = CFrame.new(mouse.Hit.p) * CFrame.new(0,5,0) sicko.Disabled = false
		end
			for i = 1, 20 do
		HEADLERP.C0 = HEADLERP.C0:lerp(CFrame.new(-0.2,-1.5,0)*CFrame.Angles(math.rad(-10.5),math.rad(-50.4),math.rad(-10.5))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
		LEFTARMLERP.C0 = LEFTARMLERP.C0:lerp(CFrame.new(1.5,0.6,0.1)*CFrame.Angles(math.rad(-119.5),math.rad(47.8),math.rad(33.3))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
		LEFTLEGLERP.C0 = LEFTLEGLERP.C0:lerp(CFrame.new(0.2,1.5,0.2)*CFrame.Angles(math.rad(-28.9),math.rad(-55.6),math.rad(9.9))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
		RIGHTARMLERP.C0 = RIGHTARMLERP.C0:lerp(CFrame.new(-1.9,1.2,0.3)*CFrame.Angles(math.rad(-126.1),math.rad(-10.6),math.rad(-0.7))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
		RIGHTLEGLERP.C0 = RIGHTLEGLERP.C0:lerp(CFrame.new(-0.8,1.7,1.8)*CFrame.Angles(math.rad(13),math.rad(25),math.rad(11.5))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
		ROOTLERP.C0 = ROOTLERP.C0:lerp(CFrame.new(0,0,0)*CFrame.Angles(math.rad(-31.1),math.rad(-60.2),math.rad(-8.8))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.15)
		swait()
			end
			g1:Destroy()
			debounce = false
			attacking = false
			ws = 100
		end
elseif Press=='f' then
	if debounce  then return end
	if secondform then return end
	
	      if toggle == false then
	  
	att.Parent = c["Torso"]
att.Position = Vector3.new(0, -40, -0)
att.Orientation = Vector3.new(-0, 0, -0)

                       toggle = true
 else
 
 	  	att.Parent = c["Left Arm"]
att.Position = Vector3.new(0, -1, -2.3)
att.Orientation = Vector3.new(-0, -90, -35)
 
     end
	
	ballshockwave(Torso.CFrame,.05,BrickColor.new("White"),"Neon",.05,Vector3.new(2,2,2))
	spikeball(Torso.CFrame,Vector3.new(1.5,1.5,1.5),BrickColor.White(),.05,"Neon")
	realhead.Parent = nil
	realhead2.Parent = Torso
	local hdweld2 = weldBetween(fkhead2,Head)
	shirt.ShirtTemplate = "rbxassetid://238537827"
	pants.PantsTemplate = "rbxassetid://486031443"
	st = staff:Clone() st.Parent = Torso 
    STAFFLERP.Part0 = st.t
    STAFFLERP.Part1 = LeftArm
secondform = true

	for _,v in pairs(game.Players.LocalPlayer.Character.Torso.secondhead:GetChildren()) do
	if v:IsA("BasePart") then
		v.Transparency = 1
	end
end
	
	for _,v in pairs(game.Players.LocalPlayer.Character.Torso.staff:GetChildren()) do
	if v:IsA("BasePart") then
		v.Transparency = 1
	end
end

doomtheme.SoundId = "rbxassetid://1382488262"
doomtheme.TimePosition = 20.7
doomtheme:Play()
dmt2 = {1382488262,4592815034,4593898734,4627771248}
coroutine.wrap(function()
if tauntdebounce then return end
tauntdebounce = true
local rdnm2 = introable[math.random(1,#introable)]
for i = 1, 2 do
local tauntsound = Instance.new("Sound", Head)
tauntsound.Volume = 10
tauntsound.SoundId = "rbxassetid://"..rdnm2
tauntsound.Looped = false
tauntsound.Pitch = 1
tauntsound:Play()
coroutine.wrap(function()
	wait(.5)
repeat swait() until tauntsound.IsPlaying == false
tauntsound:Destroy()
wait()
tauntdebounce = false
end)()
removeuseless:AddItem(tauntsound,15)
end
end)()

elseif Press=='z' then
	if debounce then return end
	debounce = true
	attacking = true
	ws = 120
	axe.Transparency = 0
	realhead.beard.Transparency = 0
	doomtheme.SoundId = "rbxassetid://187042245"
	doomtheme:Play()
	doomtheme.Volume = 10
	doomtheme.Pitch = .98
	doomtheme.TimePosition = 3
local light = Instance.new("PointLight", Torso)
light.Color = Color3.new(0,0,0)
light.Range = 0
light.Brightness = 0
light.Range = 35
light.Brightness = 20
light.Color = BrickColor.Random().Color
local b1 = Instance.new("BillboardGui",Head)
b1.Size = UDim2.new(0,100,0,40)
b1.StudsOffset = Vector3.new(0,3,0)
b1.Adornee = Head
local b2 = Instance.new("TextLabel",b1)
b2.BackgroundTransparency = 1
coroutine.wrap(function()
while wait(.15) do
	light.Color = BrickColor.Random().Color
b2.Text = "DIGGY DIGGY HOLE!!!"
b2.TextColor3 = BrickColor.Random().Color
end
end)()
b2.Font = "Arcade"
b2.TextSize = 30
b2.TextStrokeTransparency = 0
b2.TextColor3 = BrickColor.new("Lime green").Color
b2.TextStrokeColor3 = Color3.new(0,0,0)
b2.Size = UDim2.new(1,0,0.5,0)
	while wait() do
		for i = 1, 9 do
			HEADLERP.C0 = HEADLERP.C0:lerp(CFrame.new(-0.2,-2,0)*CFrame.Angles(math.rad(-8.9),math.rad(-41),math.rad(-8.2))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.4)
			LEFTARMLERP.C0 = LEFTARMLERP.C0:lerp(CFrame.new(1.6,1.6,-0.2)*CFrame.Angles(math.rad(-49),math.rad(-15.7),math.rad(35.8))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.4)
			LEFTLEGLERP.C0 = LEFTLEGLERP.C0:lerp(CFrame.new(0.5,2.6,0.1)*CFrame.Angles(math.rad(-38.5),math.rad(-40.6),math.rad(-1.6))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.4)
			RIGHTARMLERP.C0 = RIGHTARMLERP.C0:lerp(CFrame.new(-1.9,1.4,-1.2)*CFrame.Angles(math.rad(-129.1),math.rad(30.5),math.rad(-34.4))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.4)
			RIGHTLEGLERP.C0 = RIGHTLEGLERP.C0:lerp(CFrame.new(-0.3,1.5,1.8)*CFrame.Angles(math.rad(23.5),math.rad(15.5),math.rad(-18.3))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.4)
			ROOTLERP.C0 = ROOTLERP.C0:lerp(CFrame.new(0,0,0)*CFrame.Angles(math.rad(-27.6),math.rad(-40.7),math.rad(-28.6))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.4)
			AXELERP.C0 = AXELERP.C0:lerp(CFrame.new(2.1,-0.2,-0.2)*CFrame.Angles(math.rad(-78.1),math.rad(0.9),math.rad(-125.7))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.4)
			swait()
		end
				for i = 1, 9 do
					AXELERP.C0 = AXELERP.C0:lerp(CFrame.new(2.5,0.5,-1.3)*CFrame.Angles(math.rad(-118.9),math.rad(-23.3),math.rad(-86))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.4)
					HEADLERP.C0 = HEADLERP.C0:lerp(CFrame.new(-0.2,-2,0)*CFrame.Angles(math.rad(-7.6),math.rad(-27.9),math.rad(-5.9))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.4)
					LEFTARMLERP.C0 = LEFTARMLERP.C0:lerp(CFrame.new(2,1.1,0.5)*CFrame.Angles(math.rad(26.5),math.rad(-15.7),math.rad(35.8))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.4)
					LEFTLEGLERP.C0 = LEFTLEGLERP.C0:lerp(CFrame.new(0.5,1.7,2)*CFrame.Angles(math.rad(8.2),math.rad(-40.6),math.rad(-1.6))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.4)
					RIGHTARMLERP.C0 = RIGHTARMLERP.C0:lerp(CFrame.new(-2,0.4,-0.4)*CFrame.Angles(math.rad(-149),math.rad(-23.9),math.rad(-50.2))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.4)
					RIGHTLEGLERP.C0 = RIGHTLEGLERP.C0:lerp(CFrame.new(-0.3,1.5,1.8)*CFrame.Angles(math.rad(23.5),math.rad(15.5),math.rad(-18.3))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.4)
					ROOTLERP.C0 = ROOTLERP.C0:lerp(CFrame.new(0,0,0)*CFrame.Angles(math.rad(-27.6),math.rad(-40.7),math.rad(16.6))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.4)
			swait()
		end
	end
elseif Press=='e' then
	if debounce then return end
	debounce = true
	attacking = true
	if secondform then
		ws = 8
		attacktaunt()
local g1 = Instance.new("BodyGyro", nil)
g1.CFrame = Root.CFrame
g1.Parent = Root
g1.D = 175
g1.P = 20000
g1.MaxTorque = Vector3.new(0,90000,0)
		for i = 1, 20 do
			g1.CFrame = g1.CFrame:lerp(CFrame.new(Root.Position,mouse.Hit.p),.2)
			HEADLERP.C0 = HEADLERP.C0:lerp(CFrame.new(-0.1,-1.5,-0.1)*CFrame.Angles(math.rad(2.9),math.rad(30.1),math.rad(-1.9))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
			LEFTARMLERP.C0 = LEFTARMLERP.C0:lerp(CFrame.new(-0.9,2.3,0.5)*CFrame.Angles(math.rad(107),math.rad(-57.9),math.rad(-165.1))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
			LEFTLEGLERP.C0 = LEFTLEGLERP.C0:lerp(CFrame.new(0.3,1.6,1.7)*CFrame.Angles(math.rad(14.2),math.rad(-27.1),math.rad(0.5))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
			RIGHTARMLERP.C0 = RIGHTARMLERP.C0:lerp(CFrame.new(-0.8,-0.7,0.3)*CFrame.Angles(math.rad(171.5),math.rad(79.5),math.rad(-109.6))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
			RIGHTLEGLERP.C0 = RIGHTLEGLERP.C0:lerp(CFrame.new(-0.4,1.7,1.7)*CFrame.Angles(math.rad(31.1),math.rad(28.5),math.rad(-18.8))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
			STAFFLERP.C0 = STAFFLERP.C0:lerp(CFrame.new(-0.6,0,1.1)*CFrame.Angles(math.rad(96),math.rad(-12.6),math.rad(35.2))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
			ROOTLERP.C0 = ROOTLERP.C0:lerp(CFrame.new(0,0,0)*CFrame.Angles(math.rad(-17),math.rad(31.2),math.rad(-14.2))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
			swait()
		end
		local a = Instance.new("Part",Torso)
		a.Size = Vector3.new(1,1,1)
		a.Anchored = true
		a.CanCollide = false
		a.Transparency = 1
		a.CFrame = Root.CFrame * CFrame.new(0,0,-5)
		for i = 1, 2 do
		local am = Instance.new("Sound",a)
		am.SoundId = "rbxassetid://4086041756"
		am.Volume = 10
		am.Pitch = .95
		am.TimePosition = .25
		am:Play()
		removeuseless:AddItem(am,15)
		end
		coroutine.wrap(function()
			local xx = 20
			for i = 1, 200 do
				a.CFrame = a.CFrame * CFrame.new(0,0,-xx)
local didhit = false
local mate = nil
local colo = nil
local ray = Ray.new(a.Position,Vector3.new(0,-25,0))
local tabd = {bloodfolder,Character}
local part, hitPosition = workspace:FindPartOnRayWithIgnoreList(ray, {bloodfolder,Root,Character,blooddecal,blowd,Torso},false,true)
if part then
	didhit = true
mate = part.Material
colo = part.BrickColor
else
	didhit = false
end
if didhit then
	local randomc = math.random(1,#cardtable)
	local pick = cardtable[randomc] local card = pick:Clone() card.Parent = Torso card.Size = Vector3.new(.1,.25,.1)
	card.CFrame = CFrame.new(hitPosition) * CFrame.new(math.random(-5,5),0,math.random(-5,5))
	coroutine.wrap(function()
		local az = math.random(-180,180)
		for i = 1, 40 do
			card.CFrame = card.CFrame:lerp(card.CFrame*CFrame.Angles(0,math.rad(az),0),.09)
			card.Size = card.Size + Vector3.new(.175,0,.32)
			swait()
		end
		local explo = Instance.new("Part",Torso)
		explo.BrickColor = BrickColor.new("Really black")
		explo.Material = "Neon"
		explo.Anchored = true
		explo.CanCollide = false
		explo.CFrame = card.CFrame * CFrame.Angles(math.rad(90),math.rad(90),0)
		explo.Size = Vector3.new(3,3,3)
		local explom = Instance.new("SpecialMesh",explo)
		explom.MeshType = "Sphere"
		SOUND(explo,3855293277,4,false,math.random(9,11)/10,15)
		local hit = damagealll(15,card.Position)
		for _,v in pairs(hit) do
        if v:FindFirstChildOfClass("Humanoid") and v:FindFirstChildOfClass("Humanoid").Health > 0 then
	--death(v:FindFirstChildOfClass("Humanoid").Parent)
    end
end
		local explo2 = explo:Clone() explo2.Parent = Torso explo2.BrickColor = BrickColor.new("White") explo2.Transparency = .5
			spikeball(CFrame.new(explo.Position),Vector3.new(2,2,2),BrickColor.new("White"),.1,"Neon")
			shockwave(CFrame.new(explo.Position),Vector3.new(2,.75,2),.05,BrickColor.new("Really black"),math.random(16,21),.1,"Neon")
			shockwave(CFrame.new(explo.Position),Vector3.new(3,.25,3),.05,BrickColor.new("White"),math.random(2,5),.05,"Neon")
			for i = 1, 20 do
				explo.Size = explo.Size + Vector3.new(5,1,1)
				explo.Transparency = explo.Transparency + .05
				explo2.Size = explo.Size + Vector3.new(5,1,1)*1.1
				explo2.Transparency = explo.Transparency + .025
				swait()
			end
			explo.Transparency = 1
			removeuseless:AddItem(explo,3)
			explo2:Destroy()
		local az2 = math.random(-180,180)
		for i = 1, 40 do
			card.CFrame = card.CFrame:lerp(card.CFrame*CFrame.Angles(0,math.rad(az2),0),.09)
			card.Size = card.Size - Vector3.new(.175,0,.32)
			swait()
		end
		card:Destroy()
		end)()
end
				swait()
			end
			a:Destroy()
		end)()
		for i = 1, 26 do
			blocktrail(st.shbox.Position,Vector3.new(1.5,1.5,1.5),.05,"Neon",BrickColor.new("Really red"))
			HEADLERP.C0 = HEADLERP.C0:lerp(CFrame.new(0.1,-1.5,0.2)*CFrame.Angles(math.rad(-6.8),math.rad(-42.2),math.rad(2.4))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
			LEFTARMLERP.C0 = LEFTARMLERP.C0:lerp(CFrame.new(1.9,0.9,0.5)*CFrame.Angles(math.rad(-100.2),math.rad(28.8),math.rad(5.3))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
			LEFTLEGLERP.C0 = LEFTLEGLERP.C0:lerp(CFrame.new(0.1,2.8,0.4)*CFrame.Angles(math.rad(-32.7),math.rad(-50.3),math.rad(9.6))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
			RIGHTARMLERP.C0 = RIGHTARMLERP.C0:lerp(CFrame.new(-0.8,-0.7,0.3)*CFrame.Angles(math.rad(171.5),math.rad(79.5),math.rad(-109.6))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
			RIGHTLEGLERP.C0 = RIGHTLEGLERP.C0:lerp(CFrame.new(-0.1,0.5,2)*CFrame.Angles(math.rad(64.5),math.rad(28.5),math.rad(-18.8))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
			STAFFLERP.C0 = STAFFLERP.C0:lerp(CFrame.new(-0.1,-0.6,1.2)*CFrame.Angles(math.rad(113.2),math.rad(13.1),math.rad(-0.3))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
			ROOTLERP.C0 = ROOTLERP.C0:lerp(CFrame.new(0,0,0)*CFrame.Angles(math.rad(-36.8),math.rad(-44.8),math.rad(4.3))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
			swait()
		end
		g1:Destroy()
		debounce = false
		attacking = false
		ws = 90
		else---post attack for corruptAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	ws = 8
	local g1 = Instance.new("BodyGyro", nil)
g1.CFrame = Root.CFrame
g1.Parent = Root
g1.D = 175
g1.P = 20000
g1.MaxTorque = Vector3.new(3000,90000,3000)
SOUND(Torso,1888686669,10,false,math.random(9,11)/10,15)
coroutine.wrap(function()
for i = 1, 20 do
	HEADLERP.C0 = HEADLERP.C0:lerp(CFrame.new(0.1,-1.5,0.5)*CFrame.Angles(math.rad(-15.7),math.rad(-46.7),math.rad(2.5))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
	LEFTARMLERP.C0 = LEFTARMLERP.C0:lerp(CFrame.new(1,2,-0.5)*CFrame.Angles(math.rad(-105.8),math.rad(-50.1),math.rad(24.7))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
	LEFTLEGLERP.C0 = LEFTLEGLERP.C0:lerp(CFrame.new(0.2,1.7,0.2)*CFrame.Angles(math.rad(-28.9),math.rad(-55.6),math.rad(9.9))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
	RIGHTARMLERP.C0 = RIGHTARMLERP.C0:lerp(CFrame.new(-1,1,1.3)*CFrame.Angles(math.rad(4),math.rad(46),math.rad(-35.1))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
	RIGHTLEGLERP.C0 = RIGHTLEGLERP.C0:lerp(CFrame.new(-0.8,1.7,1.5)*CFrame.Angles(math.rad(13),math.rad(25),math.rad(11.5))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
	ROOTLERP.C0 = ROOTLERP.C0:lerp(CFrame.new(0,0,0)*CFrame.Angles(math.rad(-30.6),math.rad(-56.3),math.rad(2.9))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
	swait()
end
end)()
	local randomc = math.random(1,#cardtable)
	local pick = cardtable[randomc]
	local bigcard = pick:Clone() bigcard.Parent = Torso bigcard.Size = Vector3.new(.1,.25,.1) bigcard.Transparency = 0
	bigcard.Anchored = false
	bigcard.CanCollide = false
	bigcard.Massless = true
	bigcard.Material = "Neon"
    local bigcardweld = weldBetween(bigcard,Root) bigcardweld.C0 =  CFrame.Angles(math.rad(90),0,math.rad(0))* CFrame.new(0,0,5) 
local titt = 0
spikeball(bigcard.CFrame,Vector3.new(.5,.5,.5),BrickColor.new("White"),.035,"Neon")
spikeball(bigcard.CFrame,Vector3.new(1,1,1),BrickColor.new("White"),.05,"Neon")
ballshockwave(bigcard.CFrame,.05,BrickColor.new("White"),"Neon",.05,Vector3.new(1.5,1.5,1.5))
	for i = 1, 40 do
		titt = titt + 2
		g1.CFrame = g1.CFrame:lerp(CFrame.new(Root.Position,mouse.Hit.p),.09)
		bigcard.Size = bigcard.Size + Vector3.new(.175,0,.3)
		bigcardweld.C0 = bigcardweld.C0:lerp(bigcardweld.C0 * CFrame.Angles(math.rad(0),math.rad(0),math.rad(titt)),.09)
		swait()
	end
    local blackhole = Instance.new("Sound",bigcard)
blackhole.SoundId = "rbxassetid://1835334344"
blackhole.Volume = 8
blackhole.Pitch = 1
blackhole:Play()
	local portal = Instance.new("Part",Torso)
	portal.Anchored = false
	portal.CanCollide = false
	portal.Size = Vector3.new(.35,4.5,4.5)
	portal.Material = "Neon"
	portal.BrickColor = BrickColor.new("White")
	portal.Shape = "Cylinder"
	portal.Transparency = 1
	local portalweld = weldBetween(portal,bigcard) portalweld.C0 = portalweld.C0 * CFrame.Angles(math.rad(0),math.rad(0),math.rad(90))
	for i = 1, 10 do
		g1.CFrame = g1.CFrame:lerp(CFrame.new(Root.Position,mouse.Hit.p),.09)
		portal.Transparency = portal.Transparency - .05
		bigcard.Size = bigcard.Size + Vector3.new(.175/2,0,.3/2)
		bigcardweld.C0 = bigcardweld.C0:lerp(bigcardweld.C0 * CFrame.Angles(math.rad(0),math.rad(0),math.rad(titt)),.09)
		swait()
	end
		for i = 1, 10 do
			g1.CFrame = g1.CFrame:lerp(CFrame.new(Root.Position,mouse.Hit.p),.09)
		portal.Transparency = portal.Transparency - .05
		bigcard.Size = bigcard.Size - Vector3.new(.175/2,0,.3/2)
		bigcardweld.C0 = bigcardweld.C0:lerp(bigcardweld.C0 * CFrame.Angles(math.rad(0),math.rad(0),math.rad(titt)),.09)
		swait()
	end
	titt = titt + 4
	local hitbox = Instance.new("Part",Torso)
	hitbox.Size = Vector3.new(1,1,1)
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.CFrame = Root.CFrame * CFrame.new(0,0,-10)
	hitbox.Transparency = 1
	for i = 1, 500 do
		local zv = math.random(1,2)
		if zv == 1 then
			local blc = Instance.new("Part",Torso)
			blc.Anchored = true
			blc.CanCollide = false
			blc.CFrame = hitbox.CFrame * CFrame.new(0,0,-10) * CFrame.new(math.random(-20,20),math.random(-20,20),math.random(-20,20)) * CFrame.Angles(math.rad(math.random(-180,180)),math.rad(math.random(-180,180)),math.rad(math.random(-180,180)))
			blc.Material = "Neon"
			blc.Transparency = 0
			blc.BrickColor = BrickColor.new("White")
			blc.Size = Vector3.new(2,2,2)
			coroutine.wrap(function()
				for i = 1, 20 do
					blc.Size = blc.Size - Vector3.new(.1,.1,.1)
					blc.CFrame = blc.CFrame:lerp(CFrame.new(portal.Position),.2)
					blc.Transparency = blc.Transparency + .05
					swait()
				end
				blc:Destroy()
			end)()
		end
		local hit = damagealll(0,hitbox.Position)
		for _,v in pairs(hit) do
if v:FindFirstChildOfClass("Humanoid") and v:FindFirstChildOfClass("Humanoid").Health > 0 then
local slachtoffer = v:FindFirstChildOfClass("Humanoid")
local enemychar = slachtoffer.Parent
pcall(function()
	local creep = Instance.new("Part",Torso)
	creep.Anchored = true
	creep.CanCollide = false
	creep.Transparency = 1
	creep.CFrame = enemychar.Torso.CFrame
	creep.Size = Vector3.new(1,1,1)
	removeuseless:AddItem(creep,10)
	SOUND(creep,314678645,10,false,math.random(9.5,10.5)/10,15)
for i,v in pairs(enemychar:GetDescendants()) do
			if v:IsA("Part") then
				v.BrickColor = BrickColor.new("White")
				v.Material = "Neon"
				v.Anchored = true
				v.Parent = Torso
				v.CanCollide = false
				v:BreakJoints()
				coroutine.wrap(function()
					local a1 = math.rad(math.random(-180,180))
					local a2 = math.rad(math.random(-180,180))
					local a3 = math.rad(math.random(-180,180))
				for i = 1, 80 do
					v.CFrame = v.CFrame:lerp(CFrame.new(portal.Position)*CFrame.Angles(a1,a2,a3),.05)
					v.Transparency = v.Transparency + .0125
					swait()
				end
				v:Destroy()
				end)()
			elseif v:IsA("MeshPart") then
				v.BrickColor = BrickColor.new("White")
				v.Material = "Neon"
				v.Anchored = true
				v.Parent = Torso
				v.CanCollide = false
				enemychar:Destroy()
			end
end
end)
end
		end
		g1.CFrame = g1.CFrame:lerp(CFrame.new(Root.Position,mouse.Hit.p),.09)
		hitbox.CFrame = Root.CFrame * CFrame.new(0,0,-25)
		bigcardweld.C0 = bigcardweld.C0:lerp(bigcardweld.C0 * CFrame.Angles(math.rad(0),math.rad(0),math.rad(titt)),.25)
		swait()
	end
	bigcardweld:Destroy()
	bigcard.Anchored = true
	coroutine.wrap(function()
		SOUND(portal,4086044079,10,false,math.random(9.5,10.5)/10,15)
		for i = 1, 20 do
			portal.Transparency = portal.Transparency + .05
			portal.Size = portal.Size - portal.size/20
			bigcard.Size = bigcard.Size - bigcard.Size/10
			bigcard.Transparency = bigcard.Transparency + .05
			swait()
		end
		removeuseless:AddItem(portal,10)
		bigcard:Destroy()
	end)()
	g1:Destroy()
	ws = 100
	debounce = false
	attacking = false
	end
end
end)

checks1 = coroutine.wrap(function() -------Checks
while true do
if Root.Velocity.Magnitude < 8 and not attacking then
position = "Idle"
elseif Root.Velocity.Magnitude > 8 and not attacking then
position = "Walking"
else
end
wait()
end
end)
checks1()

immortal = {}
for i,v in pairs(Character:GetDescendants()) do
	if v:IsA("BasePart") and v.Name ~= "lmagic" and v.Name ~= "rmagic" then
		if v ~= Root and v ~= Torso and v ~= Head and v ~= RightArm and v ~= LeftArm and v ~= RightLeg and v.Name ~= "lmagic" and v.Name ~= "rmagic" and v ~= LeftLeg then
			v.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
		end
		table.insert(immortal,{v,v.Parent,v.Material,v.Color,v.Transparency})
	elseif v:IsA("JointInstance") then
		table.insert(immortal,{v,v.Parent,nil,nil,nil})
	end
end
for e = 1, #immortal do
if immortal[e] ~= nil then
local STUFF = immortal[e]
local PART = STUFF[1]
local PARENT = STUFF[2]
local MATERIAL = STUFF[3]
local COLOR = STUFF[4]
local TRANSPARENCY = STUFF[5]
if levitate then
if PART.ClassName == "Part" and PART ~= Root and PART.Name ~= eyo1 and PART.Name ~= eyo2 and PART.Name ~= "lmagic" and PART.Name ~= "rmagic" then
PART.Material = MATERIAL
PART.Color = COLOR
PART.Transparency = TRANSPARENCY
end
PART.AncestryChanged:connect(function()
PART.Parent = PARENT
end)
else
if PART.ClassName == "Part" and PART ~= Root and PART.Name ~= "lmagic" and PART.Name ~= "rmagic" then
PART.Material = MATERIAL
PART.Color = COLOR
PART.Transparency = TRANSPARENCY
end
PART.AncestryChanged:connect(function()
PART.Parent = PARENT
end)
end
end
end
function immortality()
for e = 1, #immortal do
if immortal[e] ~= nil then
local STUFF = immortal[e]
local PART = STUFF[1]
local PARENT = STUFF[2]
local MATERIAL = STUFF[3]
local COLOR = STUFF[4]
local TRANSPARENCY = STUFF[5]
if PART.ClassName == "Part" and PART == Root then
PART.Material = MATERIAL
PART.Color = COLOR
PART.Transparency = TRANSPARENCY
end
if PART.Parent ~= PARENT then
hum:Remove()
PART.Parent = PARENT
hum = Instance.new("Humanoid",Character)
hum.Name = "noneofurbusiness"
end
end
end
end
if Character:FindFirstChild"CharacterMesh" then
	Character:FindFirstChild"CharacterMesh":Destroy()
end
if Character:FindFirstChild"Body Colors" then
Character:FindFirstChild"Body Colors".HeadColor = BrickColor.new("Really black")
Character:FindFirstChild"Body Colors".TorsoColor = BrickColor.new("Really black")
Character:FindFirstChild"Body Colors".LeftArmColor = BrickColor.new("Really black")
Character:FindFirstChild"Body Colors".RightArmColor = BrickColor.new("Really black")
Character:FindFirstChild"Body Colors".LeftLegColor = BrickColor.new("Really black")
Character:FindFirstChild"Body Colors".RightLegColor = BrickColor.new("Really black")
end
coroutine.wrap(function()
	while wait(.25) do
				local t = wosh:Clone() t.Parent = Torso
	t.CFrame = Root.CFrame * CFrame.new(0,math.random(-5,5),0) * CFrame.Angles(0,math.rad(math.random(-180,180)),0)
	t.Anchored = false
	t.Massless = true
	t.CanCollide = false
	t.Transparency = 1
local tweld = weldBetween(t,Torso)
	coroutine.wrap(function()
		local mthrandom = math.random(-5,5)
		local xci = math.random(-1,1)/40
		local xci2 = math.random(.8,1)
				for i = 1, 100 do
			t.Size = t.Size + Vector3.new(.8,.05,.8)/10
			t.Transparency = t.Transparency - .00125/2
			tweld.C0 = tweld.C0 * CFrame.new(0,xci,0) * CFrame.Angles(0,math.rad(0+mthrandom),0)
			swait()
		end
		for i = 1, 100 do
			t.Size = t.Size + Vector3.new(.8,.05,.8)/10
			t.Transparency = t.Transparency + .00125/2
			tweld.C0 = tweld.C0 * CFrame.new(0,xci,0) * CFrame.Angles(0,math.rad(0+mthrandom),0)
			swait()
		end
		t:Destroy()
	end)()
	end
end)()
coroutine.wrap(function()
while game:GetService("RunService").Stepped:wait() do
hpheight = 4 + 1 * math.sin(sine/16)
hum.HipHeight = hpheight
Head.Transparency = 1
Head.BrickColor = BrickColor.new("Really black")
Torso.BrickColor = Head.BrickColor
LeftArm.BrickColor = Head.BrickColor
RightArm.BrickColor = Head.BrickColor
LeftLeg.BrickColor = Head.BrickColor
RightLeg.BrickColor = Head.BrickColor
hum:SetStateEnabled("Dead",false) hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
if Torso:FindFirstChild("Neck") == nil then
immortality()
end
swait()
end
end)()

local anims = coroutine.wrap(function()
while true do
settime = 0.05
sine = sine + change
sine2 = sine2 + change2
if position == "Walking" and attacking == false then
change = 1
walking = true
if ws < 100 then
	ws = ws + 1
end
if secondform then
	local plant2 = hum.MoveDirection*Torso.CFrame.LookVector
local plant3 = hum.MoveDirection*Torso.CFrame.RightVector
local plant = plant2.Z + plant2.X
local plant4 = plant3.Z + plant3.X
	    STAFFLERP.C0 = STAFFLERP.C0:lerp(CFrame.new(0.5,-0.2,1)*CFrame.Angles(math.rad(92.6),math.rad(10.8),math.rad(-21.9))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
		HEADLERP.C0 = HEADLERP.C0:lerp(CFrame.new(-0.3,-1.5,0.25)*CFrame.Angles(math.rad(-14.8),math.rad(-14.6+5*math.sin(sine/16)),math.rad(-6.9))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
		LEFTARMLERP.C0 = LEFTARMLERP.C0:lerp(CFrame.new(1,1.5,0.7)*CFrame.Angles(math.rad(-86.9 + 4 * math.sin(sine/16)),math.rad(-25.1+1*math.sin(sine/16)),math.rad(-5.3+1*math.sin(sine/16)))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
		LEFTLEGLERP.C0 = LEFTLEGLERP.C0:lerp(CFrame.new(0.3,1.6,1.5)*CFrame.Angles(math.rad(17.1+3*math.sin(sine/16)),math.rad(-27.1+1*math.sin(sine/16)),math.rad(0.5))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
		RIGHTARMLERP.C0 = RIGHTARMLERP.C0:lerp(CFrame.new(-0.8,-0.7,0.3)*CFrame.Angles(math.rad(171.5-1*math.sin(sine/16)),math.rad(79.5),math.rad(-109.6))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
		RIGHTLEGLERP.C0 = RIGHTLEGLERP.C0:lerp(CFrame.new(-0.6,1.2,1.5)*CFrame.Angles(math.rad(49.9+2*math.sin(sine/16)),math.rad(12.7+1*math.sin(sine/16)),math.rad(-11.1))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
		ROOTLERP.C0 = ROOTLERP.C0:lerp(CFrame.new(.15*math.sin(sine/32),0,.15*math.sin(sine/27))*CFrame.Angles(math.rad(4 * math.sin(sine/24)+ Root.RotVelocity.Y / 20),math.rad(-14.9+4*math.sin(sine/31)),math.rad(4*math.sin(sine/27)+ Root.RotVelocity.Y / 20))*CFrame.Angles(math.rad(-plant - plant/5)*32.1,math.rad(-plant4 - plant4/5),math.rad(-plant4 - plant4/5)*15),.125)
	else
local plant2 = hum.MoveDirection*Torso.CFrame.LookVector
local plant3 = hum.MoveDirection*Torso.CFrame.RightVector
local plant = plant2.Z + plant2.X
local plant4 = plant3.Z + plant3.X
HEADLERP.C0 = HEADLERP.C0:lerp(CFrame.new(0,-1.5,0.2)*CFrame.Angles(math.rad(-5.6-1*math.sin(sine/16)),math.rad(-48.9),math.rad(1.6))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
LEFTARMLERP.C0 = LEFTARMLERP.C0:lerp(CFrame.new(1.1,-0,0.4)*CFrame.Angles(math.rad(-42.9 + 3*math.sin(sine/16)),math.rad(68.2 - 1 * math.sin(sine/16)),math.rad(-35.3))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
LEFTLEGLERP.C0 = LEFTLEGLERP.C0:lerp(CFrame.new(0.2,1,1.5)*CFrame.Angles(math.rad(48.2 + 2 * math.sin(sine/16)),math.rad(-55.6 + 3 * math.sin(sine/16)),math.rad(9.9))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
RIGHTARMLERP.C0 = RIGHTARMLERP.C0:lerp(CFrame.new(-1.3,1,1)*CFrame.Angles(math.rad(4),math.rad(46-3*math.sin(sine/16)),math.rad(-35.1-2*math.sin(sine/16)))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
RIGHTLEGLERP.C0 = RIGHTLEGLERP.C0:lerp(CFrame.new(0.3,2,1)*CFrame.Angles(math.rad(27.9+1.5*math.sin(sine/16)),math.rad(1.2),math.rad(-47.5+1*math.sin(sine/16)))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
ROOTLERP.C0 = ROOTLERP.C0:lerp(CFrame.new(0,0,0)*CFrame.Angles(math.rad(-30),math.rad(-47.1),math.rad(10.6))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
ROOTLERP.C0 = ROOTLERP.C0:lerp(CFrame.new(.25 * math.sin(sine/19),0,.25*math.sin(sine/22))*CFrame.Angles(math.rad(0+ 2 * math.sin(sine/16)+ Root.RotVelocity.Y / 20),math.rad(-50),math.rad(3)+ Root.RotVelocity.Y / 20)*CFrame.Angles(math.rad(plant - -plant/5)*-27.5,0,math.rad(plant4 - -plant4/5)*-29.4),.25)
end
elseif position == "Idle" and attacking == false then
change = 1
if ws > 11 then
	ws = ws - 1
end
if secondform then
		STAFFLERP.C0 = STAFFLERP.C0:lerp(CFrame.new(0.5,-0.2,1)*CFrame.Angles(math.rad(92.6),math.rad(10.8),math.rad(-21.9))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
		HEADLERP.C0 = HEADLERP.C0:lerp(CFrame.new(-0.3,-1.5,-0.1)*CFrame.Angles(math.rad(-0.8),math.rad(-14.6+6*math.sin(sine/27)),math.rad(-6.9))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
		LEFTARMLERP.C0 = LEFTARMLERP.C0:lerp(CFrame.new(1,1.5,0.7)*CFrame.Angles(math.rad(-86.9 + 4 * math.sin(sine/16)),math.rad(-25.1+1*math.sin(sine/16)),math.rad(-5.3+1*math.sin(sine/16)))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
		LEFTLEGLERP.C0 = LEFTLEGLERP.C0:lerp(CFrame.new(0.3,2.4,0.5)*CFrame.Angles(math.rad(-22.1+2*math.sin(sine/16)),math.rad(-27.1+2*math.sin(sine/16)),math.rad(0.5+1*math.sin(sine/16)))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
		RIGHTARMLERP.C0 = RIGHTARMLERP.C0:lerp(CFrame.new(-0.8,-0.7,0.3)*CFrame.Angles(math.rad(171.5-1*math.sin(sine/16)),math.rad(79.5),math.rad(-109.6))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
		RIGHTLEGLERP.C0 = RIGHTLEGLERP.C0:lerp(CFrame.new(-0.6,1.6,1.5)*CFrame.Angles(math.rad(34.4+1*math.sin(sine/16)),math.rad(12.7+1*math.sin(sine/16)),math.rad(-11.1+1*math.sin(sine/16)))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
		ROOTLERP.C0 = ROOTLERP.C0:lerp(CFrame.new(.15*math.sin(sine/32),0,.15*math.sin(sine/27))*CFrame.Angles(math.rad(-21.3 + 4 * math.sin(sine/24)),math.rad(-14.9+4*math.sin(sine/31)),math.rad(-0.5+4*math.sin(sine/27)))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.125)
	else
HEADLERP.C0 = HEADLERP.C0:lerp(CFrame.new(0,-1.5,-0.1)*CFrame.Angles(math.rad(3-1*math.sin(sine/16)),math.rad(-40.2),math.rad(0))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
LEFTARMLERP.C0 = LEFTARMLERP.C0:lerp(CFrame.new(1.5,1+.1,.2)*CFrame.Angles(math.rad(12.7+3*math.sin(sine/16)),math.rad(-3.5+2*math.sin(sine/16)),math.rad(49.2+3*math.sin(sine/16)))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
LEFTLEGLERP.C0 = LEFTLEGLERP.C0:lerp(CFrame.new(0.3 + .1 * math.sin(sine/16),2,0.3 - .1 * math.sin(sine/16))*CFrame.Angles(math.rad(-22.1 - 4 * math.sin(sine/16)),math.rad(-55.6 + 1.5 * math.sin(sine/16)),math.rad(13 - 2.5 * math.sin(sine/16)))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
RIGHTARMLERP.C0 = RIGHTARMLERP.C0:lerp(CFrame.new(-1.5,1.2+.15*math.sin(sine/16),0.3)*CFrame.Angles(math.rad(-16.1-2*math.sin(sine/16)),math.rad(20.9),math.rad(-44.3-3*math.sin(sine/16)))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
RIGHTLEGLERP.C0 = RIGHTLEGLERP.C0:lerp(CFrame.new(-0.6,1.1,1.5)*CFrame.Angles(math.rad(22.6 + 3 * math.sin(sine/16)),math.rad(22.1-2*math.sin(sine/16)),math.rad(0))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
ROOTLERP.C0 = ROOTLERP.C0:lerp(CFrame.new(.25*math.sin(sine/26),0,.25*math.sin(sine/31))*CFrame.Angles(math.rad(-14.9 + 6 * math.sin(sine/25)),math.rad(-43.1+6*math.sin(sine/32)),math.rad(4.4))*CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)),.25)
end
end
swait()
end
end)
anims()
warn("Surprising resurrection. Made by Supr14")
if game:GetService("ServerStorage").intro.Value == false then
	dox = true
end
