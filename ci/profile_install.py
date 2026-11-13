"""Private profile installation with durable ownership tracking."""
import re

def install_profiles(root, home):
    import json
    import os
    from pathlib import Path

    root, home = Path(root), Path(home)
    profile_uuid = (root / 'profile-uuid').read_text().strip()
    if not re.fullmatch(r'[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}', profile_uuid):
        raise ValueError('Invalid canonical profile UUID')
    paths = [home / directory / (profile_uuid + '.mobileprovision') for directory in (
        'Library/MobileDevice/Provisioning Profiles',
        'Library/Developer/Xcode/UserData/Provisioning Profiles',
    )]
    for path in paths:
        if os.path.lexists(path):
            raise FileExistsError(f'Refusing to replace existing profile: {path}')
    source = root / 'profile.mobileprovision'
    import shutil

    journal = root / 'profile-install.json'
    record = {'uuid': profile_uuid, 'files': {}}

    def save():
        temporary = journal.with_suffix('.pending')
        with temporary.open('w') as stream:
            json.dump(record, stream)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, journal)

    save()
    for path in paths:
        path.parent.mkdir(parents=True, exist_ok=True)
        # O_EXCL atomically refuses files/symlinks appearing after preflight.
        # Each destination is a regular file, including across filesystems.
        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, 'wb') as destination:
            metadata = os.fstat(destination.fileno())
            record['files'][str(path)] = {
                'device': metadata.st_dev, 'inode': metadata.st_ino,
                'birthtime': getattr(metadata, 'st_birthtime', None),
            }
            try:
                save()  # Ownership is durable before copying any sensitive bytes.
            except BaseException:
                current = path.lstat()
                if (current.st_dev, current.st_ino) == (metadata.st_dev, metadata.st_ino):
                    path.unlink()
                raise
            with source.open('rb') as incoming:
                shutil.copyfileobj(incoming, destination)
            destination.flush()
            os.fsync(destination.fileno())


def cleanup_profiles(root, home):
    import json
    from pathlib import Path

    root, home = Path(root), Path(home)
    journal = root / 'profile-install.json'
    if not journal.exists():
        return
    record = json.loads(journal.read_text())
    profile_uuid = record['uuid']
    if not re.fullmatch(r'[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}', profile_uuid):
        raise ValueError('Invalid canonical profile UUID in cleanup journal')
    errors = []
    for directory in ('Library/MobileDevice/Provisioning Profiles',
                      'Library/Developer/Xcode/UserData/Provisioning Profiles'):
        path = home / directory / (profile_uuid + '.mobileprovision')
        try:
            stat = path.lstat()
            # Accept the old shared-inode journal for interrupted older runs.
            owned = record.get('files', {}).get(str(path)) if 'files' in record else record
            if owned is None or (stat.st_dev, stat.st_ino) != (owned['device'], owned['inode']):
                raise ValueError('Refusing to delete an unowned provisioning profile')
            if owned.get('birthtime') is not None and stat.st_birthtime != owned['birthtime']:
                raise ValueError('Refusing to delete a replaced provisioning profile')
            path.unlink()
        except FileNotFoundError:
            continue
        except (OSError, ValueError) as exc:
            errors.append(str(exc))
    if errors:
        raise OSError('; '.join(errors))


if __name__ == '__main__':
    import os
    import sys
    from pathlib import Path
    operation, root = sys.argv[1:]
    if operation == 'install':
        install_profiles(Path(root), Path.home())
    elif operation == 'cleanup':
        cleanup_profiles(Path(root), Path.home())
    else:
        raise SystemExit('Unknown operation')
