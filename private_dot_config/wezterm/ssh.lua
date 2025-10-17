local private_exists, private_config = pcall(require, "private") -- Load private config if it exists

local M = {}

M.setup = function(config)
	if private_exists and private_config ~= nil and private_config.ssh_domains then
		config.ssh_domains = private_config.ssh_domains
	end
end

return M
