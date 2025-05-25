--[[
	Slightly modified version of DerpMonster83's keybind library.
	
	Link:
	https://create.roblox.com/store/asset/113699456236768/Keybind-Module
	
	Uses the new Input Action System (IAS):
	https://devforum.roblox.com/t/studio-beta-new-input-action-system/3656214
]]--

--!nonstrict
export type Action = typeof(script:FindFirstChild("ActionTemplate"))
type KeybindImpl = {
	CurrentContext: string,
	EnableContext: (KeybindImpl, context: string) -> (),
	GetAction: (KeybindImpl, context: string, name: string) -> Action	
}

type KeybindContext = {
	context: InputContext,
	keybinds: { [string]: Action }
}

-- module table:
local Keybind = {
	CurrentContext = ""
} :: KeybindImpl

-- constant variables
local ACTION_TEMPLATE = script:FindFirstChild("ActionTemplate")
local ALWAYS_ON_STATE = "default" -- this state will always be on

-- Private variables
local keybinds: { [string]: KeybindContext } = {}

-- Private functions
local function getContext(name: string): KeybindContext
	local trueName = name:lower()
	
	if keybinds[trueName] == nil then
		local context = Instance.new("InputContext")
		context.Enabled = trueName == ALWAYS_ON_STATE
		context.Name = trueName
		context.Parent = script
		
		keybinds[trueName] = {
			context = context,
			keybinds = {}
		}
	end
	return keybinds[trueName]
end

local function getEmptyAction(): Action
	return ACTION_TEMPLATE:Clone()
end

-- Global methods


function Keybind:GetAction(Context, name): Action
	local context = getContext(Context)
	
	local action = context.keybinds[name]
	if action == nil then
		action = getEmptyAction()
		action.Name = name
		action.Parent = context.context
		
		for _, v in action:GetChildren() do
			local binding = v :: InputBinding
			local bindingName = v.Name
			
			binding:GetPropertyChangedSignal("KeyCode"):Connect(function()
				if binding.KeyCode == Enum.KeyCode.Unknown then return end
				
				-- cannot bind non-gamepad keycodes into gamepad binding
				local isGamepadBinding = binding.KeyCode.Name:find("Button") ~= nil
				if (bindingName == "GamepadBinding") ~= isGamepadBinding then
					binding.KeyCode = Enum.KeyCode.Unknown
					warn("Invalid keybind provided. Gamepad bindings must only use gamepad buttons, and vice versa for keyboard.")
					return
				end
				
				
				-- loop to check for duplicates
				for otherName, V in context.keybinds do
					if V == action then continue end -- don't check itself
					
					if V[bindingName].KeyCode == binding.KeyCode then
						warn(`Conflicting keybinds found for {name} and {otherName}.`)
					end
				end
			end)
		end
		
		context.keybinds[name] = action
	end
	return action
end

function Keybind:EnableContext(context)
	for name, v in keybinds do
		v.context.Enabled = name == context or name == ALWAYS_ON_STATE
	end
	Keybind.CurrentContext = context
end

return Keybind

