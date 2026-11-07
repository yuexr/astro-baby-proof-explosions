local dll = assert(arg[1])
local directory = assert(dll:match("^(.*[/\\])"))
local status = assert(package.loadlib(dll, "luaopen_babyproofdynamites_status"))
local initialize = assert(package.loadlib(dll, "luaopen_babyproofdynamites"))
local on = assert(package.loadlib(dll, "luaopen_babyproofdynamites_on"))
local off = assert(package.loadlib(dll, "luaopen_babyproofdynamites_off"))
local labels = {}
for i = 1, 13 do labels[i] = "status " .. i end
local function readStatus() local value = status(table.unpack(labels)); return value end
assert(readStatus() == "status 5")
initialize()
assert(readStatus() == "status 6") -- no game executable in this standalone Lua process
on(); off()
assert(readStatus() == "status 6")
for _, name in ipairs({"BabyProofDynamites-status.txt", "BabyProofDynamites-events.txt"}) do
    local file = io.open(directory .. name, "r")
    assert(not file, "Native code created " .. name)
end
print("PASS: real Lua/native status bridge returns selected status; inactive ON/OFF refused; no diagnostic files created.")
