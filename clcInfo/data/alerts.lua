local mod = clcInfo.env

-- expose the play function
mod.Alert = clcInfo.display.alerts.Play

--------------------------------------------------------------------------------
function mod.AddAlertIconExpiration(alertIndex, timeLeft, sound)
	local e = mod.___e
	e.hasAlerts = 1
	e.alerts.expiration = {
		alertIndex = alertIndex,
		timeLeft = timeLeft,
		sound = sound,
		
		last = 0,
	}
end
function mod.AddAlertIconStart(alertIndex, sound)
	local e = mod.___e
	e.hasAlerts = 1
	e.alerts.start = {
		alertIndex = alertIndex,
		sound = sound,
		
		last = -1,
	}
end
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
function mod.AddAlertMIconExpiration(id, alertIndex, timeLeft, sound)
	local e = mod.___e
	e.hasAlerts = 1
	if not e.alerts[id] then e.alerts[id] = {} end
	e.alerts[id].expiration = {
		alertIndex = alertIndex,
		timeLeft = timeLeft,
		sound = sound,
		
		last = 0,
	}
end
function mod.AddAlertMIconStart(id, alertIndex, sound)
	local e = mod.___e
	e.hasAlerts = 1
	if not e.alerts[id] then e.alerts[id] = {} end
	e.alerts[id].start = {
		alertIndex = alertIndex,
		sound = sound,
		
		last = -1,
	}
end
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
function mod.AddAlertBarExpiration(alertIndex, timeLeft, sound)
	local e = mod.___e
	e.hasAlerts = 1
	e.alerts.expiration = {
		alertIndex = alertIndex,
		timeLeft = timeLeft,
		sound = sound,
		
		last = 0,
	}
end
function mod.AddAlertBarStart(alertIndex, sound)
	local e = mod.___e
	e.hasAlerts = 1
	e.alerts.start = {
		alertIndex = alertIndex,
		sound = sound,
		
		last = -1,
		lastReversed = 1000000, -- some really big number
	}
end
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
function mod.AddAlertMBarExpiration(id, alertIndex, timeLeft, sound)
	local e = mod.___e
	e.hasAlerts = 1
	if not e.alerts[id] then e.alerts[id] = {} end
	e.alerts[id].expiration = {
		alertIndex = alertIndex,
		timeLeft = timeLeft,
		sound = sound,
		
		last = 0,
	}
end
function mod.AddAlertMBarStart(id, alertIndex, sound)
	local e = mod.___e
	e.hasAlerts = 1
	if not e.alerts[id] then e.alerts[id] = {} end
	e.alerts[id].start = {
		alertIndex = alertIndex,
		sound = sound,
		
		last = -1,
		lastReversed = 1000000, -- some really big number
	}
end
--------------------------------------------------------------------------------