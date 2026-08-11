-- modules/departments.lua

local departments = {
	name = "departments",
	description = "Handles all department related interactions.",
}

local connections = {}

departments.Start = function()
	connections["memberDepartments"] = Client:on("memberDepartments", function(member, config)
		local guild = member.guild
		local isDep, host, depConfig = db:isDepartment(guild)

		if isDep and host and depConfig then
			local hostMember = host:getMember(member.id)
			if hostMember and depConfig.linkedroles then
				for _, link in pairs(depConfig.linkedroles) do if member:hasRole(link.department) and (not hostMember:hasRole(link.host)) then hostMember:addRole(link.host, "departmental role syncing from department " .. guild.name .. " (" .. guild.id ..")") end end

				local removed = {}
				for _, link in pairs(depConfig.linkedroles) do
					if hostMember:hasRole(link.host) and not removed[link.host] then
						local hasAnyDep = false
						for _, otherLink in pairs(depConfig.linkedroles) do
							if otherLink.host == link.host and member:hasRole(otherLink.department) then hasAnyDep = true; break end
						end
						if not hasAnyDep then
							removed[link.host] = true
							hostMember:removeRole(link.host, "departmental role syncing from department " .. guild.name .. " (" .. guild.id ..")" )
						end
					end
				end
			end

			if hostMember and depConfig.syncnicknames then if hostMember.name ~= member.name then hostMember:setNickname(member.name) end end
		elseif config.departments and table.count(config.departments) > 0 then
			for did, depConfig in pairs(config.departments) do
				local department = Client:getGuild(did)
				local departmentMember = department and department:getMember(member.id)

				if department then
					if departmentMember and depConfig.linkedroles then
						for _, link in pairs(depConfig.linkedroles) do if member:hasRole(link.host) and (not departmentMember:hasRole(link.department)) then departmentMember:addRole(link.department, "departmental role syncing from host " .. guild.name .. " (" .. guild.id ..")") end end

						local removed = {}
						for _, link in pairs(depConfig.linkedroles) do
							if departmentMember:hasRole(link.department) and not removed[link.department] then
								local hasAnyHost = false
								for _, otherLink in pairs(depConfig.linkedroles) do
									if otherLink.department == link.department and member:hasRole(otherLink.host) then hasAnyHost = true; break end
								end
								if not hasAnyHost then
									removed[link.department] = true
									departmentMember:removeRole(link.department, "departmental role syncing from host " .. guild.name .. " (" .. guild.id ..")" )
								end
							end
						end
					end

					if departmentMember and depConfig.syncnicknames then if departmentMember.name ~= member.name then departmentMember:setNickname(member.name) end end
				end
			end
		end
	end)
end

departments.Stop = function()
	for event, connection in pairs(connections) do
		Client:removeListener(event, connection)
	end

	connections = nil
end

return departments
