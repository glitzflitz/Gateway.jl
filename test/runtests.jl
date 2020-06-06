using Gateway
using Test

@testset "GetGateway.jl" begin
	if Sys.islinux()
		result = Gateway.parse_linux_proc_net_route(open("/proc/net/route"))
	    @test Gateway.getgateway() == result
	end
end

