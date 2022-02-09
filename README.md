# Ansible deployment

## Requirements
* Ubuntu 20.02 machine for deployment
* [Python 3.8](https://www.python.org/downloads/)
* [Ansible 3](https://docs.ansible.com/ansible/2.8/installation_guide/intro_installation.html) on controlling machine

## Installing Ansible
In order to ensure that the correct version of Ansible and it's dependencies is installed, we suggest you use [pipenv](https://pipenv.pypa.io/en/latest/) to install it in a [virtual environment](https://virtualenv.pypa.io/en/latest/):

1. [Install pipenv](https://pipenv.pypa.io/en/latest/#install-pipenv-today)
2. Activate pipenv shell: `pipenv shell` (from project directory, installs Ansible and dependencies)
3. Ansible is ready to be used.

## Inventory
The default Ansible configuration we're using, `ansible.cfg` in the current directory, configures the [inventory](https://docs.ansible.com/ansible/2.8/user_guide/intro_inventory.html) in `inventory.yml` in the current directory. In our production setting we pull the inventory in a separate, private, repository.

In order to use Ansible deployment, `backend` and `frontend` host groups need to be configured here. An example is provided in [`inventory_example.yml`](inventory_example.yml).

## Ansible Galaxy requirements
May be installed with:
```sh
$ ansible-galaxy install -r requirements.yml
```

## Secrets / vault
In addition to the inventory, a succesful deployment requires several secrets to be configured in the inventory. By default, the vault password is [encrypted with GPG](https://medium.com/@towo/wrapping-ansible-vault-with-gpg-b107b0e7a5e8) for increased security and to reduce password typing. To randomly generate and encrypt a password file, run `vault/create_passphrase.sh`.

## Bootstrappeing
The `bootstrap` playbook will make sure `sudo` and `Ansible` are available on the machine, assuming initial SSH root access. It creates a remote SSH user with pubkey authentication and sudo rights on the server(s) and completely disables password login.

After bootstrapping, the `site` playbook will do common configuration, including the backend and the frontend.

Then, using , execute:
```sh
$ ansible-playbook bootstrap.yml --user root --ask-pass
$ ansible-playbook site.yml
```

## Frontend deploy

### Staging vs. production certificates
By default, staging certificates are requested from LetsEncrypt. Once the above process proceeds, the variable `certbot_test` should be set to `false` in `inventory.yml`.

### Deploying frontend updates
By default, the `v2` branch of the [frontend repository] is deployed, using the following command (the `-t frontend` makes sure that only the actual frontend code is deployed, rather than the entire frontend server setup):

```sh
$ ansible-playbook frontend.yml -t frontend
```

## Deploying on Hetzner infrastructure
In our production environment, we are deploying to Hetzner's bare metal root servers.

### Generating inventory
For verbosity reasons, we are using Ansible to *generate* certain inventory variables: hostnames, VLAN DMZ ip's, IPFS node keys
Once a new host has been delivered by Hetzner, it will show up in the inventory and the `setup_inventory.yml` playbook can be used to generate the required variables. This will not require any interaction with any server, but it does have local dependencies, particularly [go-ipfs](https://dist.ipfs.io/#go-ipfs). Once IPFS is installed, run:

```sh
ansible-playbook setup_inventory.yml
```

### Install a new server
In order to (re)install a machine, first make sure the machine is running in the [rescue system](https://docs.hetzner.com/robot/dedicated-server/troubleshooting/hetzner-rescue-system/). Then, run:

```sh
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root setup_hetzner.yml -l <hostname>
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u root bootstrap.yml -l <hostname>
ansible-playbook setup_server.yml -l <hostname>
ansible-playbook site.yml
```
