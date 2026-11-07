local script = assert(arg[1])
local scripts = assert(script:match('^(.*)[/\\]main.lua$'))
local config = scripts .. '/../config.ini'
local nativeStatus, statusMissing
local handler, enabled, vehicles, active = nil, true, false, true
local messages = {}
local registered = {}
local host, worldReady = true, true
local nativeCalls = 0
local world = {IsValid=function() return worldReady end}
world.AuthorityGameMode = {IsValid=function() return host end}
FindFirstOf=function(name)
    assert(name=='GameInstance')
    return {IsValid=function() return true end, GetWorld=function() return world end}
end
local function write(path, text) local f=assert(io.open(path,'w')); assert(f:write(text)); assert(f:close()) end
local function read(path) local f=assert(io.open(path,'r'));local s=f:read('*a');f:close();return s end
local function updateStatus()
    local text = active and ('ACTIVE: Safe explosions '..(enabled and 'ON.' or 'OFF.')..
        ' Attached vehicle destruction '..(vehicles and 'ON.' or 'OFF.')) or 'INACTIVE: unsupported build'
    nativeStatus = text
end
local function loadSettings()
    local text=read(config):match('%[Explosions%]([^%[]*)') or ''
    local protection=text:match('ProtectVehicles=(%w+)')
    vehicles=protection and protection=='false' or
        (not protection and text:find('AllowAttachedVehicleDestruction=true',1,true)~=nil)
    updateStatus()
end
write(config,'; keep this comment\n[Explosions]\nEnabled=false\nAllowAttachedVehicleDestruction=false\nOtherSetting=123\n[Other]\nEnabled=leave-this-alone\nKeep=true\n')
package.loadlib=function(_,name)
    if name=='luaopen_babyproofdynamites' then return function() nativeCalls=nativeCalls+1; enabled=true;loadSettings() end end
    if name=='luaopen_babyproofdynamites_refresh' then return function() nativeCalls=nativeCalls+1;loadSettings() end end
    if name=='luaopen_babyproofdynamites_on' then return function() nativeCalls=nativeCalls+1; if active then enabled=true end;updateStatus() end end
    if name=='luaopen_babyproofdynamites_off' then return function() nativeCalls=nativeCalls+1; if active then enabled=false end;updateStatus() end end
    if name=='luaopen_babyproofdynamites_status' then return function(...) assert(select('#',...)==13);if statusMissing then error('Native status unavailable') end;return nativeStatus end end
    error('Unknown export: '..name)
