module Gateway
using Sockets

#err_no_gateway = error("No gateway found")

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
	ipv4 = Sockets.IPv4(gateway)
	ipv4
end

end #module
