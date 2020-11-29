#!/usr/bin/env python3
# -*- coding: UTF-8 -*-

# Copyright (c) 2019 The ungoogled-chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
Remove entries of debian/copyright's Files-Excluded patterns that match
files modified in patches
"""

import sys
from pathlib import Path

import debian.copyright

_UNGOOGLED_ROOT = Path(__file__).resolve().parent.parent.parent / 'ungoogled-chromium'

sys.path.insert(0, str(_UNGOOGLED_ROOT / 'devutils'))
from third_party import unidiff
sys.path.pop(0)

sys.path.insert(0, str(_UNGOOGLED_ROOT / 'utils'))
from _common import ENCODING, get_logger, parse_series
sys.path.pop(0)


def _read_series_file(patches_dir, series_file, join_dir=False):
    """
    Returns a generator over the entries in the series file

    patches_dir is a pathlib.Path to the directory of patches
    series_file is a pathlib.Path relative to patches_dir

    join_dir indicates if the patches_dir should be joined with the series entries
    """
    for entry in parse_series(patches_dir / series_file):
        if join_dir:
            yield patches_dir / entry
        else:
            yield entry


def _get_files_excluded(copyright):
    """Returns an iterable of all Files-Excluded patterns"""
    return map(str.strip, copyright.header['Files-Excluded'].strip().splitlines())


def _set_files_excluded(copyright, new_patterns):
    copyright.header['Files-Excluded'] = ''.join(map('\n {}'.format, new_patterns))


def get_modified_files(patches_dir, series_path=Path('series')):
    """
    Yields all files modified by patches in the given patches directory
    """
    for patch_path in _read_series_file(patches_dir, series_path, join_dir=True):
        with patch_path.open(encoding=ENCODING) as file_obj:
            try:
                patch = unidiff.PatchSet(file_obj.read())
            except unidiff.errors.UnidiffParseError as exc:
                get_logger().exception('Could not parse patch: %s', patch_path)
                raise exc
            for patched_file in patch:
                if patched_file.is_removed_file or patched_file.is_modified_file:
                    yield patched_file.path


def _is_inside(outer, inner):
    return outer.parts == inner.parts[:len(outer.parts)]


def _make_pattern_filter(file_iterable):
    def should_keep_pattern(pattern):
        pattern_regex = None
        pattern_path = Path(pattern)
        if '*' in pattern:
            pattern_regex = debian.copyright.globs_to_re([pattern])
        for filepath in file_iterable:
            if pattern_regex:
                if pattern_regex.fullmatch(filepath):
                    return False
            elif _is_inside(pattern_path, Path(filepath)):
                return False
        return True
    return should_keep_pattern


def main():
    """CLI entrypoint"""

    debian_dir = Path(__file__).resolve().parent.parent

    # Get all modified files
    files_modified = set(get_modified_files(debian_dir / 'patches'))
    files_modified.update(get_modified_files(_UNGOOGLED_ROOT / 'patches'))

    with (debian_dir / 'copyright').open() as copyright_file:
        copyright = debian.copyright.Copyright(copyright_file)

    # New iterable of files to exclude
    files_excluded = filter(_make_pattern_filter(files_modified), _get_files_excluded(copyright))

    # Update copyright object
    _set_files_excluded(copyright, files_excluded)

    # Write new copyright file
    with (debian_dir / 'copyright').open('w') as copyright_file:
        copyright.dump(copyright_file)

if __name__ == '__main__':
    main()
