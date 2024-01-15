Equipmate.CallbackRegistry = CreateFromMixins(CallbackRegistryMixin)
Equipmate.CallbackRegistry:OnLoad()
local callbacks = {}
for k, v in pairs(Equipmate.Constants.CallbackEvents) do
    table.insert(callbacks, v)
end
Equipmate.CallbackRegistry:GenerateCallbackEvents(callbacks)