Equipmate.CallbackRegistry = CreateFromMixins(CallbackRegistryMixin)
Equipmate.CallbackRegistry:OnLoad()
local callbacks = {}
for k, v in pairs(Equipmate.Constants.CallbackEvents) do
    table.insert(callbacks, v)
end
Equipmate.CallbackRegistry:GenerateCallbackEvents(callbacks)

--add a sort of 'hook' so that when a private addon event is triggered
--and its listed as a public event
--the EventRegistry will trigger it
--the intention is to remove the need to add triggers in the addon logic
for k, v in pairs(Equipmate.Constants.EventRegistryCallbacks) do
    local f = function(_, ...)
        EventRegistry:TriggerEvent(v, ...)
    end
    Equipmate.CallbackRegistry:RegisterCallback(k, f)
end