hosts_file = File.join(File.dirname(__FILE__), "hosts.local")

$dns = {}
File.open(hosts_file) do |f|
    f.each_line do |line|
        ip, *hostnames = line.split(" ")
        for hostname in hostnames
            hostname = hostname.strip()
            ip = ip.strip()
            name = hostname.split(".")[0]
            $dns[name] = {:name => hostname, :ip => ip}
        end
    end
end

