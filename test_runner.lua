local tests = require "tests"

local failures = 0
local count = 0

for name, test in pairs(tests) do
    local success, error_message = pcall(test)
    
    if not success then
        print(name, "Failed: ", error_message)
        failures = failures + 1
    end
    
    count = count + 1
end

print("Ran", count, "tests with", failures, "failures")

return failures