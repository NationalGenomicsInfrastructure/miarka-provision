def authorize_key_for_root(config, user="root", *key_paths)
  [*key_paths, nil].each do |key_path|
    if key_path.nil?
      fail "Public key not found at following paths: #{key_paths.join(', ')}"
    end

    full_key_path = File.expand_path(key_path)

    if File.exists?(full_key_path)
      config.vm.provision 'file',
        run: 'once',
        source: full_key_path,
        destination: '/vagrant/root_pubkey'

     puts "User is #{user}"

     if user == "root" then
      config.vm.provision 'shell',
        privileged: true,
        run: 'once',
        inline: <<-SCRIPT
          echo "Creating /root/.ssh/authorized_keys with #{full_key_path}"
	  mkdir -p /root/.ssh/
          rm -f /root/.ssh/authorized_keys
          mv /vagrant/root_pubkey /root/.ssh/authorized_keys
          chown root:root /root/.ssh/authorized_keys
          chmod 600 /root/.ssh/authorized_keys
          if [ -x "$(command -v sestatus)" ]; then
              sestatus | grep -q "SELinux status:[ \t]*enabled"
              if [ "$?" -eq "0" ]; then
                  restorecon -R -v /root/.ssh
              fi
          fi
          rm -f /vagrant/root_pubkey
          echo "Done!"
          SCRIPT
     else
      config.vm.provision 'shell',
        privileged: true,
        run: 'once',
        inline:
          "echo \"Creating /home/#{user}/.ssh/authorized_keys with #{key_path}\" && " +
	  "mkdir -p /home/#{user}/.ssh/ && " +
          "rm -f /home/#{user}/.ssh/authorized_keys && " +
          "mv /vagrant/root_pubkey /home/#{user}/.ssh/authorized_keys && " +
          "chown #{user}:#{user} /home/#{user}/.ssh/authorized_keys && " +
          "chmod 600 /home/#{user}/.ssh/authorized_keys && " +
          "rm -f /vagrant/root_pubkey && " +
          'echo "Done!"'
     end
    
     break
    end
  end
end

