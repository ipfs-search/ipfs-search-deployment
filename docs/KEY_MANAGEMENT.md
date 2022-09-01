# Key management
We're [Yubikeys](https://www.yubico.com/products/yubikey-5-overview/) to generate and store OpenGPG keys, which are also used for SSH logins. This provides strong guarantees as to the number of keys with access to infrastructure. However, as this method does not allow us to backup our private key, it is essential to have at least one spare Yubikey.

## Attested keys
Ensure that OpenGPG and SSH keys are generated on-device.

### Generate keys
Requires:
* [GnuPG](https://www.gnupg.org/) and possibly scdaemon
* [ykman](https://www.yubico.com/support/download/yubikey-manager/)

It's real sad, but this process is very hard to script.

> If you haven't set a User PIN or an Admin PIN for OpenPGP, the default values are 123456 and 12345678, respectively.
https://support.yubico.com/hc/en-us/articles/360013790259-Using-Your-YubiKey-with-OpenPGP

Make sure to execute below commands *in order*:

#### Enforce touch policy for keys
This requires you to touch the key every 15s, preventing hostile takeover of a computer with the key in it.
```
ykman openpgp keys set-touch enc cached-fixed
ykman openpgp keys set-touch aut cached-fixed
ykman openpgp keys set-touch att cached-fixed
```

#### 1. Start editing card
```
% gpg --card-edit --expert

Reader ...........: Yubico YubiKey OTP FIDO CCID
Application ID ...: <private>
Application type .: OpenPGP
Version ..........: 3.4
Manufacturer .....: Yubico
Serial number ....: <private>
Name of cardholder: [not set]
Language prefs ...: [not set]
Salutation .......:
URL of public key : [not set]
Login data .......: [not set]
Signature PIN ....: not forced
Key attributes ...: rsa2048 rsa2048 rsa2048
Max. PIN lengths .: 127 127 127
PIN retry counter : 0 0 3
Signature counter : 0
KDF setting ......: off
Signature key ....: [none]
Encryption key....: [none]
Authentication key: [none]
General key info..: [none]
```

#### 2. Enable admin commands.
```
gpg/card> admin
Admin commands are allowed
```

#### 3. Enable [KDF](https://developers.yubico.com/PGP/YubiKey_5.2.3_Enhancements_to_OpenPGP_3.4.html) to prevent cleartext PIN exchange/storage
```
gpg/card> kdf-setup
```

#### 4. Set PIN, Admin PIN and reset code

Make sure that the PIN has execatly 6 characters and the admin PIN has exactly 8 characters and *might* have to be numeric. The reset code allows longer alphanumeric options.
```
gpg/card> passwd
gpg: OpenPGP card no. <private> detected

1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit

Your selection? 2
PIN unblocked and new PIN set.

1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit

Your selection? 3
PIN changed.

1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit

Your selection? 4
Reset Code set.

1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit

Your selection? q
```

#### 5. Configure RSA3072 (as of 2022) as algorithm
```
gpg/card> key-attr
Changing card key attribute for: Signature key
Please select what kind of key you want:
   (1) RSA
   (2) ECC
Your selection? 1
What keysize do you want? (2048) 3072
The card will now be re-configured to generate a key of 3072 bits
Changing card key attribute for: Encryption key
Please select what kind of key you want:
   (1) RSA
   (2) ECC
Your selection? 1
What keysize do you want? (2048) 3072
The card will now be re-configured to generate a key of 3072 bits
Changing card key attribute for: Authentication key
Please select what kind of key you want:
   (1) RSA
   (2) ECC
Your selection? 1
What keysize do you want? (2048) 3072
The card will now be re-configured to generate a key of 3072 bits
```

Reference: https://www.keylength.com/

#### 6. Verify settings

Specifically:
* `KDF setting ......: on`
* `Key attributes ...: rsa3072 rsa3072 rsa3072`

```
gpg/card> verify

Reader ...........: Yubico YubiKey OTP FIDO CCID
Application ID ...: <private>
Application type .: OpenPGP
Version ..........: 3.4
Manufacturer .....: Yubico
Serial number ....: <private>
Name of cardholder: [not set]
Language prefs ...: [not set]
Salutation .......:
URL of public key : [not set]
Login data .......: [not set]
Signature PIN ....: not forced
Key attributes ...: rsa3072 rsa3072 rsa3072
Max. PIN lengths .: 127 127 127
PIN retry counter : 3 3 3
Signature counter : 0
KDF setting ......: on
Signature key ....: [none]
Encryption key....: [none]
Authentication key: [none]
General key info..: [none]
```

#### Generate keys

```
gpg/card> generate
Make off-card backup of encryption key? (Y/n) n

Please note that the factory settings of the PINs are
   PIN = '123456'     Admin PIN = '12345678'
You should change them using the command --change-pin

Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0) 3y
Key expires at <private>
Is this correct? (y/N) y

GnuPG needs to construct a user ID to identify your key.

Real name: <private>
Email address: <private>
Comment:
You selected this USER-ID:
    "<private>"

Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? o
```
> **_NOTE:_** Key generation takes a minute or two, all the while your Yubikey will be blinking!
```
gpg: revocation certificate stored as '<private>/.gnupg/openpgp-revocs.d/<private>.rev'
public and secret key created and signed.
```

### Generate certificates
Requires [ykman](https://www.yubico.com/support/download/yubikey-manager/).

Export signer certificate:
```sh
ykman openpgp certificates export ATT signer.pem
```

Export attestation certificates:
> **_NOTE:_** This will require touching the key!

```sh
ykman openpgp keys attest AUT attestation_aut.pem
ykman openpgp keys attest SIG attestation_sig.pem
ykman openpgp keys attest ENC attestation_enc.pem
```

### Verify certificates
Requires [yk-attest-verify](https://github.com/joemiller/yk-attest-verify).

```sh
yk-attest-verify pgp attestation_aut.pem signer.pem --allowed-keysources="generated" --allowed-touch-policies="enabled-permanent-cached" --ssh-pub-key=<ssh_public_key>
yk-attest-verify pgp attestation_aut.pem signer.pem --allowed-keysources="generated" --allowed-touch-policies="enabled-permanent-cached"
yk-attest-verify pgp attestation_aut.pem signer.pem --allowed-keysources="generated" --allowed-touch-policies="enabled-permanent-cached"
```

## Enabling SSH logins through GPG
To secure SSH logins using the Yubikey the [GPG agent](https://linux.die.net/man/1/gpg-agent) (which proxies access to private keys and caches the PIN) can emulate the [OpenSSH agent](https://man.openbsd.org/ssh-agent).

In order to set this up, on most systems it should suffice to add the following line to `~/.gnupg/gpg-agent.conf `:

```
enable-ssh-support
```

In addition, the following lines should be added to `~/.bash_profile`:
```
# on OS X with GPGTools, comment out the next line:
eval $(gpg-agent --daemon)
GPG_TTY=$(tty)
export GPG_TTY
if [ -f "${HOME}/.gpg-agent-info" ]; then
    . "${HOME}/.gpg-agent-info"
    export GPG_AGENT_INFO
    export SSH_AUTH_SOCK
fi
```

In order to activate this configuration, you might want to kill any running GPG agents for the settings to take effect:

```
gpgconf --kill gpg-agent
```

Now you should have everything setup and you should have the GPG key on your Yubikey available for use with SSH.

To confirm as well as to export the public key, run:

```
ssh-add -L
```

Reference: [Yubico documentation](https://developers.yubico.com/PGP/SSH_authentication/)
