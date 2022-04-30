# NemosMiner

NemosMiner monitors mining pools in real-time in order to find the most profitable Algo

Updated 31 March 2022


Copyright (c) 2018-2022 Nemo, MrPlus & UselessGuru

This is free software, and you are welcome to redistribute it
under certain conditions.
https://github.com/Minerx117/NemosMiner/blob/master/LICENSE

Updated/Maintained by Nemo/Minerx117 & UselessGuru

with a lot of help from MrPlusGH, grantemsley & UselessGuru. Without them NemosMiner would not be possible.

NemosMiner code is partly based on

- MultiPoolMiner which can be found here: https://github.com/MultiPoolMiner/MultiPoolMiner (Project is no longer maintained)

- NPlusMiner which can be found here: https://github.com/MrPlusGH/NPlusMiner


Note: NemosMiner Version 4.x is **NOT backwards compatible** with the 3.8.x code base.
It is highly recommended to install this version to a new directory.

Some configuration options have changed. See 'Changed Config Items.txt' for more information.
NemosMiner will automatically convert an existing configuration file.

*****

**Main features:**
   - GUI and easy configuration
   - Auto Benchmarks each algo to get optimal speeds
   - Fully automated
   - Auto Downloads Miners
   - Auto Updates
   - Monitoring
   - Earnings graph

*****

