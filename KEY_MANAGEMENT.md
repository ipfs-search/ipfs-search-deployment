# Key management
We're [Yubikeys](https://www.yubico.com/products/yubikey-5-overview/) to generate and store OpenGPG keys, which are also used for SSH logins. This provides strong guarantees as to the number of keys with access to infrastructure. However, as this method does not allow us to backup our private key, it is essential to have at least one spare Yubikey.

## Setting the PIN for the Yubikey
For the Yubikey to provide actual security, it is essential to configure both a normal as well as an Admin PIN for it. In doing so, it is a best practise to enable Key Derived Format (KDF). With the KDF function enabled, the PIN is stored as a hash on the YubiKey.

```
$ gpg --edit-card
gpg/card> admin
gpg/card> kdf-setup
gpg/card> passwd
gpg: OpenPGP card no. D2760001240103030006294453760000 detected

1 - change PIN
2 - unblock PIN
3 - change Admin PIN
4 - set the Reset Code
Q - quit

Your selection? 1
PIN changed.
```

For more background on managing PIN's please refer to the [GnuPG card HOWTO](https://www.gnupg.org/howtos/card-howto/en/ch03s02.html) and the [Yubico documentation on KDF](https://developers.yubico.com/PGP/YubiKey_5.2.3_Enhancements_to_OpenPGP_3.4.html).

## Generating keys on the Yubikey
In order to have strong guarantees it is essential that keys are generated *on the Yubikey*, instead of being generated on the computer and imported afterwards.

The best reference on how to do this is the [GnuPG card HOWTO](https://www.gnupg.org/howtos/card-howto/en/ch03s03.html).

**NOTE** During the key generation a 'backup' is made, however the backup should only contain bogus data as the Yubikey does not allow exporting private keys.

## Cross-signing and publishing (signed) keys
To increase and trust, it is recommended that newly generated keys are signed by previous keys from the same older. This goes both for pre-existing non-Yubikey GPG keys as well as any spare-keys. This way, the trust which has been extended to one key will propagate to the other; new members on the team will only need to trust a single key and other keys are automatically marked as trusted.

**TODO**

## Exporting and backing up revocation certificates
Under circumstances where a key gets lost, the key needs to be revoked and the revocation needs to be propagated to the key server. To be able to do this, a revocation certificate can be generated which can *only* be used to revoke and thus disable generated keys, once they get out of control.

**TODO**

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

## Attestation
Attestation allows one to verify whether the keys on a Yubikey were properly generated (e.g. on the key) and whether or not the correct security features are set.

The following steps require the following utils and their dependencies to be installed on the system:
- [ykman](https://docs.yubico.com/software/yubikey/tools/ykman/)
- [yk-attest-verify](https://github.com/joemiller/yk-attest-verify)

### Generating and signing attestation certificate
```
ykman openpgp keys attest AUT attestation.pem
ykman openpgp certificates export ATT signer.pem
```

### Verifying attestation certificate
1. Verify the signature chain (`yk-attest-verify pgp attestation.pem signer.pem`).
2. Compare the public keys from an SSH pub key file to the public key on the YubiKey (`--ssh-pub-key="id_rsa.pub"`).
3. Verify the attested key was generated on the YubiKey (`--allowed-keysources="generated"`).
4. Verify the attested key has an allowed [Touch Policy](https://docs.yubico.com/software/yubikey/tools/ykman/OpenPGP_Commands.html?highlight=policy#touch-policies) set (`--allowed-touch-policies="enabled-permanent-cached"`).
```
yk-attest-verify pgp attestation.pem signer.pem \\
   --ssh-pub-key="id_rsa.pub" \\
   --allowed-keysources="generated" \\
   --allowed-touch-policies="enabled-permanent-cached"
```

## Importing pre-existing SSH keys as subkeys of a Yubikey (tedious/advanced/optional)

**NOTE** This has not yet been performed succesfully.

You can find the id of your Yubikey using `gpg -K`.

Convert existign SSH key to PEM format:
```
$ ssh-keygen -p -m PEM -f ~/.ssh/id_rsa
```

Convert PEM SSH key to OpenGPG format and import it into `gpg`:
```
$ brew install monkeysphere
$ pem2openpgp temporary_id < ~/.ssh/id_rsa | gpg --import
```

List imported and hardware Yubikey:
$ gpg -K --with-keygrip

Import/add SSH key as subkey to Yubikey:
```
$ gpg --expert --edit-key <yubikey_id>
gpg> addkey
Secret parts of primary key are stored on-card.
Please select what kind of key you want:
   (3) DSA (sign only)
   (4) RSA (sign only)
   (5) Elgamal (encrypt only)
   (6) RSA (encrypt only)
   (7) DSA (set your own capabilities)
   (8) RSA (set your own capabilities)
  (10) ECC (sign only)
  (11) ECC (set your own capabilities)
  (12) ECC (encrypt only)
  (13) Existing key
  (14) Existing key from card
Your selection? 13
Enter the keygrip: <imported_ssh_keygrip>

Possible actions for a RSA key: Sign Encrypt Authenticate
Current allowed actions: Sign Encrypt

   (S) Toggle the sign capability
   (E) Toggle the encrypt capability
   (A) Toggle the authenticate capability
   (Q) Finished

Your selection? s

Possible actions for a RSA key: Sign Encrypt Authenticate
Current allowed actions: Encrypt

   (S) Toggle the sign capability
   (E) Toggle the encrypt capability
   (A) Toggle the authenticate capability
   (Q) Finished

Your selection? e

Possible actions for a RSA key: Sign Encrypt Authenticate
Current allowed actions:

   (S) Toggle the sign capability
   (E) Toggle the encrypt capability
   (A) Toggle the authenticate capability
   (Q) Finished

Your selection? a

Possible actions for a RSA key: Sign Encrypt Authenticate
Current allowed actions: Authenticate

   (S) Toggle the sign capability
   (E) Toggle the encrypt capability
   (A) Toggle the authenticate capability
   (Q) Finished

Your selection? q
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0)
Key does not expire at all
Is this correct? (y/N) y
Really create? (y/N) y
```

Remove previously imported SSH key:
```
gpg --delete-secret-and-public-key <ssh-key-id>
```

Enable import SSH key for SSH login:
```
echo <imported_ssh_keygrip> >> ~/.gnupg/sshcontrol
```

Now SSH login *should* work, but we have so far been unsuccesful.

[Reference](https://opensource.com/article/19/4/gpg-subkeys-ssh-multiples)
