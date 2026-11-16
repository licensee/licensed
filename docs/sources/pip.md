# Pip

The pip source uses `pip` CLI commands to enumerate dependencies and properties. It is expected that `pip` is available in the `virtual_env_dir` specific directory before running `licensed`.

License contents are read from installed license files, not the free-form `License` field in `pip show` output. That field is excluded from metadata parsing because bundled license text can contain headings that resemble package metadata.

A `virtualenv` directory is required before running `licensed`. You can setup a `virtualenv` by running the command:
```
virtualenv <your_venv_dir>
```
_note_: `<your_venv_dir>` path should be relative to the repository root or can be specified as an absolute path.

#### virtual_env_dir (Required)

The `pip` command will be sourced from this directory.
You have to add this setting to your licensed configuration file.
An example usage of this might look like:
```yaml
python:
    virtual_env_dir: "/path/to/your/venv_dir"
```
