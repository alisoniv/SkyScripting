# SkyScripting
UCI Capstone 2024-2025

### IMPORTANT Notes for Python Virtual Environment Setup
#### Btw if you have any trouble send disc dm or something
1. Navigate to `SkyScripting` repo folder (NOT `skyscript_model`) and create the environment using `python3.8 -m venv skyenv`
2. Setup the environment:
    - `source skyenv/bin/activate` --> There should be something like (skyenv) at the very left of the command line
    - `pip install jupyter ipykernel`
    - `pip install -r requirements.txt` --> may not work, if not install packages manually ex: `pip install torch` etc.
    - `python3.8 -m ipykernel install --user --name=skyenv --display-name "skyenv (Python 3.8.10)`
3. When running notebooks set the kernel as `skyenv (Python 3.8.10)`