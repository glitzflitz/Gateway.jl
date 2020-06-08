module Gateway

using Sockets

export getgateway

function parse_linux_proc_net_route(file::IOStream)
	# /proc/net/route file:
	# Iface	Destination	Gateway 	Flags	RefCnt	Use	Metric	Mask		MTU	Window	IRTT
	# wlo1	00000000	0100A8C0	0003	0	0	600	00000000	0	0	0
	# wlo1	0000A8C0	00000000	0001	0	0	600	00FFFFFF	0	0	0

	sep = "\t"
	field = 14

	scanner = read(file, String)
	tokens = split(scanner, sep)
	if length(tokens) <= field
		throw(error("No gateway found"))
	end

	gateway = parse(UInt32, tokens[field], base=16)
	gateway = hton(gateway) # Convert hex address to big endian
	Sockets.IPv4(gateway)
end

function parse_windows_route(output::IOStream)
	# Windows "route print 0.0.0.0" output:
	# ===========================================================================
	# Interface List
	# 3 ...02 16 4a a8 72 ca ...... Intel(R) PRO/100 VE Network Connection
	# 1 ........................... Software Loopback Interface 1
	# ===========================================================================
	# IPv4 Route Table
	# ===========================================================================
	# Active Routes:
	# Network Destination        Netmask          Gateway       Interface  Metric
	#           0.0.0.0          0.0.0.0      192.168.0.1    192.168.0.100     20
	# ===========================================================================
	#
	# Get to "Active Routes" section and jump 2 lines below and pick address from 3rd column

	sep = "\n"
	column = 3

	scanner = read(output, String)
	tokens = split(output, sep)
	sep = 0
	for (idx, line) in enumerate(tokens)
		if sep == 3
			if length(tokens) <= idx  + 2
				throw(error("No gateway found"))
			end

			fields = split(tokens[idx+2])
			if length(fields) < 3
				throw(error("No gateway found"))
			end

			return Sockets.IPv4(fields[column])
		end

		if startswith(line, "=======")
			sep += 1
			continue
		end
	end
	throw(error("No gateway found"))
end

function parse_osx_route(output::IOStream)
	# Darwin route frame:
	#    route to: default
	# destination: default
	#        mask: default
	#     gateway: 192.168.1.1

	sep = "\n"
	column = 2

	scanner = read(output, String)
	tokens = split(scanner, sep)

	for line in tokens
		fields = split(line)
		if length(fields) >=2 && fields[column - 1] == "gateway:"
			return Sockets.IPv4(fields[column])
		end
	end

	throw(error("No gateway found"))
end

function parse_unix_netstat(output::IOStream)
	# For unix based OS such as *BSD, solaris etc
	# netstat -rn output:
	# Routing tables
	#
	# Internet:
	# Destination        Gateway            Flags      Netif Expire
	# default            10.88.88.2         UGS         em0
	# 10.88.88.0/24      link#1             U           em0
	# 10.88.88.148       link#1             UHS         lo0
	# 127.0.0.1          link#2             UH          lo0
	#
	# Internet6:
	# Destination                       Gateway                       Flags      Netif Expire
	# ::/96                             ::1                           UGRS        lo0
	# ::1                               link#2                        UH          lo0
	# ::ffff:0.0.0.0/96                 ::1                           UGRS        lo0
	# fe80::/10                         ::1                           UGRS        lo0
	# ...
	sep = "\n"
	column = 2
	scanner = read(output, String)
	tokens = split(scanner, sep)

	for line in tokens
		fields = split(line)
		if length(fields) >=2 && fields[column - 1] == "default"
			return Sockets.IPv4(fields[column])
		end
	end

	throw(error("No gateway found"))
end

function getgateway()
	if Sys.islinux()
		open("/proc/net/route") do file
			return parse_linux_proc_net_route(file)
		end
	elseif Sys.iswindows()
		output = read(`cmd /c route print 0.0.0.0`)
		return parse_windows_route(output)
	elseif Sys.isapple()
		output = read(`/sbin/route -n get 0.0.0.0`)
		return parse_osx_route(output)
	elseif Sys.isbsd()
		output = read(`netstat -rn`)
		return parse_unix_netstat(output)
	else
		println("Operating system not supported please file a issue on github")
	end
end


end #module
