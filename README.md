# ansible_go_deploy
Vagrant and Ansible setup to deploy a simple go app


## Instructions:

To run this, please clone this repository, then run the following:

```
vagrant up
```

It should then download and install all required vagrant plugins and start bringing up the hosts and provisioning with ansible.

It uses the ansible_local plugin which is currently broken with vagrant <= 1.8.1 and ansible > 2.0.0. So to get around this ansible 1.9.2 is installed
via a seperate provisioner script. The bug report for it is available here:  https://github.com/mitchellh/vagrant/issues/6793

A typical run output is included in [vagrant_up.log](https://github.com/vamegh/ansible_go_deploy/blob/master/vagrant_up.log)

## Accessing the Site:

Vagrant should have automatically added the hostname to the hosts config file, so accessing:

http://lb1.ev9.io

should show the load balanced site working. If this does not work, accessing:

http://192.168.100.10

should show the site. the nodes are also port forwarded to localhost.

Accessing http://localhost:8080 should be a connection directly to the loadbalancer.

Direct connections to the nodes are also made availabled via localhost ports 8001 / 8002 or via http://app1.ev9.io:8484  / http://app2.ev9.io:8484
or their equivalent ips, which can be found in the hosts.yaml config file.

### Screenshots:

<img src="https://raw.githubusercontent.com/vamegh/ansible_go_deploy/master/screenshots/screenshot1.jpg" align=center width="600" height="600" />
<img src="https://raw.githubusercontent.com/vamegh/ansible_go_deploy/master/screenshots/screenshot2.jpg" align=center width="600" height="600" />

## How it works:

Vagrant reads in the Hosts.yaml file, this has all of the various hosts defined, it then builds the boxes as defined within this config and generates an environment file based on the hosts name information.

Ansible is called from playbook.yaml, with a limit of the specific host being run from vagrant the exact command run is as follows:

```
cd /opt/vagrant/ansible && PYTHONUNBUFFERED=1 ANSIBLE_FORCE_COLOR=true ansible-playbook --limit='lb1' --inventory-file=/tmp/vagrant-ansible/inventory -v playbook.yaml
```

/opt/vagrant is a vboxsf mount of the current vagrant folder. The inventory file is auto-created by vagrant, with values passed in from the Vagrantfile.


## Load balancer deployment process:
On the vagrant up invocation, if a loadbalancer(lb) instance is being deployed, ansible will run the lb playbook which runs the common role and the lb role.

The common role is run on all nodes and does the following:

### Common role:
* configures resolv.conf
* installs epel (already installed due to vagrant/ansible bug described above)
* installs common required packages (wget,curl,vim,deltarpm,yum-utils and lsof)
* it can then do a yum update (currently disabled to speed up the deployment process)

The lb role is then run which does the following:

### Loadbalancer (lb) role:
* installs nginx
* configures nginx to work in round-robin mode (very simple config)
* starts nginx
* opens firewall port 80

## App deployment process:
On the vagrant up invocation, if an app instance is being deployed, then the playbook runs through the app match and runs the common and app roles.

The common role is run on all nodes and does the same thing.

The app role does the following:

### App role:
* installs golang
* creates /opt/app directory
* copies the app code  to /opt/app
* compiles the code
* creates a systemd startup configuration file for the app
* runs a systemctl daemon-reload to have the service available
* starts the app and enables app to start on boot
* opens firewall port 8484


## Features
Because of the way it is done, it is trivial to add more apps, to add more loadbalancers requires either a hearbeat between them (for active - passive) or possibly dns entries to round-robin requests to multiple active load-balancers.

To add more apps:
Add the apps to the hosts.yaml.  Example as follows:

```
- :name: 'app<NUM>'
  :hostname: 'app<NUM>.ev9.io'
  :ip: '192.168.100.10<NUM>'
  :netmask: '255.255.255.0'
  :memory: "512"
  :cpu: "1"
  :box: 'puppetlabs/centos-7.0-64-nocm'
  :plat: 'virtualbox'
  :port_forward:
  - :guest: "8484"
    :host: "8001"
```

To provision the new node, either run:

```
vagrant up
```
which will run through and bring everything up or run:

```
vagrant up app<NUM>
```

which will build just the new node.


Then add the app to ansible/group_vars/all:

```
app: all
apps:
  all:
    appservers:
      servers:
        - '192.168.100.101'
        - '192.168.100.102'
      app_port: '8484'
```

and then reprovision the loadbalancer by running vagrant provision lb1, to add the entry to nginx.

Currently, it matches up to app10, if more apps are required the following section in the Vagrantfile will need to be updated:

```
        ansible.groups = {
          "app" => ["app[1:10]"],
          "lb" => ["lb[1:10]"],
          "all:children" => ["app", "lb"],
        }
```

## Automated Upgrades / Build / Delivery of the code

Due to the way this is done and the very useful vagrant provision command, changing the web app code in:

```
ansible/app/files/webapp.go
```

and then running:

```
cat hosts.yaml |grep app|grep :name:|awk -F\' '{print "vagrant provision "$2}'\|/bin/bash
```

Or any variant of this to provision all app nodes, will automatically rebuild / redeploy the code across all of the nodes.


