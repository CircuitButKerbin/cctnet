require "cctnet.lowlevel.layer4"
---@class iTestable
---@field test fun(self):boolean

---@class MethodTest : iTestable
---@field name string
---@field targetMethod fun(...):... 
---@field validator fun(...):boolean
---@field test fun(self):boolean
---@field failMessage string | nil

MethodTest = {
    new = function(name, validator, targetMethod, ...)
        local o = {
            args = table.pack(...),
            targetMethod = targetMethod,
            validator = validator,
            failMessage = nil,
            name = name,
            results = {}
        }
        o.test = function(self)
            local results = table.pack(xpcall(self.targetMethod, function(err) return err end, table.unpack(self.args)))
            if results[1] then
                self.results = results
                return self.validator(table.unpack(results, 2, results.n))
            end
            self.failMessage = results[2]
            return false
        end
        local mt = {
            __call = function(self)
                return self:test()
            end,
        }
        setmetatable(o, mt)
        return o
    end
}
---@class TestSuit
---@field Tests table<MethodTest>
---@field add fun(self, test:MethodTest)
---@field run fun(self):boolean

TestSuit = {
    Tests = {},
    failedTests = {},
    add = function(self, test)
        table.insert(self.Tests, test)
    end,
    run = function(self)
        local result = true
        for _, test in ipairs(self.Tests) do
            print(string.format("Running test #%d (\"%s\")", _, test.name))
            if not test() then
                print(string.format("\x1b[1A\x1b[1G\x1b[\x1b[48;5;52mTest #%d(\"%s\") failed with result \"%s\" \x1b[0m", _, test.name, test.results[2] or "nil"))
                if test.failMessage then
                    print(string.format("Fail message: %s", test.failMessage))
                end
                self.failedTests[#self.failedTests + 1] = test
                result = false
            else
                print(string.format("\x1b[1A\x1b[1GTest #%d(\"%s\") passed with result %s", _, test.name, test.results[2] or "nil"))
            end
        end
        print(string.format("\x1b[48;5;52m%d\x1b[0m Test Failed", #self.failedTests))
        print(string.format("\x1b[48;5;22m%d\x1b[0m Test Passed", #self.Tests - #self.failedTests))
        if #self.failedTests > 0 then
            print("Failed Tests:")
            for _, test in ipairs(self.failedTests) do
                print(string.format("Test #%d (\"%s\") failed", _, test.name))
                if test.failMessage then
                    print(string.format("Fail message: %s", test.failMessage))
                end
            end
        end
        return result
    end
}
---MAC
TestSuit:add(MethodTest.new("MACAddress.new(0)", function (result) return tostring(result) == "00:00:00:00:00:00"; end, MACAddress.new, 0))
TestSuit:add(MethodTest.new("MACAddress.new(0x123456789ABC)", function (result) return tostring(result) == "12:34:56:78:9A:BC"; end, MACAddress.new, 0x123456789ABC))
TestSuit:add(MethodTest.new("MACAddress.new(\"00:00:00:00:00:00\")", function (result) return tostring(result) == "00:00:00:00:00:00"; end, MACAddress.new, "00:00:00:00:00:00"))
TestSuit:add(MethodTest.new("MACAddress.new(\"12:34:56:78:9A:BC\")", function (result) return tostring(result) == "12:34:56:78:9A:BC"; end, MACAddress.new, "12:34:56:78:9A:BC"))
TestSuit:add(MethodTest.new("MACAddress.new(\"00:00:00:00:00:00\") == MACAddress.new(0)", function (result) return result; end, function() return MACAddress.new("00:00:00:00:00:00") == MACAddress.new(0); end))
TestSuit:add(MethodTest.new("MACAddress.new(\"12:34:56:78:9A:BC\") == MACAddress.new(0x123456789ABC)", function (result) return result; end, function() return MACAddress.new("12:34:56:78:9A:BC") == MACAddress.new(0x123456789ABC); end))
--IP
TestSuit:add(MethodTest.new("IPAddress.new(0)", function (result) return tostring(result) == "0.0.0.0" end, IPAddress.new, 0))
TestSuit:add(MethodTest.new("IPAddress.new(0x12345678)", function (result) return tostring(result) == "18.52.86.120" end, IPAddress.new, 0x12345678))
TestSuit:add(MethodTest.new("IPAddress.new(\"18.52.86.120\")", function (result) return tostring(result) == "18.52.86.120" end, IPAddress.new, "18.52.86.120"))
TestSuit:run()