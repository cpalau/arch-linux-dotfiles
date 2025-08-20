# Private Directory

This directory contains sensitive files that should NOT be committed to version control.

## Structure

```
private/
├── ssh/          # SSH keys and configuration
│   ├── id_rsa    # Private SSH key
│   ├── id_rsa.pub # Public SSH key
│   └── config    # SSH client configuration
├── gpg/          # PGP/GPG keys
│   ├── private.asc # Private PGP key
│   └── public.asc  # Public PGP key
└── credentials/  # Other sensitive files
    ├── passwords.txt
    └── api_keys.txt
```

## Usage

Place your sensitive files in the appropriate subdirectories. These files will be automatically ignored by git to prevent accidental commits.

## Security Notes

- Never commit files from this directory
- Use proper file permissions (600 for private keys)
- Consider encrypting sensitive files
- Backup these files securely and separately from the git repository