Easy configuration, easy start:

      Run NemosMiner.bat
      1. Edit configuration (http://localhost:3999/configedit.html)
      2. Set your Wallet address(es) and Username(s)
      3. Select your pool(s)
      4. Save Config
      5. Start

      Note: 2. you only need to change Username if you are using Miningpoolhub or ProHashing

   Algorithm selection / removal

      +[algorithm] to enable algorithm
      -[algorithm] to disable algorithm

      If '+' is used, then only the explicitly enabled algorithms are used
      If '-' is used, then all algorithms except the disabled ones are used
      Leave empty to use ALL available algorithms (not recommended as it may cause more miner switching)

      Do not combine + and - for the same algo

      Examples:
      Algorithm list = -x16r
      Will mine anything but x16r

      Algorithm list = -x16r,-bcd
      Will mine anything but x16r and bcd

      Algorithm list = +x16r
      Will mine only x16r

      Algorithm list = +x16r,+bcd
      Will mine only x16r and BCD

      Algorithm list blank
      Will mine anything

   Pools Variants

      *24hr  - uses last 24hour price data in pool API to calculate profit (no estimates or advanced calculations)

      *Plus - uses advanced calculations to reduce uneeded switching

      normal - uses current price data in pool API to calculate profit (no estimates or advanced calculations)

      *Coins - uses advanced calculations, mines only top paying coin in Algo (MiningPoolHub & ZergPool)


   Developer/Contributors Donation: 
      The list and wallets is stored in [NemosMiner Directory]\Data\DonationData.json

      Donation Fee = 0.9%
      There is 13 minute per day default donation (0.9%),
      which can be increased or decreased in the configuration editor.
      Please help support the great team behind NemosMiner by leaving mining donations turned on.
      We want to stay completely transparent on the way fees are managed in the product.
      Donation cycle occurs once in 24hrs (or once until midnight if NemosMiner has been running less than 24hrs).
      Donation start time is randomized each time.
      It will then mine for one randomly chosen developer / contributor for the configured duration.

      Example for default parameters (13 minutes):
      - NemosMiner was started at 10:00h
      - First donation cycle starts somewhen beween 10:01h and 23:47h and will then donate for 13 minutes, then mine for you again until the next donation run.
      - After 00:00h the donation start time is randomized again. 
      - When donation start time is reached it will then donate for 13 minutes, then mine for you again until the next donation run.
      All donation time and addresses are recorded in the logs files.

   NemosMiner Monitoring Server: https://nemosminer.com

      Keep tabs on all your mining rigs from one place
      You can now optionally monitor all your workers remotely, both in the GUI and via https://nemosminer.com
      Monitoring setup instructions https://nemosminer.com/setup.php

   GUI

      Since version 3.9.9.x (Beta) NemosMiner has a Web GUI making it easy to configure and run.
      NemosMiner relies on config files. No need to edit bat files. Simply run NemosMiner.bat
      Set the config in the Web GUI (http://localhost:3999/configedit.html), apply & start mining

   Pause mining

      Ability to pause miners while keeping other jobs running (pause button)
      This will stop mining activity
      BrainPlus will still run in the background avoiding the learning phase on resume
      EarningTracker will still run in the background to keep the pool balances up to date

   PreRun

      Ability to run a batch prior switching to a specific miner and/or algorithm.
      The prerun scripts can be used to set per miner/algorithm OC via nvidiaInspector or OverdriveNTool.
      Before starting a miner executable NemosMiner is trying to launch one of the following 3 prerun scripts (in this order):
      1. <MinerName>_<Algorithm>.bat
         Simply create a file named <MinerName>_<AlgorithmName>.bat in prerun folder, e.g. 'Bminer-v16.4.11-1xRadeonRX5808GB-Handshake-10.bat' or 'CcminerMTP-v1.3.2-1xGTX10606GB_MTP.bat'
      2. <Algorithm>.bat
         Simply create a file named <AlgorithmName>.bat in prerun folder, e.g. 'Ethash.bat'
      3. default.bat
         If neither of the two above exist, NemosMiner will try to launch prerun\default.bat
      Use overclock with caution

   Per pool config (Advanced)

      **This is for advanced users. Do not use if you do not know what you are doing.**

      The file Config\PoolsConfig.json contains configuration details for the pools.
      A separate section can be added for each pool base name. If a pool is listed in this file,
      the specific settings will be taken into account. If not, the built in default values will be used.
      See \Data\PoolData.json for the basic structure of the file Config\PoolsConfig.json

      You can set specific options per pool. For example, you can mine NiceHash on the internal wallet and other pools on a valid wallet. This configuration is provided as an example in Config\PoolsConfig-NHInternal.json

      Available options:
         - Wallets[Currency] = Your wallet address for [Currency]; some pools, e.g. HiveOn require wallets in each supported currency
         - UserName = your MPH or ProHashing user name
         - WorkerName = your worker name
         - PricePenaltyFactor = See explanation below
         - Algorithm = List of included or excluded algorithms per pool (see example files)
         - PayoutThreshold[Currency] = pool will allow pyout if this amount is reached

      Usage:
         - Edit Config\PoolsConfig.json
         - Add an entry for the pool you want to customize
            - The name must be the pool base name (omit *24hrs or *Coins), e.g ZergPool (even if you have configured ZergPoolCoins in the pool list)
            - (**careful with json formating ;)**

      Note that the GUI only updates default values (valid for ALL pools unless there is pool specific configuration setting defined in 'Config\PoolConfig.json'). Any other changes need to be done manually.

   PricePenaltyFactor

      When using advanced per pool configuration, it is possible to add a penalty factor for a specific pool. This simply adds a multiplicator on estimations presented by the pool.

      Example scenario:
         - You feel like a pool is exaggerating its estimations by 10% - Set PricePenaltyFactor to 0.9

   Pool Variants

   Poolnames ending in *Plus

      Uses calculations based on 24hr actual and current estimate prices to get a more realistic estimate.
      Includes some trust index based on past 1hr current estimate variation from 24hr.
      AND is NOT sensible to spikes.
      This shows less switching than following current estimate and more switching that following the 24hr actual.
      Better profitability.

   Balances Tracking

      Displays BTC/h and BTC/d and an estimation of when the pool payment threshold will be reached.
      Supported pools:
         - AHashPool
         - BlockMasters
         - HiveON
         - MiningPoolHub
         - NiceHash (internal & external wallet)
         - NLPool
         - ProHashing
         - ZergPool
         - Zpool
      If mining more than one pool, NemosMiner shows stats for all supported pools.
      Press key 'b' in the console window to show/hide earnings.

   Support for running multiple instances (not recommended)

      **Experimental**
      More than one instance of NemosMiner can run on the same rig
      Each instance must be placed in its own directory
      Miner has to be started prior the launch of the next instance

   CustomMiners (Advanced)

      Users can place any miner.ps1 from miners/optionalminers or custom user created miner.ps1 files in CustomMiners folder 
      Note: Miners in CustomMiners folder are always enabled (to disable a custom miner it must be removed from the CustomMiners folder)

   Algorithm switching log

      Simple algo switching log as csv (switching.log file found in Logs folder).
      You can easily track switching rate.

   Console Display Options

      Use -UIStyle Light or -UIStyle Full in config.json
         Full = Usual display (Default)
         Light = Show only current mining info
      UIStyle automatically switches to Full during benchmarking.
      Press key 's' in the console window to switch UIStyle.

   In session console the following keys are supported

      a: Toggle Accuracy column
      b: Toggle Pool Balances
      c: Toggle Cost column
      e: Toggle Earnings column
      i: Toggle Earning Bias column
      l: Toggle listing all available miners
      m: Toggle Miner Fees column
      n: Toggle Coin Name column
      p: Toggle Pool Fees column
      r: Toggle Profit Bias column
      s: Toggle Style (full or light)
      t: Toggle Profit column
      u: Toggle Power Usage column
      y: Toggle Currency column
      Will toggle display at next refresh

   New version notification (Available since version 3.9.9.10)

      NemosMiner will notify new version availability

***Requirements***

PowerShell Version 7.x is required:

[Download Installer for version 7.2.3](https://github.com/PowerShell/PowerShell/releases/download/v7.2.3/PowerShell-7.2.3-win-x64.msi)

**Some miners may need 'Visual C+ RunTimes download/extract, run install_all.bat file**

[Visual C+ RunTimes](https://github.com/Minerx117/Visual-C-Runtimes-All-in-One-Sep-2019/releases/download/sep2019/Visual-C-Runtimes-All-in-One-Sep-2019.zip)

**Virtual memory settings**

When running multiple cards its recommended to increase Virtual Memory. 64GB is optimal.

**Recommended/optimal Windows Nvidia driver**

[recommended/optimal Windows Nvidia driver 512.15](https://us.download.nvidia.com/Windows/512.15/512.15-notebook-win10-win11-64bit-international-dch-whql.exe)

**Recommended/optimal Windows AMD driver**

[Windows 10 AMD GPU Driver 22.2.2](https://www.amd.com/en/support)

   NemosMiner is currently tested on the following Rigs: 

      windows10-1xGTX-1660Super/RYZEN-3700x (Test PC) 

      windows10-7xAMD-6700XT/Octominer (test Rig 1)
      windows10-6xRTX-3070/RYZEN-3700x (test Rig 2)
      windows10-6xRTX-3060ti/RYZEN-3700x (test Rig 3)
      windows10-1xGTX-1060Super/1xGTX750Ti-2GB/1xRX580-8GB/RX5700/Inteli5-8600K (test Rig 4)
      windows10-7xAMD-6600XT/Octominer (test Rig 5)
      (users have reported up to 12cards are working, I have not tested myself)
      Some miners do not support more than 9 cards

      CPU miners are tested with AMD Ryzen 3700x & Inteli5-8600K CPUs

*****

Licensed under the GNU General Public License v3.0
Permissions of this strong copyleft license are conditioned on making available complete source code of licensed works and modifications, which include larger works using a licensed work, under the same license.
Copyright and license notices must be preserved. Contributors provide an express grant of patent rights.
https://github.com/Minerx117/NemosMiner/blob/master/LICENSE

Happy Mining
