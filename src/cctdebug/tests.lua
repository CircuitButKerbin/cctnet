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
        local o = MethodTest
        o.args = ...
        o.targetMethod = targetMethod
        o.validator = validator
        o.failMessage = nil
        o.name = name
        o.test = function(self)
            local results = table.pack(xpcall(self.targetMethod, function(err) return err end, self.args))
            if results[1] then
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
                print(string.format("Test #%d (\"%s\") failed", _, test.name))
                if test.failMessage then
                    print(string.format("Fail message: %s", test.failMessage))
                end
                self.failedTests[#self.failedTests + 1] = test
                result = false
            end
        end
        if result then
            print("All tests passed")
        else
            print(string.format("%d tests failed", #self.failedTests))
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

TestSuit:add(MethodTest.new("MACAddress.new(0)", MACAddress.new, function (result)
    return tostring(result) == "00:00:00:00:00:00"
end, 0))
TestSuit:run()