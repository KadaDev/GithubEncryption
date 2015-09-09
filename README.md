# GithubEncryption
Encrypts files using the public github keys of all users with push access to the repository

# Requirements
- openssl
- ruby
- push access to the github repo that you wish to get collaborators from

## Notes
- Max file size is probably around 240B
- Encrypted files are `(number of keys) * 256B` in size

# Usage
Edit files.conf to add files that you want to encrypt.

run `ruby encrypt.rb` to encrypt the files

run `ruby decrypt.rb` to decrypt the files
