local BankAccount = {Owner = "", Value = 0, Pin = ""}


--Metamethods
BankAccount.__index = BankAccount
BankAccount.__type = "BankAccount"

BankAccount.__add = function(self, adding)
	if not adding or type(adding) ~= "table" then
		error("Attempt to add type: "..type(adding).." to type: "..self.__type)
		return self	
	end
	if adding.__type ~= "BankAccount" then return self end

	local _,amount =adding:Withdraw(adding.Value, adding.Pin)
	self:Deposit(amount, self.Pin)
	return self
end
BankAccount.__sub = function(self, removing)
	if not removing or type(removing) ~= "table" then
		error("Attempt to add type: "..type(removing).." to type: "..self.__type)
		return self	
	end
	if removing.__type ~= "BankAccount" then return self end
	local success,amount = self:Withdraw(removing.Value, self.Pin)	
	if not success then
		success,amount = self:Withdraw(self.value, self.Pin)
		removing:Deposit(amount, removing.Pin)
	end
	removing:Deposit(amount, removing.Pin)
	return self

end

function BankAccount.new(owner, value, pin)
	local self = setmetatable({}, BankAccount)
	self.Owner = owner
	self.Value = value
	self.Pin = pin

	return self

end

function BankAccount:Deposit(amount, pin)
	if pin ~= self.Pin then return false, 0 end
	if amount <= 0 then return false, 0 end
	self.Value += amount
	return true, amount
end

function BankAccount:Withdraw(amount, pin)
	if pin ~= self.Pin then return false, 0 end
	if amount <= 0 then return false, 0 end
	local amountCanWithdraw = math.min(self.Value, amount)
	self.Value-= amountCanWithdraw
	return true, amountCanWithdraw

end
return BankAccount