end
RegisterConsoleCommandHandler=function(name,fn) assert(not registered[name]);registered[name]=fn;if name=='babyproof' then handler=fn end end
local output={Log=function(_,text) messages[#messages+1]=text end}
statusMissing = false
local function expectedSummary()
    if not active then
        return 'Babyproof: INACTIVE\nEquipment: NOT PROTECTED BY THIS MOD\nVehicles: NOT PROTECTED BY THIS MOD\nunsupported build\n'
    end
    if not enabled then
        return 'Babyproof: OFF (vanilla explosions)\nEquipment: NOT PROTECTED\nVehicles: NOT PROTECTED\n'
    end
    return 'Babyproof: ON (tiny explosions)\nEquipment: PROTECTED\nVehicles: '..
        (vehicles and 'BREAKABLE (direct attachment required)' or 'PROTECTED')..'\n'
end
local function command(...)
    local count=#messages
    assert(handler('',{...},output))
    assert(#messages==count+1)
    local result=messages[#messages]
    if statusMissing then
        assert(result:find('Babyproof: STATUS UNAVAILABLE',1,true))
        assert(result:find('Protection could not be confirmed.',1,true))
    else
        local expected=expectedSummary()
        assert(result:sub(-#expected)==expected,result)
    end
    return result
end

dofile(script)
assert(enabled and not vehicles)
local clientReply = "Baby-proof Explosions is a server side mod. Only the host can change protection settings.\nIf the host does not have the mod installed, vanilla explosions apply.\n"
local clientConfig,clientStatus=read(config),nativeStatus
local priorCalls=nativeCalls
host=false
for _,params in ipairs({{}, {'status'}, {'on'}, {'off'}, {'v','on'}, {'vehicles','off'}, {'vehicle','ON'}, {'bogus'}}) do
    local count=#messages
    assert(handler('',params,output))
    assert(#messages==count+1 and messages[#messages]==clientReply)
    assert(read(config)==clientConfig and nativeStatus==clientStatus and nativeCalls==priorCalls)
end
host=true;worldReady=false
assert(handler('',{'on'},output))
assert(messages[#messages]:find('could not determine host status',1,true))
assert(nativeCalls==priorCalls and read(config)==clientConfig)
worldReady=true
print('PASS: all client commands return exact server-only message; no config/status/native changes; unknown world blocks changes; host commands resume.')
local before=read(config)
local help=command()
assert(not help:find('babyproof toggle',1,true) and not help:find('babyproof vehicle status',1,true))
assert(read(config)==before)
assert(command('status')==expectedSummary())
command('v','off');assert(vehicles and enabled)
assert(read(config):find('ProtectVehicles=false',1,true))
local beforeMainCommand=read(config)
command('off');assert(read(config)==beforeMainCommand and not enabled and vehicles)
assert(command('status')==expectedSummary())
assert(command('vehicle','on'):find('Babyproof turned ON.',1,true))
assert(enabled and not vehicles)
command('vehicle','off');assert(enabled and vehicles)
command('on');assert(enabled and not vehicles)
assert(read(config):find('ProtectVehicles=true',1,true))
assert(not read(config):find('AllowAttachedVehicleDestruction',1,true))
command('OFF');assert(not enabled and not vehicles)
command('vehicle','off');assert(not enabled and vehicles)
command('vehicles','on');assert(enabled and not vehicles)
command('V','OFF');assert(enabled and vehicles)
command('off');assert(not enabled and vehicles)
loadSettings();assert(not enabled and vehicles)
enabled=true;loadSettings();assert(enabled and vehicles)
command('ON');assert(enabled and not vehicles)
local saved=read(config)
assert(saved:find('; keep this comment',1,true) and saved:find('OtherSetting=123',1,true))
assert(saved:find('[Other]\nEnabled=leave-this-alone\nKeep=true',1,true))
assert(saved:find('Enabled=false',1,true))
for _,params in ipairs({{'bogus'},{'toggle'},{'toggle','on'},{'v','bogus'},{'vehicle','status'},{'vehicles','status'},{'v','status'}}) do
    assert(command(table.unpack(params)):find('Unknown command.',1,true))
    assert(read(config)==saved and enabled and not vehicles)
end
active=false;updateStatus()
assert(command('status')==expectedSummary())
assert(command():find('babyproof on',1,true))
assert(command('off'):find('Command not applied.',1,true))
command('vehicle','on')
assert(read(config)==saved and enabled and not vehicles)
active=true;updateStatus()
command('off');assert(not enabled)
assert(os.remove(config))
assert(command('on'):find('Command failed:',1,true))
assert(not enabled)
write(config,saved)
statusMissing=true
command('status');command();command('on')
assert(not enabled and read(config)==saved)
statusMissing=false;updateStatus()
command('on');assert(enabled and not vehicles)
local originalOpen=io.open
io.open=function(path,mode)
    assert(not path:find('BabyProofDynamites-status.txt',1,true) and not path:find('BabyProofDynamites-events.txt',1,true))
    return originalOpen(path,mode)
end
command('status');command('off');command('on');command('v','off');command('v','on')
io.open=originalOpen
print('PASS: status and configuration commands do not access diagnostic files.')
local registrations=0
for name,fn in pairs(registered) do
    registrations=registrations+1
    assert(name:lower()=='babyproof' and fn==handler)
    host=true
    assert(fn(name..' StAtUs',{'StAtUs'},output))
    assert(messages[#messages]==expectedSummary())
    assert(fn(name..' VeHiClEs OfF',{'VeHiClEs','OfF'},output))
    assert(enabled and vehicles)
    assert(fn(name..' V oN',{'V','oN'},output))
    assert(enabled and not vehicles)
    local beforeClient, beforeCalls = read(config), nativeCalls
    host=false
    for _,params in ipairs({{}, {'StAtUs'}, {'oN'}, {'OfF'}, {'VeHiClEs','oN'}, {'V','OfF'}}) do
        assert(fn(name,params,output))
        assert(messages[#messages]==clientReply)
        assert(read(config)==beforeClient and nativeCalls==beforeCalls)
    end
end
assert(registrations==512 and registered['baBYprOOf'])
host=true
print('PASS: all 512 command capitalizations; mixed-case options; client message and host-only changes preserved.')
print('PASS: every command/help/error reports current protections; all three states; singular/plural/v ON/OFF; redundant vehicle status removed; inactive/missing status never claims protection; config error preserves runtime state.')
