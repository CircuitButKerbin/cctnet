---@class UnitTest
---@field CheckMethod fun(sucess, ...):boolean 
---@field MethodToTest fun(...):...
---@field MethodTestArgs table
---@field Test fun(self):boolean

UnitTest = {
    CheckMethod = function ()
        assert(false, "Unimplemented Method! Implement me!")
    end,
    MethodToTest = function ()
        assert(false, "MethodToTest was unoverriden. Override this in your unit test!")
    end,
    MethodTestArgs = {},
    Test = function (self)
       local passed = nil;
       local xpres = table.pack(xpcall(self.MethodToTest, function ()
        passed = debug.traceback("UnitTest Debug Traceback")
       end, table.unpack(self.MethodTestArgs)))
       if (xpres[0]) then 
            return self.CheckMethod(table.unpack(xpres))
       else
            return self.CheckMethod(xpres[0], passed)
       end
    end
}