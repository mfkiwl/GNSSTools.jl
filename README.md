# GNSSTools

A general Julia package for working with GNSS data. Support course acquisition for L5Q signals. New will signals will be added on an as needed basis. Local signal generation and course acquisition methods support multithreading. See instructions for installing this package.

**NOTE:** This is a private repo, but you should still have access to it if logged in. Contact me if you don't.

# Installation

## Allowing Julia to Access SeNSe GitLab Repos

Since this is a private repo, the installation instructions are different than for publically registered Julia packages. Add the following to your `.bashrc` file.

```bash
# Startup ssh-agent and add RSA key for Julia's Package Manager
eval `ssh-agent -s`
ssh-add ~/.ssh/id_rsa  # This could also be the path to your RSA key if it is named differently
```

The above ensures that Julia's package manager can access SeNSe's internal GitLab using the same ssh key you use to make commits. Once you've done this, restart your terminal session by logging out and back in. You will now be able to install internal packages directly through Julia's package manager.

**NOTE:** If your ssh key for GitLab changes, make sure to update the above to point to it.

## Installing GNSSTools

From terminal type `julia` and the type `]` to enter the package manager. Then copy/paste the following:

```julia
add git@192.168.3.66:bilardis/GNSSTools.jl.git
```

Julia will automatically install the neccessary dependencies and GNSSTools. Once complete, you can return the Julia REPL by hitting the `backspace` key. To update GNSSTools if newer versions are released, enter the package manager again by typing `]` and use `update GNSSTools`.


## TODOS

- [ ] Monte Carlo simulation for processing method evaluation
  * static C/N₀ and constellation
  * all other parameters are variable
    + thermal and phase noise are generated for each simulation run
    + initial code phase and carrier phase are picked from a uniform distribution at each iteration
- [ ] multi-PRN simulation
  * each signal from a given PRN is a modulated carrier of specific C/N₀
  * add multiple carriers together into a single raw IQ vector
- [ ] partial sample code offset (two possible methods)
  1. everything is a function of time and is integrated over each sample period
  2. up-sample signal by N times
    * for each sample, N sub-samples are calculated and summed together
    * will not store N sub-samples; will instead calculate them in place and store only the sum of them
- [ ] generate L1C codes
- [ ] User dynamics due to user motion
  * allow user to provide a vector of user positions along with accompanying time vector
  * this vector will be used along with satellite information to calculate Doppler frequency curve
  * Doppler curve will be used for non-linear Doppler simulation
- [ ] FFT based phase noise generation
  * allow user to specify phase noise in frequency domain
  * frequency domain phase noise is converted to time domain using inverse FFT
- [ ] allow seed input for thermal and phase noise sources
- [ ] effects due to ionosphere
  * not needed for X-band frequency, since ionospheric effects are negligible at that frequency
