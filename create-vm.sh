#!/bin/bash
## Create a LAMP box ##

mkdir my-vm && cd my-vm
mkdir www
cat > www/index.php <<EOL
<?php echo "Hello, World!";
EOL

#### Do vagrant setup ####
mkdir vagrant
cat > vagrant/Vagrantfile <<EOL
Vagrant.configure("2") do |config|
  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"
  config.vm.network :private_network, ip: "192.168.33.11"
  # config.ssh.forward_agent = true
 config.vm.synced_folder "../www", "/var/www"

  config.vm.provision :chef_solo do |chef|
      chef.roles_path = "../chef/roles"
      chef.cookbooks_path = ["../chef/site-cookbooks", "../chef/cookbooks"]
      chef.add_role "webserver"
  end
end
EOL


#### Do chef setup ####
mkdir -p chef/{cookbooks,data_bags,nodes,roles,site-cookbooks}
cd chef
git init .
git submodule add https://github.com/opscode-cookbooks/apt.git cookbooks/apt
git submodule add https://github.com/opscode-cookbooks/apache2.git cookbooks/apache2
git submodule add https://github.com/opscode-cookbooks/mysql.git cookbooks/mysql
git submodule add https://github.com/opscode-cookbooks/php.git cookbooks/php
git submodule add https://github.com/opscode-cookbooks/openssl.git cookbooks/openssl
git submodule add https://github.com/opscode-cookbooks/vim.git cookbooks/vim

cat > roles/webserver.rb <<EOL
name "webserver"

override_attributes(
    "mysql" => {
        "server_root_password" => 'password',
        "server_repl_password" => 'password',
        "server_debian_password" => 'password'
    }
)

run_list(
    "recipe[apt]",
    "recipe[openssl]",
    "recipe[apache2]",
    "recipe[apache2::mod_php5]",
    "recipe[mysql]",
    "recipe[mysql::server]",
    "recipe[php]",
    "recipe[php::module_mysql]",
    "recipe[apache2::vhosts]",
    "recipe[vim]"
)


EOL

mkdir -p site-cookbooks/apache2/recipes

cat > site-cookbooks/apache2/recipes/vhosts.rb <<EOL
include_recipe "apache2"


web_app "example" do
  server_name "www.example.vm"
  server_aliases ["example.vm"]
  allow_override "all"
  docroot "/var/www/"
end
EOL
cd ..